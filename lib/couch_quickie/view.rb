module CouchQuickie
  class View < Response
    
    def initialize( klass )
      p klass
    end
    
    class << self
      alias :json_create :new
    end
  end
end