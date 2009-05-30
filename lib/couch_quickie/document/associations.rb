module CouchQuickie
  module Document
    module Associations
      def self.included( base )
        base.send :include, InstanceMethods
        base.send :extend,  ClassMethods
      end

      module InstanceMethods
        def get_related( assoc )
          query = { :key => [self.id, assoc ] }
          self.class.get( :associated, :query => query ).inject( {} ){ |final, hash| final.deep_combine( hash ) }
        end

        protected
        # Makes a copy of the document without associated documents, collects associated documents and creates Relationships in between
        def prepare_to_save_with_associations( reject = [], depth = 2 )
          docs   = [self]
          reject << self

          for name, key in associations
            next unless self[name].kind_of? Array
            self[ "_#{ name }" ] = self[ name ].collect do |other|
              docs << other.prepare_to_save_with_associations( reject, depth - 1 ) unless reject.include? other unless depth <= 0
              other.id
            end
          end

          docs.flatten.reject{ |doc| doc.pristine? and doc.saved? }
        end
        
        def associations; self.class.associations; end
      end

      module ClassMethods
        def associations; @associations; end #:nodoc:
        
        private
        def has_and_belongs_to_many( *keys )
          keys.each do |key| 
            @associations[ key.to_s ] = nil
            define_accessors_for_habtm key
          end
        end
        alias :habtm :has_and_belongs_to_many

        def define_accessors_for_habtm( joint )
          define_method joint do
            update get_related( joint ) unless self[joint]
            self[joint]
          end

          define_method "#{joint}=" do |val| #TODO: associated must share the database
            key = self.class.to_s.pluralize.downcase
            val.each do |associated|
              associated[ key ] ||= []
              associated[ key ] << self
              associated[ key ].uniq!
            end
            self[joint] = val
          end
        end
      end

    end
  end
end