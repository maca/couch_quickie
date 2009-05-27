module CouchQuickie
  module Document
    class Generic < StringHash
      attr_reader :database, :pristine
      
      def initialize( hash = {} )
        super hash.dup
        pristine_copy
      end
      
      # Difference between the documents current attributes and the pristine copy since created or saved.
      def changes; self.diff @pristine; end

      # Returns +true+ if the document has changed since created or saved.
      def changed?; not pristine?; end

      # Returns +false+ if the document has changed since created or saved.
      def pristine?; changes.empty?; end
      
      # Returns the +_id+ attribute.
      def id; self['_id']; end

      # Returns the +_rev+ (revision) attribute.
      def rev; self['_rev']; end
      
      # It will return +false+ if the document has ever been saved.
      def new_document?; not saved?; end
      
      # It will return +true+ if the document has ever been saved.
      def saved?; rev && id; end
      
      # Sets the database for the document +database+ can be a String URI or a +Database+ instance.
      def database=( database )
        @database = database.kind_of?( Database ) ? database : Database.new( database )
      end
      
      # Will save or update a document on database and raise an error if saving fails.
      def save!
        raise "A database must be setted" unless self.database
        response = id.nil? ? self.database.post( self ) : self.database.put( self )
        pristine_copy
        response
      end

      # Deletes the document from the datatabase and deletes the +_rev+ (revision) attribute for the Document instance.
      # Will raise an error if the database or the document does not exists or any other problem occurs.
      def delete!
        raise "A database must be setted" unless self.database
        response = database.delete self
        pristine_copy
        response
      end
      
      private
      # Creates a pristine copy for comparing changes
      def pristine_copy
        @pristine = {}
        for key, val in self
          @pristine[key] = 
          val.dup rescue val
        end
      end
    end
  end
end