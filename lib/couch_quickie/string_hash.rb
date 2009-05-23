
module CouchQuickie  
  class StringHash < Hash
    def initialize( constructor = {} )
      super().update constructor.strigify_keys
    end
    
    # Overrides the default []= Hash method converting the key to String prior to updating.
    def []= key, value
      super key.to_s, value
    end

    # Overrides the default [] Hash method converting the key to String prior to fetching for indiferent attribute access.
    def [] key
      super key.to_s
    end
    
    def delete( key )
      super key.to_s
    end
  end
end

