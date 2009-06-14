# module CouchQuickie
#   module Document
#     
#     module Validation
#       def self.included( base )
#         base.send :include, InstanceMethods
#         base.send :extend,  ClassMethods
#       end
#       
#       module InstanceMethods
#         def save
#           begin 
#             save!
#             @errors = nil
#           rescue CouchQuickie::CouchDBError => e
#             @errors = Validation::Errors.new( e.response['error'], e.response['reason'] )
#           end
#         end
# 
#         def valid?; @errors.empty?; end
#         
#         def errors( field = nil )
#           return @errors[field] if field
#           @errors
#         end
#       end
#       
#       module ClassMethods
#         
#         def validate_as( validation )
#           design['validate_doc_update'] = CouchQuickie.validation_file validation
#         end
#         
#         def validate_with( function )
#           design['validate_doc_update'] = function
#         end
#       end
#     
#       class Errors < StringHash
#         attr_reader :kind
#         def initialize( kind, fields )
#           @kind = kind
#           super fields
#         end
#       end
#     end
#     
#     
#   end
# end