require '../lib/couch_quickie'
require 'benchmark'


include CouchQuickie
$db = Database.new( 'http://127.0.0.1:5984/many_to_many_example' )
$db.reset! # errase and recreate the database in case there are any docs
# $db.delete!


class Person < Document::Base
  set_database $db
  habtm :groups
  design.save!
end

class Group < Document::Base
  set_database $db
  habtm :people
  design.save!
end


collegues = Group.new '_id' => 'Collegues'
family    = Group.new '_id' => 'Family'
friends   = Group.new '_id' => 'Friends'

persons   = [
  Person.new( '_id' => 'Michel', 'groups' => [ friends ] ),
  Person.new( '_id' => 'Ary',    'groups' => [ family, friends, collegues ] ),
  Person.new( '_id' => 'Txema',  'groups' => [ friends, collegues ] ),
  Person.new( '_id' => 'Mom',    'groups' => [ family ] )
]

db     = Person.database
design = Group.design
michel = persons.first
ary    = persons[1]
michel.save!
ary.save!


puts "\nGroups for ary"
puts ary.groups.to_yaml

puts "\nfriends"
puts friends.people.to_yaml

puts "\n----------------"
puts ary.groups.first.people.first.to_yaml

# 
# design.push_view :people => {
#   :map => "function(doc) {
#      if (doc.json_class == 'Person') {
#         for (var i in doc._groups) {
#            emit( doc._groups[i], doc);
#         }
#      }
#   }"
# }
# 
# design.push_view :associations => {
#   :map => "function(doc) {
#     if ( doc._associations ) {
#       for (var i in doc._associations) {
#         var association = doc._associations[ i ];
#         associated = doc[ '_' + association ];
#         for (var j in associated ) {
#           var emited = {}
#           emited[ doc._joint_name ] = [doc]
#           emit( [ associated[j], doc._joint_name ], emited );
#         }
#       }
#     }
#   }"
# }
# 
# 
# 
# design.save!
# 
# response = db.view design.id, :associations, :query => { :key => ['Txema', 'groups'] }
# 
# puts response['rows'].inspect
# puts response['rows'].inject( {} ){ |final, hash| final.deep_combine( hash['value'] ) }.to_yaml
# 
