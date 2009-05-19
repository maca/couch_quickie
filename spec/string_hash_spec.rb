require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie

describe StringHash do
  
  before do
    @ihash = StringHash.new( :symbol => Symbol, 'string' => String )
  end
  
  it "should set all keys to string" do
    @ihash.should == { 'symbol' => Symbol, 'string' => String }
  end
  
  it "should delete string key with symbol" do
    @ihash.delete(:string).should == String
  end

end