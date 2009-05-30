require File.dirname(__FILE__) + '/../spec_helper.rb'
# require File.join(FIXTURES, 'obj')

Database.new('http://127.0.0.1:5984/doc_spec').delete! rescue nil

include CouchQuickie

class Calendar < Document::Base
  set_database 'http://127.0.0.1:5984/doc_spec'
  
  def monday=( whatever )
    self['monday'] = 'you can fall apart'
  end
end

describe Document::Base do  
  
  describe 'JSON parsing' do
    before do
      @hash_calendar = { "json_class" => "Calendar", "yesterday" => Date.civil(2009, 5, 10), "today" => Date.civil(2009, 5, 11), "tomorrow" => Date.civil(2009, 5, 12), "some-blue-day" => nil, "_joint_name"=>"calendars" }
    end
    
    shared_examples_for 'parsed document' do
      it "it should parse to ruby" do
        @calendar.should be_kind_of( Document::Base )
        @calendar.should be_instance_of( Calendar )
      end
      
      it "should map poperties" do
        @calendar.should == @hash_calendar
      end
    end
    
    describe 'parse from json' do
      before do
        @calendar = JSON.parse( JSON_CALENDAR )
        @calendar.delete('_id').should_not be_nil
      end
      it_should_behave_like 'parsed document'
    end
    
    describe 'serialization persistence' do
      before do
        @calendar = JSON.parse( JSON.parse( JSON_CALENDAR ).to_json )
        @calendar.delete('_id').should_not be_nil
      end
      it_should_behave_like 'parsed document'
    end
  end
  
  describe 'hash behaviour' do
    before do
      @calendar = { "json_class" => "Calendar", "yesterday" => Date.civil(2009, 5, 10), "today" => Date.civil(2009, 5, 11), "tomorrow" => Date.civil(2009, 5, 12), "some-blue-day" => nil, "_joint_name"=>"calendars" }
      @friday   = { 'friday' => 'I am in love' }
      @doc = Calendar.new( @calendar )
    end

    it "should should return instance on Document::Base on #merge" do
      merge = Calendar.new( @calendar ).merge( @friday )
      merge.delete('_id').should_not be_nil
      merge.should == @calendar.merge( @friday )
      merge.should be_instance_of( Calendar )
    end

    it "should should return instance on Document::Base on #merge!" do
      merge = Calendar.new( @calendar ).merge!( @friday )
      merge.delete('_id').should_not be_nil
      merge.should == @calendar.merge( @friday )
      merge.should be_instance_of( Calendar )
    end

    it "should default to nil" do
      Calendar.new( @calendar )[:not_a_key].should == nil
    end

    it "should have indiferent access" do
      jsondoc = Calendar.new( @calendar )
      jsondoc.delete('_id').should_not be_nil
      jsondoc[:today].should == @calendar['today']
      jsondoc[:friday] = @friday['friday']
      jsondoc.should == @calendar.merge(@friday)
    end
    
    it "should use accessors if available" do
      cal = Calendar.new( @calendar.merge('monday' => "I'm in love") )
      cal.delete('_id').should_not be_nil
      cal.should == @calendar.merge('monday' => 'you can fall apart')
    end
    
    it "should track changes" do
      @doc.changes.should == {}
      @doc.merge!( 'monday' => 'you can fall apart' )
      @doc.changes.should == { 'monday' => 'you can fall apart' }
    end
    
    it "should be changed" do
      @doc.should_not be_changed
      @doc.merge!( 'monday' => 'you can fall apart' )
      @doc.should be_changed
    end
    
    it "should reset pristine copy when saving" do
      @doc.should_not be_changed
      @doc.merge!( 'monday' => 'you can fall apart' )
      @doc.save!
      @doc.should_not be_changed
    end
    
    it "should reset pristine copy when deleting" do
      @doc.save!
      @doc.should_not be_changed

      @doc.merge!( 'monday' => 'you can fall apart' )
      @doc.delete!
      @doc.should_not be_changed
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
            
      describe Document::Base, 'save, update and delete' do
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
      class Book < Document::Base
        set_database "http://localhost:5984/bookstore_specs"
      end
    end

    it "should have a design" do
      design = Book.design
      design.should be_instance_of( Document::Design )
      design['document_class'].should == 'Book'
    end
    
    it "should set database for design" do
      Book.design.database.should == Book.database
    end
    
    it "should save and get the design" do
      Book.design.should_not be_new_document
      Book.database.get( "_design/book" ).should == Book.design
    end
  end
  
end
