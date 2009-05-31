require File.dirname(__FILE__) + '/../spec_helper.rb'

include CouchQuickie  
include Document

CouchQuickie.assets_dir = File.expand_path File.dirname(__FILE__) + '/../fixtures'
Database.new( 'http://127.0.0.1:5984/validation_spec' ).delete! rescue nil

class Person < Document::Base
  set_database 'http://127.0.0.1:5984/validation_spec'
  validate_as :book
  design.save!
end

class Doc < Document::Base
  set_database 'http://127.0.0.1:5984/validation_spec'
end


describe 'Javascript validation' do
  
  before :all do
    @validation = CouchQuickie.validation_file :book
  end
  
  before do
    @doc    = Doc.new
    @person = Person.new( 'name'  => 'Macario Ortega', 'email' => 'macarui@gmail.com', 'phones' => [{'mobile' => '044-55-41353526'}] )
  end
  
  it "should push save validation to design" do
    Person.design['validate_doc_update'].should == @validation
  end
  
  it "should save doc" do
    @doc.save!
  end

  it "should not save" do
    @person['name'] = nil
    @person.save
    @person.should_not be_saved
  end
  
  it "should not be valid" do
    @person['name'] = nil
    @person.save
    @person.should_not be_valid
  end
  
  it "should output errors" do
    @person['name'] = nil
    @person.save
    @person.errors.should == {"name"=>["can't be blank"]}
    @person.errors(:name).should == ["can't be blank"]
  end

end



