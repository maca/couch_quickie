require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie
Database.new('http://127.0.0.1:5984/bookstore_spec').delete! rescue nil

class Book < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
  # belongs_to :author
  design.save!

end

class Author < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
  joins :editorials
  
end

class Editorial < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
  joins :books
  
end

describe 'associations' do

  before do
    Book.database.reset!
    Book.design.reset!.save!
    Author.design.reset!.save!
        
    @truman = Author.new( 'name' => 'Truman Capote')
    @truman.save!
    
    @alejo = Author.new( 'name' => 'Alejo Carpentier')
    @alejo.save!
    
    @books = [
      Book.new( 'title' => 'Answered Prayers', 'author' => @truman ),
      Book.new( 'title' => 'El recurso del método', 'author' => @alejo ),
      Book.new( 'title' => 'In Cold Blood', 'author' => @truman ),
      Book.new( 'title' => 'Music for Chameleons', 'author' => @truman ),
      Book.new( 'title' => 'One Christmas', 'author' => @truman )
    ]
    @books.each{ |book| book.save! }
    
    @book = @books.first
  end
  # 
  # describe 'belongs to' do
  # 
  #   it "should not save author in book document" do
  #     Book.database.get( @book )['author'].should be_nil
  #     @book['author'].should == @truman
  #   end
  #   
  #   it "should set author id" do
  #     @books.first['Author_id'].should == @truman.id
  #   end
  #   
  #   it "should lazy load author" do
  #     book = Book.get( @book )
  #     book.author.should == @truman
  #     book['author'].should == @truman
  #   end
  #   
  #   it "should not reload author" do
  #     book = Book.get( @book )
  #     book.author
  #     Book.should_not_receive(:get)
  #     book.author
  #   end
  #   
  #   it "should save associated"
  #   it "should eager load author"
  # end
  # 
  # 


end