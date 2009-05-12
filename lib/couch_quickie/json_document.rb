module CouchQuickie  
  class JSONDocument < Hash
    include Mixins::Views
    
    # Expects an attribute hash
    def initialize( constructor = {} )
      super().update constructor
    end
    
    # Overrides the default []= Hash method converting the key to String prior to updating.
    def []= key, value
      super key.to_s, value
    end
    
    # Overrides the default [] Hash method converting the key to String prior to fetching for indiferent attribute access.
    def [] key
      super key.to_s
    end
    
    # It will create a new database document if the Document hasn't been saved or it will update it if it has.
    # It will yield an error if the database or updating document doesn't not exists or any other problem occurs.
    def save!
      response = new_document? ? database.post( self ) : database.put( self )
      self['_id'], self['_rev'] = response['id'], response['rev']
      response
    end
    
    # Deletes the document from the datatabase and nils _id and _rev attributes for the Document instance.
    # It will yield an error if the database or the document doesn't not exists or any other problem occurs.
    def delete!
      response = database.delete self
      self['_id'], self['_rev'] = nil, nil
      response
    end
    
    # It will return false if the document has been allready saved.
    def new_document?
      self['_id'].nil?
    end
    
    # Returns the database the Document instance will use for HTTP operations, all instances of a given Document class will share this. 
    # attribute
    def database; end

    class << self
      alias :json_create :new
      
      # Returns the database for the Class
      def database; end
      # Sets the database for the Class, it is actually a private method because is just intended to be used at Class definition.
      def database=( database ); end

      private
      def inherited( klass ) #:nodoc:
        database_accessors_for( klass )
      end

      def database_accessors_for( klass )
        parent = self
        klass.class_eval <<-RUBY_EVAL
        @@#{klass}_database = parent.database if parent.respond_to?( :database )
        #Inheriting some crap
        def database
          @@#{klass}_database
        end
        
        def self.database
          @@#{klass}_database
        end
        
        private
        def self.database=( database )
          @@#{klass}_database = database.kind_of?( Database ) ? database : Database.new( database )
        end
        RUBY_EVAL
      end
    end

  end
end