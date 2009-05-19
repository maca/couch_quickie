require 'rubygems'
require 'json'
require 'json/add/core'
require 'json/add/rails'
require 'rest_client'
require 'active_support/inflector'

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'couch_quickie/response'
require 'couch_quickie/database'
require 'couch_quickie/string_hash'
require 'couch_quickie/document'
require 'couch_quickie/design'
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

    # Addapted from Rack
    def build_query( params )
      params.map do |k, v|
        if v.kind_of? Array
          build_query v.map{ |x| [k, x] }
        else
          v = escape( k.to_s == 'rev' ? v : %("#{v}") )
          "#{k}=#{v}"
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
  
  class CouchDBError < StandardError; end
end