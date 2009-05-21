require 'lib/couch_quickie'


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

michel = persons.first
ary    = persons[2]
ary.save!
