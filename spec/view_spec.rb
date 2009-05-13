require File.dirname(__FILE__) + '/spec_helper.rb'

class Book < CouchQuickie::Document; end

include CouchQuickie  

describe View do
  
  it "document must have a view class" do
    # Book.view.should be_instance_of( View )
  end
  
  
  
end