require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie

describe Database do
  
  before :all do
    @url = "http://localhost:5984/couch_test"
    @db  = Database.create( @url )
  end
  
  after do
    @db.reset!
  end
  
  after :all do
    @db.delete!
  end
   
  def get( url )
    JSON.parse RestClient.get( url )
  end

  it "should create database" do
    lambda do
      get( @url )['db_name'].should == "couch_test"
    end.should_not raise_error( RestClient::RequestFailed )
  end
  
  it "should delete the database" do
    @db.delete!
    lambda{ get @url }.should raise_error( RestClient::ResourceNotFound )
  end
  
  it "should set the database name" do
    @db.name.should == 'couch_test'
  end
  
  shared_examples_for 'document' do
    it "should create a document" do
      response = @doc['_id'] ? @db.put( @doc ) : @db.post( @doc )
      doc = get( "#{@url}/#{response['id']}" )
      doc.should == @doc
    end
  
    it "should get a document" do
      response = @doc['_id'] ? @db.put( @doc ) : @db.post( @doc )
      doc = @db.get( response['id'] )
      doc.should == @doc
    end
  
    it "should get a raw response" do
      response = @db.post @doc
      @db.get( response['id'], :parse => false ).should be_kind_of( String )
    end
  
    it "should get a document from doc[_id]" do
      response = @db.post @doc
      doc = @db.get( response['id'] )
      @db.get( doc ).should == doc
    end

    it "should count documents" do
      lambda do
        10.times{ post = @db.post @doc }
      end.should change( @db, :count ).by(10)
    end
    
    it "should reset the database" do
      @db.post @doc
      lambda{ @db.reset! }.should change( @db, :count ).by(-1)
    end
  
    it "should update document" do
      response = @db.post @doc
      doc      = @db.get  response
      lambda do
        new_response = @db.put( doc.merge('today' => Date.today + 1) )
        @db.get( new_response )['today'].should == Date.today + 1
      end.should_not change( @db, :count )
    end
    
    it "should delete a document" do
      doc = @db.get @db.post( @doc )
      lambda{ @db.delete doc }.should change( @db, :count ).by( -1 )
    end
  end
  
  describe 'conventional document' do
    before do
      @doc = { 'today' => Date.today }
    end
    it_should_behave_like 'document'
  end
  
  describe 'view' do
    before do
      @doc  = JSON.parse( BOOK_VIEW )
    end
    it_should_behave_like 'document'
    
    it "should have the correct id" do
      doc = @db.get( @db.put( @doc ) )
      doc['_id'].should == "_design/books"
    end
  end
  
  describe 'temp view and bulk save' do
    before do
      @docs = [
          {"beverage" => "beer", :count => 4},
          {"beverage" => "beer", :count => 2},
          {"beverage" => "tea",  :count => 3}
        ]
      @view = { :map => "function(doc){emit(doc.beverage, doc.count)}", :reduce => "function(beverage,counts){return sum(counts)}" }
    end
    
    it "should create temp view" do
      @docs.each{ |d| @db.post d }
      response = @db.temp_view @view
      response['rows'].first['value'].should == 9
    end
    
    it "should bulk_save an array" do
      lambda{ @db.bulk_save @docs }.should change( @db, :count ).by(3)
    end
    
    it "should update _rev and _id on bulk save" do
      @db.bulk_save @docs
      for doc in @docs
        doc['_rev'].should_not be_nil
        doc['_id'].should_not be_nil
      end
    end
    
  end
end