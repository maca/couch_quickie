
require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'benchmark'

include CouchQuickie
Database.new('http://127.0.0.1:5984/many_to_many_spec').delete! rescue nil

class Document::Design
  def reset!
    delete('_rev')
    self
  end
end

class Person < Document::Base
  set_database 'http://127.0.0.1:5984/many_to_many_spec'
  has_and_belongs_to_many :groups, :phones
  design.save!
end

class Group < Document::Base
  set_database 'http://127.0.0.1:5984/many_to_many_spec'
  habtm :people
  design.save!
end

class Phone < Document::Base
  set_database 'http://127.0.0.1:5984/many_to_many_spec'
  habtm :people
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
    shared_examples_for 'related' do
      before do
        @michel = @persons.first
        @ary    = @persons[1]
        @txema  = @persons[2]
        @phones = 5.times{ |i| Phone.new( '_id' => i ) }
        @db     = Person.database
      end
 
      it "create accessors" do
        @michel.should respond_to( :groups )
        @michel.should respond_to( :groups= )
      end
    
      it "should not save groups in Person document" do
        @michel.save!
        Person.get( @michel )['groups'].should == nil
        @michel['groups'].should == [@friends]
      end
      
      it "should append group in Person document" do
        @michel.save!
        michel = Person.get( @michel )
        michel.groups << @collegues
        @friends.delete('people')
        @collegues.delete('people')
        michel.groups.should == [ @friends, @collegues ]
      end
      
      it "should not blow if groups is nil" do
        @ary['groups'] = nil
        @ary.save!
      end
    
      it "should save associated groups without people" do
        @ary.save!
        @ary.should_not be_new_document
        groups = [ @collegues, @family, @friends ].map{ |g| g.delete(:people); g }
        @ary.groups.map{ |group| @db.get( group ) }.should == groups
      end
      
      it "should add person related group" do
        @friends.people.sort.should == [@michel, @ary, @txema].sort
      end
      
      it "should get related groups using shared design" do
        @ary.save!
        @michel.save!
        @ary.get_related( 'groups' )['groups'].should == [ @collegues, @family, @friends ].map{ |g| g.delete(:people); g }
        @michel.get_related( 'groups' )['groups'].should == [ @friends ].map{ |g| g.delete(:people); g }
      end

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
      it_should_behave_like 'related'
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
      it_should_behave_like 'related'
    end
  end

  describe Group do
    # it "create accessors" do
    #   @friends.should respond_to( :persons )
    #   @friends.should respond_to( :persons= )
    # end
  end
end