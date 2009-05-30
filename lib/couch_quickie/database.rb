module CouchQuickie
  # Ruby interaction with a CouchDB database, saves documents, updates, etc...
  class Database
    attr_accessor :url
    attr_reader   :name, :design
    
    # Expects the url of the CouchDB to use:
    #   Database.new('http://127.0.0.1:5984/books')
    # 
    # It will create the database if it doesn't allready exist.
    def initialize( url )
      @url, @name = url, url.match( /[^\/]*$/ ).to_s
      begin
        http_action :put, nil, :doc => ''
        create_shared_design
      rescue
      end
    end
    
    # Creates a new CouchDB document, <tt>doc</tt> must be kind of <tt>Hash</tt> or a subclass of <tt>Document</tt>
    #
    # Options:
    #   * :parse +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def post( doc, opts = {} )
      response = http_action :post, nil, opts.merge( :doc => doc )
      doc['_id'], doc['_rev'] = response['id'], response['rev'] if doc.kind_of? Hash
      response
    end
    
    # Updates an existing CouchDB document, <tt>doc</tt> must kind of <tt>Hash</tt> or a subclass of <tt>Document</tt>, and it must have
    # the corresponding <tt>_id</tt> and <tt>_rev</tt> attributes.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def put( doc, opts = {} )
      response = http_action :put, doc, opts.merge( :doc => doc )
      doc['_id'], doc['_rev'] = response['id'], response['rev'] if doc.kind_of? Hash
      response
    end
    
    # Fetches an existing CouchDB document, <tt>doc</tt> can kind of <tt>Hash</tt>, a subclass of <tt>Document</tt> (as long as they have
    # a corresponding <tt>_id</id> or <tt>id</tt> attibute) or an id String for a existing document.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    #   * query: +Hash+
    #   Additional query parameters
    #   eg. { :query => {:rev => 'aue763h7hiu'} }
    def get( doc, opts = {} )
      http_action :get, doc, opts #TODO, not accept nil
    end
    
    # Deletes an existing CouchDB document, <tt>doc</tt> can kind of <tt>Hash</tt> or a subclass of <tt>Document</tt> as long as it has
    # <tt>_id</id> and <tt>_rev</tt> attributes corresponding to a stored document or a Sting id.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    #   * rev: +String+
    #   To delete another revision rather than the latest
    def delete( doc, opts = {} )
      rev         = opts.delete(:rev)
      response    = http_action :delete, doc, { :query => {:rev => rev || doc['_rev'] } }.merge( opts )
      doc.delete '_rev' if doc.kind_of? Hash
      response
    end
    
    # Deletes the database and documents, use with care!. The ruby database will not have a CouchDB counterpart unless reset! is called to regenerate
    # the CouchDB database.
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def delete!( opts = {} )
      http_action :delete, nil, opts
    end
    
    # Deletes and regenerates the database erasing all documents. Note: All Design documents will have to be saved again, including those generated
    # when subclassing <tt>Document</tt>
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def reset!( opts = {} )
      http_action :delete, nil rescue nil
      http_action :put, nil, opts.merge( :doc => '' )
      create_shared_design
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
    
    # GETs the result of a view by name or if +keys+ option is passed POSTs the keys to the view. 
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    #   * keys: +Array+
    #   An array of keys can be passed in order to restrict the results to documents corresponding to those keys.
    #   * query: +Hash+
    #   Additional query parameters.
    #   eg. { :query => {:key => 'Person', :group => true} }
    #
    # More info on views in the CouchDB wiki.
    def view( design, view, opts = {} )
      keys = opts.delete( :keys )
      if keys
        http_action :post, "#{design}/_view/#{view}", opts.merge( :doc => {:keys => keys} ) 
      else
        http_action :get,  "#{design}/_view/#{view}", opts
      end
    end
    
    # POSTs a temporary view in the database, should not be used in production as it can get slow for large databases
    #
    # Options:
    #   * parse: +false+
    #   When passing false it will not parse the JSON response returning a RestClient::Response (subclass of String) that can used by
    #   JSON consumers, otherwise it will return a Ruby Hash.
    def temp_view( opts )
      view = {}
      view[:map]    = opts.delete(:map)
      view[:reduce] = opts.delete(:reduce) if opts[:reduce]
      http_action :post, '_temp_view', opts.merge( :doc => view, :content => 'application/json' )
    end
    
    # Bulk updates/saves/deletes an array of documents
    #
    # Options:
    #   * atomic: +true+
    #   The default transactional behaviour is non atomic. Some documents may successfully be saved and some may not. 
    #   The response will tell the application which documents were saved or not. In the case of a power failure, 
    #   when the database restarts some may have been saved and some not.
    #
    #   If passing true in the case of a power failure, when the database restarts either all the changes will have been 
    #   saved or none of them. 
    #   However, it does not do conflict checking, so the documents will be committed even if this creates conflicts.
    #
    # For more info: http://wiki.apache.org/couchdb/HTTP_Bulk_Document_API
    def bulk_save( docs, opts = {} )
      parse = opts.delete :parse
      bulk  = { :docs => docs }
      bulk[ "all_or_nothing" ] = true if opts.delete(:atomic) == true
      
      response = http_action :post, '_bulk_docs', opts.merge( :doc => bulk )

      docs.zip( response ) do |pair|
        doc, response = pair
        doc['_id']    = response['id']
        doc['_rev']   = response['rev']
      end
      
      parse ? response : response.to_json
    end
    
    # Returns the number of documents for the CouchDB database.
    def count; info['doc_count']; end
    
    # Returns the database url
    def to_s; @url; end
    
    private
    def http_action( method, doc_url, opts = {} ) #:nodoc:
      query    = opts.delete(:query)
      document = opts.delete(:doc)
      parse    = opts[:parse] || opts.delete(:parse).nil? # only not passing the :parse option or :parse => nil will not parse
      content  = opts.delete(:content)

      args = [ method, CouchQuickie.build_url( @url, doc_url, query ) ]
      args << document.to_json if document
      args << { 'Content-Type' => content } if content
      
      begin
        response = RestClient.send *args
      rescue RestClient::ExceptionWithResponse => e
        response = e.response.to_ary[1] 
        raise CouchQuickie::CouchDBError.new( JSON.parse( response ).merge( :url => args[1] ).to_json ) # what couchdb has to say?
      end
      
      parse ? JSON.parse( response ) : response
    end
    
    def create_shared_design
      @design = Document::Design.new( '_id' => '_design/shared', :_database => self )
      @design.push_view :associated => {
        :map => "function(doc) {
          if ( doc._associations ) {
            for (var i in doc._associations) {
              var association = doc._associations[ i ];
              associated = doc[ '_' + association ];
              for (var j in associated ) {
                var emited = {};
                emited[ doc._joint_name ] = [doc];
                emit( [associated[j], doc._joint_name], emited );
              }
            }
          }
        }"
      }
      @design.save!
    end
    
    class << self
      alias :create :new
    end
  end
end