require File.dirname(__FILE__) + '/spec_helper.rb'
# require File.join(FIXTURES, 'obj')

class Calendar < CouchQuickie::Document
  def monday=( whatever )
    self['monday'] = 'you can fall apart'
  end
end

include CouchQuickie

describe Document do  
  
  describe 'JSON parsing' do
    before do
      @hash_calendar = { "json_class" => "Calendar", "yesterday" => Date.civil(2009, 5, 10), "today" => Date.civil(2009, 5, 11), "tomorrow" => Date.civil(2009, 5, 12), "some-blue-day" => nil }
    end
    
    shared_examples_for 'parsed document' do
      it "it should parse to ruby" do
        @calendar.should be_kind_of( Document )
        @calendar.should be_instance_of( Calendar )
      end
      
      it "should map poperties" do
        @calendar.should == @hash_calendar
      end
    end
    
    describe 'parse from json' do
      before do
        @calendar = JSON.parse( JSON_CALENDAR )
      end
      it_should_behave_like 'parsed document'
    end
    
    describe 'serialization persistence' do
      before do
        @calendar = JSON.parse( JSON.parse( JSON_CALENDAR ).to_json )
      end
      it_should_behave_like 'parsed document'
    end
  end
  
  describe 'hash behaviour' do
    before do
      @calendar = { "json_class" => "Calendar", "yesterday" => Date.civil(2009, 5, 10), "today" => Date.civil(2009, 5, 11), "tomorrow" => Date.civil(2009, 5, 12), "some-blue-day" => nil }
      @friday   = { 'friday' => 'I am in love' }
    end

    it "should should return instance on Document on #merge" do
      merge = Calendar.new( @calendar ).merge( @friday )
      merge.should == @calendar.merge( @friday )
      merge.should be_instance_of( Calendar )
    end

    it "should should return instance on Document on #merge!" do
      merge = Calendar.new( @calendar ).merge!( @friday )
      merge.should == @calendar.merge( @friday )
      merge.should be_instance_of( Calendar )
    end

    it "should default to nil" do
      Calendar.new( @calendar )[:not_a_key].should == nil
    end

    it "should have indiferent access" do
      jsondoc = Calendar.new( @calendar )
      jsondoc[:today].should == @calendar['today']
      jsondoc[:friday] = @friday['friday']
      jsondoc.should == @calendar.merge(@friday)
    end
    
    it "should use accessors if available" do
      Calendar.new( @calendar.merge('monday' => "I'm in love") ).should == @calendar.merge('monday' => 'you can fall apart')
    end
  end
  
  describe 'Database creation and interaction' do
    before :all do
      @database  = "http://localhost:5984/calendars"
      @database2 = "http://localhost:5984/calendars2"
      Calendar.send :set_database, @database
      class OtherCalendar < Calendar; end
    end
        
    describe 'database inheritance' do
      it "should create database" do
        Calendar.database.url.should == @database
        Calendar.database.info['db_name'].should == 'calendars'
      end
    
      it "should inherit database" do
        OtherCalendar.database.info['db_name'].should == 'calendars'
      end
    
      it "should set new database only for current class" do
        OtherCalendar.send :set_database, @database2
        OtherCalendar.database.info['db_name'].should == 'calendars2'
        Calendar.database.info['db_name'].should == 'calendars'
      end 
            
      describe Document, 'save, update and delete' do
        before do
          @calendar = Calendar.new( JSON.parse( JSON_CALENDAR ).merge( 'json_class' => nil ) )
          @db = @calendar.database
        end
        
        after do
          Calendar.database.reset!
        end
   
        it "should get database for instance" do
          @calendar.database.info['db_name'].should == 'calendars'
        end
        
        it 'should be new document' do
          @calendar.should be_new_document
        end
        
        it "should save" do
          lambda { @calendar.save! }.should change( @db, :count ).by(1)
          @calendar.should_not be_new_document
          fetched = @db.get( @calendar )
          fetched.should == @calendar
          fetched.should be_instance_of(Calendar)
        end
        
        it "should update" do
          @calendar.save!
          lambda { @calendar.merge!('monday' => 'you can fall apart').save! }.should_not change( @db, :count )
          @db.get( @calendar )['monday'].should == 'you can fall apart'
        end
        
        it "should delete" do
          @calendar.save!
          @calendar.should_not be_new_document
          lambda { @calendar.delete! }.should change( @db, :count ).by(-1)
          @calendar.should be_new_document
          @calendar['_rev'].should be_nil
        end
        
        it "should save with a given id" do
          @calendar.merge!( '_id' => 'my_cal' )
          @calendar.should be_new_document
          lambda { @calendar.save! }.should change( @db, :count ).by(1)
          @calendar.should_not be_new_document
          @db.get( @calendar )[ '_id' ].should == 'my_cal'
        end
      end
    end
  end
  
  describe 'Designs' do
    before :all do
      Database.new("http://localhost:5984/bookstore_specs").delete! rescue nil
      class Book < Document
        set_database "http://localhost:5984/bookstore_specs"
      end
    end

    it "should have a design" do
      design = Book.design
      design.should be_instance_of( Design )
      design['document_class'].should == 'Book'
    end
    
    it "should set database for design" do
      Book.design.database.should == Book.database
    end
    
    it "should save the design" do
      Book.design.should_not be_new_document
      Book.database.get( Book.design )['_id'].should == Book.design['_id']
    end
  end
  
end
