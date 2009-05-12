require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie

describe Database do
  before :each do
    @url   = "http://localhost:5984/couch_test"
    @db    = Database.create( @url )
    @today = { 'today' => Date.today }
  end
  
  after :each do
    @db.delete! rescue nil
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
  
  describe 'documents' do
    it "should post a document" do
      today    = @db.post @today
      response = get( "#{@url}/#{today['id']}" )
      response['today'].should == Date.today
    end
  
    it "should get a document" do
      response = @db.post @today
      @db.get( response['id'] )['today'] == @today['today']
    end
  
    it "should get a raw document" do
      response = @db.post @today
      @db.get( response['id'], :parse => false ).should be_kind_of( String )
    end
  
    it "should get a document from doc[_id]" do
      response = @db.post @today
      doc = @db.get( response['id'] )
      @db.get( doc ).should == doc
    end

    it "should count documents" do
      10.times{ post = @db.post @today }
      @db.count.should == 10
    end
    
    it "should reset the database" do
      @db.post @today
      lambda{ @db.reset! }.should change( @db, :count ).by(-1)
    end
  
    it "should update document" do
      response = @db.post @today
      doc      = @db.get  response
      new_response = @db.put( doc.merge('today' => Date.today + 1) )
      @db.get( new_response )['today'].should == Date.today + 1
      @db.count.should == 1
    end
    
    it "should delete a document" do
      doc = @db.get @db.post( @today)
      @db.delete doc
      @db.count.should == 0
    end
    
    describe 'Errors' do
      it "should argument errors" # do
       #        lambda { @db.delete nil }.should raise_error(ArgumentError)
       #        lambda { @db.delete '' }.should raise_error(ArgumentError)
       #        lambda { @db.put nil }.should raise_error(ArgumentError)
       #      end
    end

  end
  

end