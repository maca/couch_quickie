
module CouchQuickie  
  class Response < Hash
    attr_accessor :database
    
    
    # Overrides the default []= Hash method converting the key to String prior to updating.
    def []= key, value
      super key.to_s, value
    end

    # Overrides the default [] Hash method converting the key to String prior to fetching for indiferent attribute access.
    def [] key
      super key.to_s
    end
  end
end