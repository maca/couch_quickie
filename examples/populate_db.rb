require '../lib/couch_quickie'
require 'benchmark'


include CouchQuickie
$db = Database.new( 'http://127.0.0.1:5984/many_to_many_example' )
$db.reset! # errase and recreate the database in case there are any docs


class Person < Document
  set_database $db
  joins :groups
  design.save!
end

class Group < Document
  set_database $db
  joins :people
  design.save!
end


collegues = Group.new '_id' => 'Collegues'
family    = Group.new '_id' => 'Family'
friends   = Group.new '_id' => 'Friends'

persons   = [
  Person.new( '_id' => 'Michel', 'groups' => [ friends ] ),
  Person.new( '_id' => 'Ary',    'groups' => [ family ] ),
  Person.new( '_id' => 'Txema',  'groups' => [ friends, collegues ] ),
  Person.new( '_id' => 'Mom',    'groups' => [ family ] )
]

db     = Person.database
design = Group.design
michel = persons.first
ary    = persons[1]
michel.save!
ary.save!




design.push_view :test => {
  :map => "function(doc) { 
    if (doc.json_class == 'CouchQuickie::Relationship'){ 
      emit( [doc.B.key, doc.A._id], doc.B._id ); 
      emit( [doc.A.key, doc.B._id], doc.A._id ) 
    } else if ( doc._associations ) {
      for(var i in doc._associations)
       {
           emit( [doc._associations[i], 'mAry'], 1 );
       }
    }
  }"
  
  
  # :reduce => "function( keys, values ){
  #   return values;
  # }"
}
design.save!
# 
response = db.view design.id, :test, :query => { :key => ['groups', 'Ary'] }
# 
puts response.to_yaml

