require '../lib/couch_quickie'


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


collegues = Group.new '_id' => 'Collegues'
family    = Group.new '_id' => 'Family'
friends   = Group.new '_id' => 'Friends'

persons   = [
  Person.new( '_id' => 'Michel', 'groups' => [ friends ] ),
  Person.new( '_id' => 'Ary',    'groups' => [ friends, collegues, family ] ),
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
     if (doc.json_class == 'CouchQuickie::Relationship') {
        emit( [doc.A], doc.B ) 
     } else if (doc.json_class == 'Group'){
       emit( [{},{}], doc )
     }
  }",
  
  # :reduce => "function( keys, values ){
  #   return values;
  # }"
}
design.save!

response = db.view design.id, :test, :query => {:startkey => ['Ary'], :endkey => [{}, {}]} # , :query => {:group => true}

puts response.to_yaml

