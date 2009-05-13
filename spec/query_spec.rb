require File.dirname(__FILE__) + '/spec_helper.rb'

class Book < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
end

class Magazine < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
end

# Empty the database
Book.database.reset!


describe 'Book quering' do
    
  before :all do
    @books = [
      Book.new( :title => 'I-Ching', :author => 'anonymous', :notes => 'Comments by Richard Wilheim' ),
      Book.new( :title => 'Cómo escuchar la música', :author => 'Aaron Copland', :editorial => 'Random House' ),
      Book.new( :title => 'Answered Prayers', :author => 'Truman Capote', :editorial => 'Random House' )
    ]
    @books.each{ |book| book.save! }
    
    @zines = [
      Magazine.new( :title => 'Wired', :tags => %w{ tech culture science } ),
      Magazine.new( :title => 'Pitchform', :tags => %w{ music entertainment rock } ),
      Magazine.new( :title => 'IdN', :tags => %{ design multimedia arts } )
    ]
    @zines.each{ |zine| zine.save! }
  end
  
  it "should find by class" do
    Book.get( :all ).should == @books
  end
  
  
end
