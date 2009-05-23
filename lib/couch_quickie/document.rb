
module CouchQuickie
  class Document < StringHash
    attr_accessor :database
    
    # Expects an attributes hash
    def initialize( hash = {} )
      hash = hash.dup
      
      associations.keys.each { |a| hash[a] ||= []  }
      self['_associations'] = associations.keys
      
      for key, val in hash
        writer = "#{key}="
        if self.respond_to? writer
          self.send writer, hash.delete( key ) 
        end
      end
      super.update( 'json_class' => self.class.to_s )
    end
            
    # It will create a new database document if the Document hasn't been saved or it will update it if it has.
    # Will raise an error if the database or updating document does not exists or any other problem occurs.
    # Options:
    #  Atomic, validate
    def save!( opts = {} )
      opts.delete :parse
      
      docs     = self.prepare_associations
      response = database.bulk_save docs, { :atomic => true }.merge( opts )
      docs[0]  = self
      docs.zip( response ) do |pair|
        doc, response = pair 
        doc.update_with response if doc.kind_of? Document 
      end 
      response
    end

    # Deletes the document from the datatabase and nils the <tt>_rev</tt>(revision) attribute for the Document instance.
    # Will raise an error if the database or the document does not exists or any other problem occurs.
    def delete!
      response = database.delete self
      self.delete('_rev')
      response
    end
    
    # def changed?; end
    
    # Returns the <tt>_id</tt> attribute
    def id; self['_id']; end
    
    # Returns the <tt>_rev</tt> attribute
    def rev; self['_rev']; end
    
    # It will return false if the document has been allready saved.
    def new_document?; not rev && id; end
    
    # Returns the <tt>Database</tt> which is shared among all instances of the class
    def database; self.class.database; end
    
    # Quick fix
    def reset!
      delete('_rev')
      self
    end
    
    def to_hash( associations = true)
      Hash.new.merge( associations ? self : self.without_associations )
    end
    
    def to_json
      self.to_hash( false ).to_json
    end
    
    def to_delete
      { '_id' => id, '_rev' => rev, '_deleted' => true }
    end
    
    protected
    # Updates _id and _rev attributes from the response of a POST or PUT request
    def update_with( response ) #TODO: Better name
      self['_id'], self['_rev'] = response['id'], response['rev']
    end
    
    # Makes a copy of the document without associated documents, collects associated documents and creates Relationships in between
    def prepare_associations( associated = [], relationships = [], deleted_relationships = [] )
      return [self] if associations.empty?
      self.assign_uuid #if it doesn't have one
      copy = self.dup

      existing_relationships = self.class.get( :relationships, :query => { :key => id } )
      
      for name, key in associations
        next unless self[name].kind_of? Array # Nothing to do
        
        foreign_key = key || name.to_s.classify
        existing = existing_relationships.select{ |rel| rel['A']['key'] == foreign_key or rel['B']['key'] == foreign_key } # just for the current associated class
        assoc    = copy.delete name
        
        assoc.zip( Array.new( assoc.size, self ) ) do |pair|
          other, this = pair #create a relationship document, assign uuid to related document unless it allready has one in order to establish the connection
          saved = existing.find{ |r| r['A']['_id'] == this.id && r['B']['_id'] == other.id or r['A']['_id'] == other.id && r['B']['_id'] == this.id } # finds a relationships between two docs if it exists
                    
          unless existing.delete( saved )
            relationships << Relationship.new( 
            'A' => { '_id' => this.id, 'key' => this['json_class'] }, 
            'B' => { '_id' => other.assign_uuid, 'key' => other['json_class'] } 
            )
          end
        end
        deleted_relationships += existing.map(&:to_delete)
        
        associated << assoc
      end
      [copy] + associated.flatten.compact + relationships + deleted_relationships
    end
    
    def without_associations
      copy = self.dup
      associations.keys.each{ |name| copy.delete name }
      copy
    end
 
    # Assigns a uuid unless document allready has one
    def assign_uuid
      self['_id'] ||= @@uuid.generate
    end
    
    private
    def associations
      self.class.associations
    end
    
    class << self
      alias :json_create :new
      @@uuid = UUID.new
            
      # Returns the database for the Document Class
      def database; @database; end
      
      # Returns the design for the Document Class
      def design; @design; end
      
      def associations; @associations; end #:nodoc:

      # Key can be a Symbol, String or Document Hash, if key is a Symbol it will get all the documents emited by a view
      # of that name otherwise it will get the requested document by id.
      def get( key, opts = {} )
        return database.get( key, opts ) unless key.is_a? Symbol
        design.get key, opts
      end

      private      
      def joins( *keys )
        keys.each do |key| 
          @associations[ key.to_s ] = nil
          define_accessors key
        end
        design.push_view :related_ids => {
          'map' => "function(doc) { if (doc.json_class == 'CouchQuickie::Relationship'){ emit( [doc.A._id, doc.B.key], doc.B._id ); emit( [doc.B._id, doc.A.key], doc.A._id ) } }"
        }
        design.push_view :relationships => {
          'map' => "function(doc) { if (doc.json_class == 'CouchQuickie::Relationship'){ emit( doc.A._id, doc ); emit( doc.B._id, doc ) } }"
        }
        # design.push_view :related ={
        #           'map' => "function(doc) {
        #             if (doc.json_class == 'CouchQuickie::Relationship' ){
        #               
        #             } else if (doc.json_) {
        #               
        #             }
        #           }"
        #           
        #         }
        
      end
      
      def define_accessors( joint )
        define_method joint do
          self[joint]
        end
        
        define_method "#{joint}=" do |val|
          key = self.class.to_s.pluralize.downcase
          val.each do |associated|
            associated[ key ] << self
            associated[ key ].uniq!
          end
          self[joint] = val
        end
      end

      protected
      # Sets the database for the Document Class and the associated <tt>Design</tt>
      def set_database( database )
        @database = database.kind_of?( Database ) ? database : Database.new( database )
        @design.database = @database if @design
        @design.save! rescue nil
      end
      
      def create_design #:nodoc:
        @design = Design.new 'document_class' => self.to_s
      end
      
      def init_class_instance_variables
        @associations = {}
      end
      
      def inherited( klass ) #:nodoc:
        klass.set_database self.database if self.database
        klass.create_design unless klass == Design #is it useful for a Design class to have designs? i guess not
        klass.init_class_instance_variables #associations are not inherited
      end      
    end
  end
end