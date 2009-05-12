module CouchQuickie
  class Database
    attr_accessor :url
    
    # Expects the url of the CouchDB to use:
    #   Database.new('http://127.0.0.1:5984/books')
    # 
    # It will create the database if it doesn't allready exist.
    def initialize( url )
      @url = url
      JSON.parse RestClient.put( @url, '' ) rescue nil
    end
    
    # Creates a new CouchDB document, <tt>doc</tt> must be a <tt>Hash</tt> or a subclass of <tt>JSONDocument</tt>
    #
    # Options:
    #   * :parse +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response(Subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def post( doc, opts = {} )
      http_action :post, nil, opts.merge( :doc => doc )
    end
    
    # Updates an existing CouchDB document, <tt>doc</tt> must be a <tt>Hash</tt> or a subclass of <tt>JSONDocument</tt>, and it must have
    # the corresponding <tt>_id</tt> and <tt>_rev</tt> attributes.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response(Subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def put( doc, opts = {} )
      http_action :put, doc, opts.merge( :doc => doc )
    end
    
    # Fetches an existing CouchDB document, <tt>doc</tt> can be a <tt>Hash</tt>, a subclass of <tt>JSONDocument</tt> (as long as they have
    # a corresponding <tt>_id</id> or <tt>id</tt> attibute) or an id String for a existing document.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response(Subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    #   * query: Hash
    #   Additional query parameters
    def get( doc, opts = {} )
      http_action :get, doc, opts
    end
    
    # Fetches an existing CouchDB document, <tt>doc</tt> can be a <tt>Hash</tt>, a subclass of <tt>JSONDocument</tt> as long as they have
    # <tt>_id</id> and <tt>_rev</tt> attributes corresponding to a stored document.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response(Subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def delete( doc, opts = {} )
      http_action :delete, doc, opts.merge( :query => {:rev => doc['_rev']} )
    end
    
    # Deletes the database, careful!. The ruby database representation will be a problem unless #reset! is called to regenerate
    # the CouchDB database.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response(Subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def delete!( opts = {} )
      http_action :delete, nil, opts
    end
    
    # Deletes and regenerates the database erasing all documents.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response(Subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def reset!( opts = {} )
      http_action :delete, nil rescue nil
      parse_if RestClient.put( @url, '' ), opts
    end
    
    # Information on the CouchDB database: name, disk size, number of documents, etc...
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response(Subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def info( opts = {} )
      http_action :get, nil, opts
    end
    
    # Returns the number of documents for the CouchDB database.
    def count
      info['doc_count']
    end
    
    private
    def parse_if( response, opts ) #:nodoc:
      opts[:parse] || opts.delete(:parse).nil? ? JSON.parse( response ) : response
    end
        
    def http_action( method, doc_url, opts = {} ) #:nodoc:
      query    = opts.delete(:query)
      document = opts.delete(:doc)
      
      args = [method, Utils.build_url( @url, doc_url, query )]
      args << document.to_json if document
      response = RestClient.send *args
      parse_if response, opts
    end
    
    class << self
      alias :create :new    
    end
  end
end