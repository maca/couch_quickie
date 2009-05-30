require 'rubygems'
require 'json'
require 'json/add/core'
require 'json/add/rails'
require 'rest_client'
require 'active_support/inflector'
require 'uuid'
require 'delegate'

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'couch_quickie/core_ext'
require 'couch_quickie/response'
require 'couch_quickie/database'
require 'couch_quickie/string_hash'
require 'couch_quickie/document/generic'
require 'couch_quickie/document/associations'
require 'couch_quickie/document/validation'
require 'couch_quickie/document/base'
require 'couch_quickie/document/design'

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
      params.map do |key, val|
        val = escape( val.to_json ) unless key.to_sym == :rev
        "#{key}=#{val}"
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