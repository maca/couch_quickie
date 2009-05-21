require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie
Database.new('http://127.0.0.1:5984/many_to_many_spec').delete! rescue nil


class Person < Document
  set_database 'http://127.0.0.1:5984/many_to_many_spec'
  joins :groups
  design.save!
end

class Group < Document
  set_database 'http://127.0.0.1:5984/many_to_many_spec'
  joins :persons
  design.save!
end


describe 'many to many' do
  before do
    Person.database.reset!
    Person.design.reset!.save!
    Group.design.reset!.save!
    @db = Person.database
  end
  
  describe Person do
    shared_examples_for 'relational' do
      before do
        @michel = @persons.first
        @ary    = @persons[1]
        @db     = Person.database
      end
      
      it "create accessors" do
        @michel.should respond_to( :groups )
        @michel.should respond_to( :groups= )
      end
    
      it "should not save groups in Person document" do
        @michel.save!
        Person.get( @michel )['groups'].should be_nil
        @michel['groups'].should == [@friends]
      end
      
      it "should not blow if groups is nil" do
        @ary['groups'] = nil
        @ary.save!
      end
    
      it "should save associated groups" do
        @ary.save!
        @ary.should_not be_new_document
        @ary.groups.map{ |group| @db.get( group ) }.should == [ @friends, @collegues, @family ]
      end
      
      it "should have save relationships" do
        @ary.save!
        response = Response.new @db.temp_view( :map => "function(doc){ if(doc.json_class == 'CouchQuickie::Relationship'){ emit(null, doc) } }")
        response.sort_by('Group').collect{ |g| [g['Person'], g['Group']] }.should == [["Ary", "Collegues"], ["Ary", "Family"], ["Ary", "Friends"]]
      end
      
      it "should have save relationships for two documents" do
        @ary.save!
        @michel.save!
        response = Response.new @db.temp_view( :map => "function(doc){ if(doc.json_class == 'CouchQuickie::Relationship'){ emit(null, doc) } }")
        split = response.sort_by('Group').collect{ |g| [g['Person'], g['Group']] }.partition{ |g| g.first == 'Ary' }
        split.first.should == [["Ary", "Collegues"], ["Ary", "Family"], ["Ary", "Friends"]]
        split.last.should  == [["Michel", "Friends"]]
      end
      
      it "should get related persons" do
        @ary.save!
        @michel.save!
        p Person.get( :groups, :query => { :key => 'Ary', :group => true } )
      end
    end
    
    describe 'with given id' do
      before do
        @collegues = Group.new '_id' => 'Collegues'
        @family    = Group.new '_id' => 'Family'
        @friends   = Group.new '_id' => 'Friends'
        
        @persons   = [
          Person.new( '_id' => 'Michel', 'groups' => [ @friends ] ),
          Person.new( '_id' => 'Ary',    'groups' => [ @friends, @collegues, @family ] ),
          Person.new( '_id' => 'Txema',  'groups' => [ @friends, @collegues ] ),
          Person.new( '_id' => 'Mom',    'groups' => [ @family ] )
        ]
      end
      it_should_behave_like 'relational'
    end
    
    # describe 'with no id' do
    #   before do
    #     @collegues = Group.new 'name' => 'Collegues'
    #     @family    = Group.new 'name' => 'Family'
    #     @friends   = Group.new 'name' => 'Friends'
    # 
    #     @persons   = [
    #       Person.new( 'name' => 'Michel', 'groups' => [ @friends ] ),
    #       Person.new( 'name' => 'Ary',    'groups' => [ @friends, @collegues, @family ] ),
    #       Person.new( 'name' => 'Txema',  'groups' => [ @friends, @collegues ] ),
    #       Person.new( 'name' => 'Mom',    'groups' => [ @family ] )
    #     ]
    #   end
    #   it_should_behave_like 'relational'
    # end
  end
  
  # http://127.0.0.1:5984/many_to_many_spec/_design/relationships/_view/by_person_ids?startkey=[%22Ary%22]&endkey=[%22Ary%22,{}]
  # Group associations ids: function(doc){ if(doc.json_class == 'CouchQuickie::Relationship'){ emit([doc.Person, doc.Group], doc._id) }; }
  
  
  describe Group do
    # it "create accessors" do
    #   @friends.should respond_to( :persons )
    #   @friends.should respond_to( :persons= )
    # end
  end
end