
module CouchQuickie
  class Document < StringHash
    attr_accessor :database
    
    # Expects an attributes hash
    def initialize( constructor = {} )
      super.update( 'json_class' => self.class.to_s )
      self
    end
        
    # It will create a new database document if the Document hasn't been saved or it will update it if it has.
    # Will raise an error if the database or updating document does not exists or any other problem occurs.
    def save!
      doc = self.without_associations
      response = id.nil? ? database.post( doc ) : database.put( doc )
      self['_id'], self['_rev'] = response['id'], response['rev']
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
    
    protected
    def without_associations
      copy = self.dup
      associations.each { |joint| copy.delete joint[:name] }
      copy
    end
    
    private
    def set_ids_for_associations( association )
    end
    
    def associations
      self.class.associations
    end
    
    class << self
      alias :json_create :new
      
      # Returns the database for the Document Class
      def database; @database; end
      
      # Returns the design for the Document Class
      def design; @design; end
      
      # Gets all the documents corresponding to a view
      def get( key, opts = {} )
        return database.get( key ) unless key.is_a? Symbol
        
        raise 'There is no view with that name' unless view = design.views[ key.to_s ]
        response = Response.new database.get( "#{@design.id}/_view/#{key}", opts )
        response = *response if view['reduce']
        response
      end
      
      def associations; @associations; end #:nodoc:

      private      
      # def has_many( *associated )
      #   opts  = associated.pop if associated.last.is_a? Hash
      #   klass = opts.delete(:kind)
      #   
      #   for association in joins( associated, :belongs_to, klass )
      #     name, key  = association[:name], association[:key]
      #     define_method name do
      #       self[name] = self[name] || self.class.get( self[key] )
      #     end
      #   end
      # end
      
      # def joins( associated, kind, klass ) #:nodoc:
      #   @associations += associated.map! do |joint| 
      #     klass = joint.to_s.classify 
      #     { :name => joint.to_s, :kind => kind, :key => "#{klass}_id" }
      #   end
      #   associated
      # end

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