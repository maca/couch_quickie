module CouchQuickie
  module Document
    class Design < Generic

      def initialize( hash = {} )
        super.update('language' => 'javascript')
        
        self['_id']   ||= "_design/" << self['document_class'].to_s.downcase
        raise ArgumentError, "an _id attribute starting with '_design/' must be specified"   unless id.match(/_design\/.+/)
        
        self['views'] ||= {}
        raise ArgumentError, "Expected views attribute to be a Hash, got a #{ views.class }" unless self['views'].instance_of? Hash    
        
        
        if self['document_class']
          push_view 'all'   => { 'map' => "function(doc) { if(doc.json_class == '#{ self['document_class'] }'){ emit(doc._id, doc); } }" }
          push_view 'count' => { 
            'map'    => "function(doc) { if(doc.json_class == '#{ self['document_class'] }'){ emit(null, 1); } }",
            'reduce' => "function(keys, values) { return sum(values); } " 
          }
        end
        
        @database = delete :_database
        pristine_copy
      end

      def push_view( view )
        views.merge! view.strigify_keys
      end

      def views; self['views']; end

      def get( key, opts = {} )
        return database.design.get( key, opts ) unless id == '_design/shared' unless view = views[ key.to_s ]
        response = Response.wrap database.view( id, key, opts )
        response = *response if view['reduce']
        response
      end

      private
      def set_default_id
        
      end

      def set_views
        
      end
    end
  end
end