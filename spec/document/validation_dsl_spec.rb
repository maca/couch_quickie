require File.dirname(__FILE__) + '/../spec_helper.rb'

include CouchQuickie
include Document

class NoMethods < Document::Base
  
  # properties :name, :surname, :status
  
  validate do |doc, old|

    must_be_present doc.name, doc.surname if doc.name == 'Macario'
    
  end

end


INIT = 'function Errors() {}; Errors.prototype.add = function(field, message) {this[field] = this[field] || []; this[field].push(message)}; var errors = new Errors()'




