
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
    #  Parse, atomic, validate
    def save!( opts = {} )
      default = { :atomic => true } # Possible source of conflict
      clean   = self.remove_associations
      
      if clean == self
        response = id.nil? ? database.post( self, opts ) : database.put( self, opts )
        self.response_update response
      else
        docs     = @associated.flatten << clean
        response = database.bulk_save docs, default.merge( opts )
        docs.zip( response ){ |e| e.first.response_update e.last }
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
    
    # Returns the <tt>_id</tt> attribute
    def id; self['_id']; end
    
    # Returns the <tt>_rev</tt> attribute
    def rev; self['_rev']; end
    
    # It will return false if the document has been allready saved.
    def new_document?; not rev && id; end
    
    # Returns the <tt>Database</tt> which is shared among all instances of the class
    def database; self.class.database; end
    
    # def each_of( klass )
    #   each_pair do |key, val| yield( key, val ) if val.kind_of? klass end
    # end
    
    def reset!
      delete('_rev')
      self
    end
    
    protected
    def response_update( response ) #TODO: Better name
      self['_id'], self['_rev'] = response['id'], response['rev']
    end
    
    def remove_associations
      copy = self.dup
      @joints = []
      @associated = associations.keys.map do |name|
        assoc   = copy.delete name
        # sarray  = Array.new( assoc.size, self )
        #    ordered = self['json_class'] > assoc.first['json_class'] ? [ sarray, assoc ] : [ assoc, sarray ]
        # 
        #    ordered.first.zip( ordered.last ) do |e|
        #      f, l = e.first, e.last
        #      relationship = { '_id' => f.id + l.id, 'type' => 'relationship', f['json_class'] => f.id, l['json_class'] => l.id  }
        #    end
        assoc
      end
      copy
    end
    
    # def associated
    #   associations.keys.collect{ |associated| self[associated]  }
    # end
    
    private
    def associations
      self.class.associations
    end
    
    class << self
      alias :json_create :new
      
      # Returns the database for the Document Class
      def database; @database; end
      
      # Returns the design for the Document Class
      def design; @design; end
      
      def associations; @associations; end #:nodoc:
      
      # Key can be a Symbol, String or Document Hash, if key is a Symbol it will get all the documents emited by a view
      # of that name otherwise it will get the requested document by _id.
      def get( key, opts = {} )
        return database.get( key, opts ) unless key.is_a? Symbol
        design.get key, opts
      end

      private      
      
      def joins( *keys )
        opts  = keys.pop if keys.last.is_a? Hash
        
        keys.each do |key| 
          @associations[ key ] = { :kind => 'joint', :class => key.to_s.classify }
          define_accessors key
        end        
      end
      
      def define_accessors( key )
        define_method key do
          self[key]
        end
        define_method "#{key}=" do |val|
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