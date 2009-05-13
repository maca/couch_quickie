require 'rubygems'
require 'json'
require 'json/add/core'
require 'rest_client'

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'couch_quickie/database'
require 'couch_quickie/mixins/db_interactions'
require 'couch_quickie/response'
require 'couch_quickie/document'
require 'couch_quickie/view'
require 'couch_quickie/object'

module CouchQuickie
  VERSION = '0.0.1'
  
  class << self
    def build_url( base, doc, query = nil )
      doc = doc['_id'] || doc['id'] if doc.kind_of? Hash
      url = "#{ base }/#{ doc }"
      url << "?" << build_query( query ) if query
      url
    end

    # From Rack
    def build_query( params )
      params.map do |k, v|
        if v.kind_of? Array
          build_query v.map{ |x| [k, x] }
        else
          "#{ escape(k) }=#{ escape(v) }"
        end
      end.join("&")
    end

    # From Rack from Camping
    def escape( s )
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
        '%'+$1.unpack('H2'*$1.size).join('%').upcase
      end.tr(' ', '+')
    end
  end
end