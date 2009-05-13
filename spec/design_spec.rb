require File.dirname(__FILE__) + '/spec_helper.rb'

class Book < CouchQuickie::Document; end

include CouchQuickie  

describe Design, 'for document class' do
  before do
    @book_design = JSON.parse( BOOK_VIEW )
    @book_view = @book_design['views']['all']
    @design = Design.new( 'document_class' => 'Book' )
  end
  
  it "should set document" do
    @design['document_class'].should == 'Book'
  end
  
  it "should set language" do
    @design['language'].should == 'javascript'
  end
  
  it "should require an id" do
    lambda{ Design.new }.should raise_error
  end
  
  it "should require an id starting with _design" do
    lambda{ Design.new( '_id' => 'id') }.should raise_error
  end
  
  it "should not have a design" do
    Design.design.should be_nil #may not be the case after all
  end
  
  it "should have views" do
    @design['views'].should be_kind_of(Hash)
  end
  
  it "should not override views" do
    Design.new( 'views' => { 'all' => '...'}, '_id' => '_design/id' )['views'].should == { 'all' => '...'}
  end
  
  it "should require views to be a hash" do
    lambda { Design.new( 'views' => 'Not good', '_id' => '_design/id' ) }.should raise_error( ArgumentError )
  end
  
  it "should push view" do
    @design.push_view @book_view
    @design['views'].should include( @book_view )
  end
  
  it "should create a default view for all documents of the class" do
    @design.views['all'].should == {'map' => "function(doc) { if(doc.json_class == 'Book'){ emit(doc, null); } }"}
  end
  
  it "should have a database" do
    @design.database = 'http://localhost:5984/books'
    @design.database.to_s.should == 'http://localhost:5984/books'
    @design.database.should be_instance_of( Database )
  end
  
  it "should set a default id" do
    @design['_id'].should == '_design/book'
  end
  
  describe 'database interaction' do
    before do
      @design = Design.new( 'document_class' => 'Book' )
      @design.database = 'http://localhost:5984/books'
      @design.database.reset!
    end
    
    after do
      @design.database.reset!
    end
    
    it "should save" do
      @design.save!
      @design.database.get( @design )['_id'].should == @design['_id']
    end
  end  
end