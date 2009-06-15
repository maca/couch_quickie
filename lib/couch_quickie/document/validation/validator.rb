module CouchQuickie
  module Document
    module Validation
      
      class Validator
        FORMATS = {
          :email => //,
          :url   => //
        }
        
        def initialize doc, old, errors
          @doc, @old, @errors = doc, old, errors
        end
        
        def must_be_present *fields
          opts    = fields.pop if fields.last.is_a? Hash
          message = opts.delete(:message)

          fields.each do |field|
            @errors.add field, message || "can't be blank" unless @doc[field]
          end
        end

        def must_be_formatted *fields
          opts = fields.pop if fields.last.is_a? Hash
          with = opts.delete( :with )
          as   = opts.delete( :as )
          
          
        end
      end
      
    end
  end
end