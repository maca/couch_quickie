module CouchQuickie  
  module Mixins
    module DBInteractions
      attr_accessor :database

      # It will create a new database document if the Document hasn't been saved or it will update it if it has.
      # Will raise an error if the database or updating document does not exists or any other problem occurs.
      def save!( validate = true )
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

      
    end
  end
end