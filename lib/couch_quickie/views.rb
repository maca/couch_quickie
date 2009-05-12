module CouchQuickie
  module Mixins
    module Views

      class << self
        def included( base )
          base.send :extend, ClassMethods
        end
      end

      module ClassMethods
      end

    end
  end
end