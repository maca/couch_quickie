require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie
Database.new('http://127.0.0.1:5984/bookstore_spec').delete! rescue nil

class Book < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
end

class Magazine < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
end

describe 'Book quering' do  
  
  before :all do    
    @books = [
      Book.new( 'title' => 'Answered Prayers', 'author' => 'Truman Capote' ),
      Book.new( 'title' => 'Cómo escuchar la música', 'author' => 'Aaron Copland' ),
      Book.new( 'title' => 'I-Ching', 'author' => 'anonymous' )
    ]
    @books.each{ |book| book.save! }
    
    @zines = [
      Magazine.new( 'title' => 'IdN', 'tags' => %{ design multimedia arts } ),
      Magazine.new( 'title' => 'Pitchform', 'tags' => %w{ music entertainment rock } ),
      Magazine.new( 'title' => 'Wired', 'tags' => %w{ tech culture science } )
    ]
    @zines.each{ |zine| zine.save! }
  end
  
  it "should find all Books" do
    Book.get( :all ).sort_by( :title ).should == @books
  end
  
  it "should get by id" do
    book = Book.get( @books.first.id )
    book.should == @books.first
    book.should be_instance_of(Book)
  end
  
  it "should get by doc" do
    book = Book.get( @books.first )
    book.should == @books.first
    book.should be_instance_of(Book)
  end
  
  it "should count books" do
    Book.get( :count ).should == @books.size
  end
  
  it "should raise error when passing nil"
    
  after :all do
   Book.database.delete!
  end
end
