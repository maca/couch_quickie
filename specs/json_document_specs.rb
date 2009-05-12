require File.dirname(__FILE__) + '/spec_helper.rb'
require File.join(FIXTURES, 'calendar')
require File.join(FIXTURES, 'obj')


include CouchQuickie

describe JSONDocument do  
  
  describe 'JSON parsing' do
    before do
      @hash_calendar = { "json_class" => "Calendar", "yesterday" => Date.civil(2009, 5, 10), "today" => Date.civil(2009, 5, 11), "tomorrow" => Date.civil(2009, 5, 12), "some-blue-day" => nil }
    end
    
    shared_examples_for 'parsed document' do
      it "it should parse to ruby" do
        @calendar.should be_kind_of( JSONDocument )
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

    it "should should return instance on JSONDocument on #merge" do
      merge = JSONDocument.new( @calendar ).merge( @friday )
      merge.should == @calendar.merge( @friday )
      merge.should be_instance_of( JSONDocument )
    end

    it "should should return instance on JSONDocument on #merge!" do
      merge = JSONDocument.new( @calendar ).merge!( @friday )
      merge.should == @calendar.merge( @friday )
      merge.should be_instance_of( JSONDocument )
    end

    it "should default to nil" do
      JSONDocument.new( @calendar )[:not_a_key].should == nil
    end

    it "should have indiferent access" do
      jsondoc = JSONDocument.new( @calendar )
      jsondoc[:today].should == @calendar['today']
      jsondoc[:friday] = @friday['friday']
      jsondoc.should == @calendar.merge(@friday)
    end
  end
  
  describe 'Database creation and interaction' do
    before :all do
      @database  = "http://localhost:5984/calendars"
      @database2 = "http://localhost:5984/calendars2"
      Calendar.send :database=, @database
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
        OtherCalendar.send :database=, @database2
        OtherCalendar.database.info['db_name'].should == 'calendars2'
        Calendar.database.info['db_name'].should == 'calendars'
      end 
            
      describe JSONDocument, 'save, update and delete' do
        before do
          @calendar = JSON.parse( JSON_CALENDAR )
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
          @db.get( @calendar ).should == @calendar
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
        
      end
    end
  end
  
  
end


