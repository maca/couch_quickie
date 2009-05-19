require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie
Database.new('http://127.0.0.1:5984/bookstore_spec').delete! rescue nil

class Book < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
  # belongs_to :author
  

end

class Author < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
  joins :editorials
  design.save!
  
end

class Editorial < CouchQuickie::Document
  set_database 'http://127.0.0.1:5984/bookstore_spec'
  joins :books
  design.save!
  
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
    
    @penguin = Editorial.new( 'name' => 'Penguin' )
    @penguin.save!
    
    @alfaguara = Editorial.new( 'name' => 'Alfaguara' )
    @alfaguara.save!
    
    @books = [
      Book.new( 'title' => 'Answered Prayers', 'author' => @truman, 'editorial' => @penguin ),
      Book.new( 'title' => 'El recurso del método', 'author' => @alejo, 'editorial' => @alfaguara ),
      Book.new( 'title' => 'A sangre fría', 'author' => @truman, 'editorial' => @alfaguara ),
      Book.new( 'title' => 'Music for Chameleons', 'author' => @truman, 'editorial' => @penguin ),
      Book.new( 'title' => 'One Christmas', 'author' => @truman, 'editorial' => @penguin  )
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