module CouchQuickie
  module Document
    module Validation

      class Errors
      end

      class Evaluator
      end

      def self.included base
        base.send :extend, ClassMethods
      end
      
      def valid?
      end
      
      module ClassMethods
        def validation &block
          file, line        = caller.first.match(/(.*):(\d+)/)[1..2]
          line              = line.to_i - 1
          source            = File.readlines file
          @validation_block = block
          
          sexp  = SafeRubyParser.new.parse( source[line..-1].join )
          sexp  = sexp.assoc(:iter) || sexp # hacky, SafeRubyParser is parsing from line to end, it shouldn't
          
          error_def = 
          'class Errors
            def add field, message
              self[field] ||= []
              self[field].push message
            end
          end
          errors = Errors.new'
          
          
          
          body  = s( :block, RubyParser.new.parse(error_def) )

          
          
          design['validate_doc_update'] = Ruby2JS.new( s(:function, sexp[2], body), :implicit_ret => false ).to_js
        end
      end

    end
  end
end    