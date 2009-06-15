module CouchQuickie
  module Document
    module Validation
      
      class Errors < StringHash
        def initialize
          @hash = {}
        end
        
        def add field, message
          self[ field ] ||= []
          self[ field ].push message
        end
        
        
        
      end
      
    end
  end
end