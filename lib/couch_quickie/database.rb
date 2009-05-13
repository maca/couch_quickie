module CouchQuickie
  # Ruby interaction with a CouchDB database, saves documents, updates, etc...
  class Database
    attr_accessor :url
    attr_reader   :name
    
    # Expects the url of the CouchDB to use:
    #   Database.new('http://127.0.0.1:5984/books')
    # 
    # It will create the database if it doesn't allready exist.
    def initialize( url )
      @url, @name = url, url.match( /[^\/]*$/ ).to_s
      http_action :put, nil, :doc => '' rescue nil
    end
    
    # Creates a new CouchDB document, <tt>doc</tt> must be kind of <tt>Hash</tt> or a subclass of <tt>Document</tt>
    #
    # Options:
    #   * :parse +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def post( doc, opts = {} )
      http_action :post, nil, opts.merge( :doc => doc )
    end
    
    # Updates an existing CouchDB document, <tt>doc</tt> must kind of <tt>Hash</tt> or a subclass of <tt>Document</tt>, and it must have
    # the corresponding <tt>_id</tt> and <tt>_rev</tt> attributes.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def put( doc, opts = {} )
      http_action :put, doc, opts.merge( :doc => doc )
    end
    
    # Fetches an existing CouchDB document, <tt>doc</tt> can kind of <tt>Hash</tt>, a subclass of <tt>Document</tt> (as long as they have
    # a corresponding <tt>_id</id> or <tt>id</tt> attibute) or an id String for a existing document.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    #   * query: Hash
    #   Additional query parameters
    #   eg. { :query => {:rev => 'aue763h7hiu'} }
    def get( doc, opts = {} )
      http_action :get, doc, opts
    end
    
    # Deletes an existing CouchDB document, <tt>doc</tt> can kind of <tt>Hash</tt> or a subclass of <tt>Document</tt> as long as it has
    # <tt>_id</id> and <tt>_rev</tt> attributes corresponding to a stored document.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def delete( doc, opts = {} )
      http_action :delete, doc, {:query => {:rev => doc['_rev']}}.merge( opts )
    end
    
    # Deletes the database, careful!. The ruby database will not have a CouchDB counterpart unless reset! is called to regenerate
    # the CouchDB database.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def delete!( opts = {} )
      http_action :delete, nil, opts
    end
    
    # Deletes and regenerates the database erasing all documents.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def reset!( opts = {} )
      http_action :delete, nil rescue nil
      http_action :put, nil, opts.merge( :doc => '' )
    end
    
    # Information on the CouchDB database: name, disk size, number of documents, etc...
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
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
      
      args = [method, CouchQuickie.build_url( @url, doc_url, query )]
      # p args
      args << document.to_json if document
      response = RestClient.send *args
      parse_if response, opts
    end
    
    class << self
      alias :create :new    
    end
  end
end