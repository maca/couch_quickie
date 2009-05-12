require 'rubygems'
require 'json'
require 'json/add/core'
require 'rest_client'

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'couch_quickie/utils'
require 'couch_quickie/database'
require 'couch_quickie/views'
require 'couch_quickie/json_document'
require 'couch_quickie/object'

module CouchQuickie
  VERSION = '0.0.1'
end