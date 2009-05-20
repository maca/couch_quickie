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
      end
      
      it "create accessors" do
        @michel.should respond_to( :groups )
        @michel.should respond_to( :groups= )
      end
    
      it "should not save groups" do
        @michel.save!
        Person.get( @michel )['groups'].should be_nil
        @michel['groups'].should == [@friends]
      end
    
      it "should save associated groups" do
        @ary.save!
        groups = @ary.groups.map do |group|
          group.delete('_rev').should_not be_nil
          group
        end
        groups.should == [ @friends, @collegues, @family ]
      end
    end
    
    describe 'with given id' do
      before do
        @friends   = Group.new '_id' => 'Friends'
        @collegues = Group.new '_id' => 'Collegues'
        @family    = Group.new '_id' => 'Family'

        @persons   = [
          Person.new( '_id' => 'Michel', 'groups' => [ @friends ] ),
          Person.new( '_id' => 'Ary',    'groups' => [ @friends, @collegues, @family ] ),
          Person.new( '_id' => 'Txema',  'groups' => [ @friends, @collegues ] ),
          Person.new( '_id' => 'Mom',    'groups' => [ @family ] )
        ]
      end
      it_should_behave_like 'relational'
    end
    
    describe 'with no id' do
      before do
        @friends   = Group.new 'name' => 'Friends'
        @collegues = Group.new 'name' => 'Collegues'
        @family    = Group.new 'name' => 'Family'

        @persons   = [
          Person.new( 'name' => 'Michel', 'groups' => [ @friends ] ),
          Person.new( 'name' => 'Ary',    'groups' => [ @friends, @collegues, @family ] ),
          Person.new( 'name' => 'Txema',  'groups' => [ @friends, @collegues ] ),
          Person.new( 'name' => 'Mom',    'groups' => [ @family ] )
        ]
      end
      it_should_behave_like 'relational'
    end
  end
  
  describe Group do
    # it "create accessors" do
    #   @friends.should respond_to( :persons )
    #   @friends.should respond_to( :persons= )
    # end
  end
end