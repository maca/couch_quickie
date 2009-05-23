require File.dirname(__FILE__) + '/spec_helper.rb'

include CouchQuickie
Database.new('http://127.0.0.1:5984/many_to_many_spec').delete! rescue nil

class Person < Document
  set_database 'http://127.0.0.1:5984/many_to_many_spec'
  joins :groups, :phones
  design.save!
end

class Group < Document
  set_database 'http://127.0.0.1:5984/many_to_many_spec'
  joins :people
  design.save!
end

class Phone < Document
  set_database 'http://127.0.0.1:5984/many_to_many_spec'
  joins :people
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
        @phones = 5.times{ |i| Phone.new( '_id' => i ) }
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
        @ary.groups.map{ |group| @db.get( group ) }.should == [ @collegues, @family, @friends ]
      end
      
      it "should save relationships" do
        @ary.save!
        response = Response.new @db.temp_view( :map => "function(doc){ if(doc.json_class == 'CouchQuickie::Relationship'){ emit(null, doc) } }")
        response.sort_by{ |e| e['B']['_id'] }.should == @ary.instance_variable_get( :@relationships ).sort_by{ |e| e['B']['_id']  }
      end
      
      it "should save relationships for two documents" do
        @ary.save!
        @michel.save!
        response = Response.new @db.temp_view( :map => "function(doc){ if(doc.json_class == 'CouchQuickie::Relationship'){ emit(null, doc) } }")
        relationships = @ary.instance_variable_get( :@relationships ) + @michel.instance_variable_get( :@relationships )
        response.sort_by{ |e| e.to_s }.should == relationships.sort_by{ |e| e.to_s  }
      end
      
      it "should get related group ids" do
        @ary.save!
        @michel.save!
        Person.get( :related_ids, :query => { :key => [@ary.id, 'Group'] } ).sort.should == @ary.groups.map { |g| g.id  }
        Person.get( :related_ids, :query => { :key => [@michel.id, 'Group'] } ).should == @michel.groups.map { |g| g.id  }
      end
      
      it "should restablish relationships" do
        @ary.save!
        @ary.groups = @michel.groups
        @ary.save!
        Person.get( :related_ids, :query => { :key => [@ary.id, 'Group'] } ).sort.should == @michel.groups.map{ |g| g.id  }
      end
      
      it "should add person to each group people array" do
        @friends.people.sort_by{ |p| p.id }.should == [@michel, @ary, @txema].sort_by{ |p| p.id }
      end
    end
    
    describe 'with no id' do
      before do
        @collegues = Group.new 'name' => 'Collegues'
        @family    = Group.new 'name' => 'Family'
        @friends   = Group.new 'name' => 'Friends'

        @persons   = [
          Person.new( 'name' => 'Michel', 'groups' => [ @friends ] ),
          Person.new( 'name' => 'Ary',    'groups' => [ @collegues, @family, @friends ] ),
          Person.new( 'name' => 'Txema',  'groups' => [ @collegues, @friends ] ),
          Person.new( 'name' => 'Mom',    'groups' => [ @family ] )
        ]
      end
      it_should_behave_like 'relational'
    end
    
    describe 'with given id' do
      before do
        @collegues = Group.new '_id' => 'Collegues'
        @family    = Group.new '_id' => 'Family'
        @friends   = Group.new '_id' => 'Friends'
        
        @persons   = [
          Person.new( '_id' => 'Michel', 'groups' => [ @friends ] ),
          Person.new( '_id' => 'Ary',    'groups' => [ @collegues, @family, @friends ] ),
          Person.new( '_id' => 'Txema',  'groups' => [ @collegues, @friends ] ),
          Person.new( '_id' => 'Mom',    'groups' => [ @family ] )
        ]
      end
      it_should_behave_like 'relational'
    end
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