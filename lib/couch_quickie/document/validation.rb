module CouchQuickie
  module Document
    module Validation
      def self.included( base )
        base.send :include, InstanceMethods
        base.send :extend,  ClassMethods
      end
      
      module InstanceMethods
      end
      
      module ClassMethods
      end
      
      class Generator
      end
    end
  end
end