
module CouchQuickie
  class Document < StringHash
    attr_accessor :database
    attr_reader   :pristine
    
    # Expects an attributes hash
    def initialize( hash = {} )
      hash = hash.dup
      
      self['_id'] ||= @@uuid.generate unless self.class == CouchQuickie::Design
      self['_associations'] = associations.keys unless associations.empty?
      self['_joint_name']   = self.class.to_s.pluralize.downcase
      
      assign_with_accessors hash
      super.update( 'json_class' => self.class.to_s )
      pristine_copy
    end
    
    def changes; self.diff @pristine; end
    
    def changed?; not pristine?; end
    
    def pristine?; changes.empty?; end
    
    def get_related( query )
      self.class.get( :associated, :query => query ).inject( {} ){ |final, hash| final.deep_combine( hash ) }
    end
                
    # It will create a new database document if the Document hasn't been saved or it will update it if it has.
    # Will raise an error if the database or updating document does not exists or any other problem occurs.
    # Options:
    #  Atomic, validate, depth
    def save!( opts = {} ) # TODO: Raise error if database is not setted
      opts.delete :parse
      
      docs     = self.prepare_associations
      response = database.bulk_save docs, { :atomic => true }.merge( opts )

      docs.zip response do |pair|
        doc, response = pair 
        doc.update_with response if doc.kind_of? Document 
      end
      pristine_copy
      response
    end

    # Deletes the document from the datatabase and nils the <tt>_rev</tt>(revision) attribute for the Document instance.
    # Will raise an error if the database or the document does not exists or any other problem occurs.
    def delete!  # TODO: Raise error if database is not setted, delete dependent, remove self from related
      response  = database.delete self
      self.delete '_rev'
      pristine_copy
      response
    end
    
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
    
    def to_hash
      Hash.new.merge self.without_associations
    end
    
    def to_json
      self.to_hash.to_json
    end
    
    def for_deletion
      self['_deleted'] = true
    end
    
    def to_delete?; self['_deleted']; end
    
    def <=> other; id <=> other.id; end
    
    protected
    def to_delete( rev = self.rev )
      { '_id' => id, '_rev' => rev, '_deleted' => true }
    end
    
    # Updates _id and _rev attributes from the response of a POST or PUT request
    def update_with( response ) #TODO: Better name
      self['_id'], self['_rev'] = response['id'], response['rev']
    end
    
    # Makes a copy of the document without associated documents, collects associated documents and creates Relationships in between
    def prepare_associations( reject = [], depth = 8 )
      docs = [self]
      reject << self
      
      for name, key in associations
        next unless self[name].kind_of? Array
        self[ "_#{ name }" ] = self[ name ].collect do |other|
          docs << other.prepare_associations( reject, depth - 1 ) unless reject.include? other unless depth <= 0
          other.id
        end
      end
      
      docs.flatten.reject( &:pristine? )
    end
    
    def without_associations
      copy = self.dup
      associations.keys.each{ |name| copy.delete name }
      copy
    end
    
    private
    def assign_with_accessors( hash )
      for key, val in hash
        writer = "#{key}="
        if self.respond_to? writer
          self.send writer, hash.delete( key ) 
        end
      end
    end
    
    def pristine_copy
      @pristine = {}
      for key, val in self
        @pristine[key] = val.dup
      end
    end
    
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
      end
      
      def define_accessors( joint )
        define_method joint do
          update get_related( :key => [self.id, joint] ) unless self[joint]
          self[joint]
        end
        
        define_method "#{joint}=" do |val|
          key = self.class.to_s.pluralize.downcase
          val.each do |associated|
            associated[ key ] ||= []
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