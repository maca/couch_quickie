require File.dirname(__FILE__) + '/../spec_helper.rb'

include CouchQuickie
include Document

class NoMethods < Document::Base
  validation do |doc, old|
  end
end

class WithMethods < Document::Base
  validation do |doc, old|
  end
  
  def some_method
  end
end

INIT = 'function Errors() {}; Errors.prototype.add = function(field, message) {this[field] = this[field] || []; this[field].push(message)}; var errors = new Errors()'

describe 'Validation to JS' do
  it "should parse validation for class with no methods" do
    NoMethods.design['validate_doc_update'].should == "function(doc, old) {#{ INIT }}"
  end
  
  it "should parse validation for class with methods" do
    WithMethods.design['validate_doc_update'].should == "function(doc, old) {#{ INIT }}"
  end
end



