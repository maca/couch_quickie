module CouchQuickie
  class IDError < StandardError; end
  
  class View
    attr_accessor :map, :reduce
    
    def initialize( map, reduce )
      @map, @reduce = map, reduce
    end
        
  end
  
  
  class Design < Document
    attr_reader :database
    
    def initialize( constructor = {} )
      super( constructor ).update('language' => 'javascript')
      set_default_id
      set_default_view      
      if self['document_class']
        push_view 'all' => { 'map' => "function(doc) { if(doc.json_class == '#{self['document_class']}'){ emit(doc, null); } }" }
      end
    end
        
    def push_view( view )
      views.merge!( view )
    end
    
    def views; self['views']; end
    
    def database=( database )
      @database = database.kind_of?( Database ) ? database : Database.new( database )
    end
    
    private
    def set_default_id
      self['_id'] ||= "_design/" << self['document_class'].to_s.downcase
      raise 'an _id attribute must be specified' unless self['_id'].match(/_design\/.+$/)
    end
    
    def set_default_view
      self['views'] = {} if self['views'].nil?
      raise ArgumentError, "Expected views attribute to be a Hash, got #{ views }" unless self['views'].instance_of? Hash
    end
  end
end