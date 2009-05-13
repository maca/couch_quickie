module CouchQuickie  
  class Document < Response
    
    # Expects an attributes hash
    def initialize( constructor = {} )
      super().update constructor.merge( 'json_class' => self.class.to_s )
    end
    
    # It will return false if the document has been allready saved.
    def new_document?
      not @saved
    end
    
    # Returns the database the Document instance will use for HTTP operations, all instances of a given Document class will share this. 
    # attribute
    def database
      self.class.database
    end

    class << self
      alias :json_create :new
      
      # Returns the database for the Class
      def database; end
      
      # Sets the database for the Class, it is actually a private method because is just intended to be used at Class definition.
      def database=( database ); end
      
      def get( view, opts = {} )
      end
      
      private      
      def inherited( klass ) #:nodoc:
        dinamic_accessors_for klass
      end

      def dinamic_accessors_for( klass ) #:nodoc:
        parent = self
        klass_name = klass.to_s.gsub('::', '_')
        klass.class_eval <<-RUBY_EVAL
        #Inheriting some crap but...
        @@#{klass_name}_database = parent.database

        def self.database
          @@#{klass_name}_database
        end
        
        private
        def self.set_database( database )
          @@#{klass_name}_database = database.kind_of?( Database ) ? database : Database.new( database ) if database
        end
        RUBY_EVAL
      end
      
    end

  end
end