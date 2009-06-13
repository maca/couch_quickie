module CouchQuickie
  module Document
    class Base < Document::Generic

      include Document::Associations
      include Document::Validation

      # Expects an attributes hash
      def initialize hash = {}
        self['_id']         ||= @@uuid.generate   unless self.class == Design
        self['_associations'] = associations.keys unless associations.empty?
        self['_joint_name']   = self.class.to_s.pluralize.downcase
        super
      end

      # It will create a new database document if the Document hasn't been saved or it will update it if it has.
      # Will raise an error if the database or updating document does not exists or any other problem occurs.
      # Options:
      #  Atomic, validate, depth
      def save! opts = {}
        docs     = prepare_to_save_with_associations
        response = database.bulk_save docs, { :atomic => true }.merge( opts )
        pristine_copy
        response
      end

      def delete!
        response = database.delete self
        pristine_copy
        response
      end
      
      # Returns the +Database+ which is shared among all instances of the class
      def database; self.class.database; end

      def mark_to_delete!; self['_deleted'] = true; end

      def to_delete?; self['_deleted']; end

      def <=> other; id <=> other.id; end
      
      def to_json depth = 1
        copy = self.dup
        associations.keys.each do |name| copy.delete name end
        {}.merge( copy ).to_json
      end

      class << self
        @@uuid = UUID.new

        # Returns the database for the Document Class
        def database; @database; end

        # Returns the design for the Document Class
        def design; @design; end

        # Key can be a Symbol, String or Document Hash, if key is a Symbol it will get all the documents emited by a view
        # of that name otherwise it will get the requested document by id.
        def get key, opts = {}
          case key
          when Symbol: design.get key,  opts
          when Array:  design.get :all, opts.merge( :keys => key )
          else
            database.get key, opts
          end
        end

        protected
        # Sets the database for the Document Class and the associated <tt>Design</tt>
        def set_database database
          @database        = database.kind_of?( Database ) ? database : Database.new( database )
          @design.database = @database
          @design.save!
        end

        def init_class_instance_variables #:nodoc:
          @design       = Design.new 'document_class' => self.to_s
          @associations = {}
        end

        def inherited klass #:nodoc:
          klass.init_class_instance_variables #associations are not inherited
        end      
      end
    end
  end
end