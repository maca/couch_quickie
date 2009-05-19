require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie
Database.new('http://127.0.0.1:5984/many_to_many_spec').delete! rescue nil


class Person < Document
  set_database 'http://127.0.0.1:5984/many_to_many_spec'
end