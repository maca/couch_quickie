# coding: utf-8

require 'rubygems'
require 'json'
require 'json/add/core'
require 'json/add/rails'
require 'rest_client'
require 'active_support/inflector'
require 'uuid'
require 'delegate'
# require 'ruby2js'
require 'ruby_parser'

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require '/Users/macario/Gems/ruby_to_js/lib/ruby2js'

require 'couch_quickie/core_ext'
require 'couch_quickie/response'
require 'couch_quickie/database'
require 'couch_quickie/string_hash'
require 'couch_quickie/document/generic'
require 'couch_quickie/document/associations'
require 'couch_quickie/document/validation'
require 'couch_quickie/document/validation/errors'
require 'couch_quickie/document/validation/validator'
require 'couch_quickie/document/base'
require 'couch_quickie/document/design'

module CouchQuickie
  VERSION = '0.0.1'

  class << self
    def assets_dir= dir
      @assets_dir = dir
    end
    
    def assets_dir
      @assets_dir
    end
    
    def validation_file name
      File.read File.join( assets_dir, 'validations', "#{name}.js" )
    end
    
    def view_file name
      File.read File.join( assets_dir, 'views', "#{name}.js" )
    end
            
    def build_url base, doc, query = nil
      doc  = doc['_id'] || doc['id'] if doc.kind_of? Hash
      url  = "#{ base }/#{ doc }"
      url << "?" << build_query( query ) if query
      url
    end

    # Addapted from Rack
    def build_query params
      params.map do |key, val|
        val = escape( val.to_json ) unless key.to_sym == :rev
        "#{key}=#{val}"
      end.join("&")
    end

    # From Rack from Camping
    def escape s
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
        '%'+$1.unpack('H2'*$1.size).join('%').upcase
      end.tr(' ', '+')
    end
  end

  class CouchDBError < StandardError
    attr_reader :response, :url
    
    def initialize response, url
      @response, @url = response, url
    end

    def response
      response = *JSON.parse( @response )
    end
    
    def to_s
      { :url => url, :response => response }.inspect
    end
  end
end