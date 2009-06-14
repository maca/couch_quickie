# coding: utf-8

require File.dirname( __FILE__ ) + '/spec_helper'
require File.join( FIXTURES, 'obj' )


describe Object, 'create from json' do
  before do
    @array = [1, 2, Obj.new( *%w(a b c d e) ), [[[['ヽ(´ー｀)ﾉ']]]], Date.today]
    @obj   = Obj.new *@array
  end
  
  it "should serialize/deserialize" do
    obj = JSON.parse( @obj.to_json )
    obj.should be_instance_of(Obj)
    obj.to_array.should == @array
  end
  
  it "should serialize/deserialize within array" do
    JSON.parse( [@obj, @obj].to_json ).each{ |o| o.to_array.should == @array }
  end
end
