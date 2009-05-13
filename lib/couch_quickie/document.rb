require 'active_support/core_ext/class/attribute_accessors'

module CouchQuickie  
  class Document < Response
    
    # Expects an attributes hash
    def initialize( constructor = {} )
      super().update constructor.merge( 'json_class' => self.class.to_s )
    end
        
    # It will create a new database document if the Document hasn't been saved or it will update it if it has.
    # Will raise an error if the database or updating document does not exists or any other problem occurs.
    def save!
      response = self['_id'].nil? ? database.post( self ) : database.put( self )
      self['_id'], self['_rev'] = response['id'], response['rev']
      @saved = true
      response
    end

    # Deletes the document from the datatabase and nils <tt>_id</tt> <tt>and _rev</tt> attributes for the Document instance.
    # Will raise an error if the database or the document does not exists or any other problem occurs.
    def delete!
      response = database.delete self
      @saved, self['_id'], self['_rev'] = nil
      response
    end
    
    def id; self['_id']; end
    
    # It will return false if the document has been allready saved.
    def new_document?
      not @saved
    end
    
    # Returns the <tt>Database</tt> which is shared among all instances of the class
    def database
      self.class.database
    end

    class << self
      alias :json_create :new
      
      # Returns the database for the Class
      def database; @database; end
      
      # Returns the design for the Class
      def design; @design; end
      
      def get( view, opts = {} )
        database.get( "#{@design.id}/_view/#{view}", opts )
      end
      
      protected
      # Sets the database for the Class and the associated <tt>Design</tt>
      def set_database( database )
        @database = database.kind_of?( Database ) ? database : Database.new( database )
        if @design
          @design.database = @database
          @design.save! rescue nil
        end
      end
      
      def create_design #:nodoc:
        @design = Design.new( 'document_class' => self.to_s )
      end
      
      def inherited( klass ) #:nodoc:
        klass.set_database self.database if self.database
        klass.create_design unless klass == Design #is it useful for a Design class to have designs?
      end      
    end
  end
end