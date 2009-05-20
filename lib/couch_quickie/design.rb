module CouchQuickie
  class Design < Document
    attr_reader :database
    
    def initialize( constructor = {} )
      super.update('language' => 'javascript')
      set_default_id
      set_views      
      if self['document_class']
        push_view 'all' => { 'map' => "function(doc) { if(doc.json_class == '#{self['document_class']}'){ emit(doc._id, doc); } }" }
        push_view 'count' => { 
          'map' => "function(doc) { if(doc.json_class == '#{self['document_class']}'){ emit(null, 1); } }",
          'reduce' => "function(keys, values) { return sum(values); } " 
        }
      end
    end
            
    def push_view( view )
      views.merge!( view.strigify_keys )
    end
    
    def views; self['views']; end
    
    def database=( database )
      @database = database.kind_of?( Database ) ? database : Database.new( database )
    end
    
    def get( key, opts = {} )
      raise 'There is no view with that name' unless view = views[ key.to_s ]
      response = Response.parse database.view( id, key, opts )
      response = *response if view['reduce']
      response
    end
    
    private
    def set_default_id
      self['_id'] ||= "_design/" << self['document_class'].to_s.downcase
      raise ArgumentError, 'an _id attribute must be specified' unless id.match(/_design\/.+/)
    end
    
    def set_views
      self['views'] ||= {}
      raise ArgumentError, "Expected views attribute to be a Hash, got a #{ views.class }" unless self['views'].instance_of? Hash
    end
  end
end