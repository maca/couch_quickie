require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie


describe Relationship do
  
  before do
    @db = Database.new('http://127.0.0.1:5984/relationship_spec')
    @db.reset!
    
    @relationships = [ 
      Relationship.new( "Group"=>"Friends", "Person"=>"Ary" ), 
      Relationship.new( "Group"=>"Collegues", "Person"=>"Ary" ), 
      Relationship.new( "Group"=>"Family", "Person"=>"Ary" )
    ]
  end
  
  it "should get" do
    
  end
  
end