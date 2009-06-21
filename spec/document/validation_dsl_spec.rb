require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'benchmark'

include CouchQuickie
include Document

class NoMethods < Document::Base
  
  # properties :name, :surname, :status
  validate do |doc, old|
    
    must_be_present doc.name, doc.surname, :message => 'should not be nil'
    
    
  end

end


