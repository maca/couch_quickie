
module CouchQuickie
  class Document < StringHash
    attr_accessor :database
    
    # Expects an attributes hash
    def initialize( constructor = {} )
      super.update( 'json_class' => self.class.to_s )
    end
        
    # It will create a new database document if the Document hasn't been saved or it will update it if it has.
    # Will raise an error if the database or updating document does not exists or any other problem occurs.
    # Options:
    #  Atomic, validate
    def save!( opts = {} )
      opts.delete :parse
      clean = self.remove_associations

      if clean == self
        response = id.nil? ? database.post( self, opts ) : database.put( self, opts )
        self.update_with response
      else
        docs     = [clean] + @associated.flatten + @relationships + @deleted_relationships #TODO: Reject not changed
        response = database.bulk_save docs, { :atomic => true }.merge( opts )
        docs[0]  = self #replace copy with self for updating _id and _rev
        docs.zip( response ) do |pair|
          doc, response = pair 
          doc.update_with response if doc.kind_of? Document #updating id and rev for associated and relationships
        end 
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
    
    protected
    # Updates _id and _rev attributes from the response of a POST or PUT request
    def update_with( response ) #TODO: Better name
      self['_id'], self['_rev'] = response['id'], response['rev']
    end
    
    # Makes a copy of the document without associated documents, collects associated documents and creates Relationships in between
    def remove_associations
      return self if associations.empty?
      self.assign_uuid #if it doesn't have one
      
      copy, @relationships, @deleted_relationships = self.dup, [], []
      existing_relationships = self.class.get( :relationships, :query => { :key => id } )
      
      @associated = associations.keys.map do |name|
        next unless self[name].kind_of? Array # Nothing to do
        klass_name = name.to_s.classify
        existing   = existing_relationships.select{ |rel| rel['A']['joint'] == klass_name or rel['B']['joint'] == klass_name } # just for the current associated class
        assoc      = copy.delete name
                
        assoc.zip( Array.new( assoc.size, self ) ) do |pair|
          other, this = pair #create a relationship document, assign uuid to related document unless it allready has one in order to establish the connection
          saved = existing.find{ |r| r['A']['_id'] == this.id && r['B']['_id'] == other.id or r['A']['_id'] == other.id && r['B']['_id'] == this.id } # finds a relationships between two docs if it exists

          unless existing.delete( saved )
            @relationships << Relationship.new( 
            'A' => { '_id' => this.id, 'joint' => this['json_class'] }, 
            'B' => { '_id' => other.assign_uuid, 'joint' => other['json_class'] } 
            )
          end
        end

        @deleted_relationships += existing.map{ |rel| { '_id' => rel.id, '_rev' => rel.rev, '_delete' => true } }
        assoc
      end.compact
      copy
    end
    
    # Assigns a uuid unless document allready has one
    def assign_uuid
      self['_id'] ||= "r-" + @@uuid.generate
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
          @associations[ key ] = nil
          define_accessors key
        end
        design.push_view :related_ids => {
          'map' => "function(doc) { if (doc.json_class == 'CouchQuickie::Relationship'){ emit( [doc.A._id, doc.B.joint], doc.B._id ); emit( [doc.B._id, doc.A.joint], doc.A._id ) } }"
        }
        design.push_view :relationships => {
          'map' => "function(doc) { if (doc.json_class == 'CouchQuickie::Relationship'){ emit( doc.A._id, doc ); emit( doc.B._id, doc ) } }"
        }
      end
      
      def define_accessors( key )
        define_method key do
          self[key]
        end
        define_method "#{key}=" do |val|
          p self.to_s
          self[key] = val
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