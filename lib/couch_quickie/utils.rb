module CouchQuickie
  module Utils
    class << self
      def build_url( base, doc, query = nil )
        url = 
        case doc
        when String
          "#{base}/#{doc}"
        when Hash
          id = doc['_id'] || doc['id']
          "#{base}/#{id}"
        when nil
          base
        end
        url = "#{url}?#{build_query(query)}" if query
        url
      end

      # From Rack
      def build_query(params)
        params.map { |k, v|
          if v.class == Array
            build_query(v.map { |x| [k, x] })
          else
            escape(k) + "=" + escape(v)
          end
        }.join("&")
      end

      # From Camping
      def escape( s )
        s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
          '%'+$1.unpack('H2'*$1.size).join('%').upcase
        end.tr(' ', '+')
      end
    end
  end
end