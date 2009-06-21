module CouchQuickie
  module Document
    module Validation
      
    

      def self.included base
        base.send :extend, ClassMethods
      end
      
      def valid?
      end
      
      module ClassMethods
                
        def validate &block
          file, line        = caller.first.match(/(.*):(\d+)/)[1..2]
          line              = line.to_i - 1
          source            = File.readlines file
          @validation_block = block

          sexp  = SafeRubyParser.new.parse( source[line..-1].join )
          sexp  = sexp.assoc(:iter) || sexp
          
          val_args = sexp.find_nodes :lasgn
          val_args = sexp.find_node(:masgn).last.find_nodes(:lasgn) if val_args.empty?
          val_args.each { |val| val[0] = :lvar  }
          
          body     = Ruby2JS.new( sexp.pop, :implicit_ret => false, :pretty_print => true ) do |sexp|
            next sexp unless sexp.first == :call
            case sexp[2]
            when :must_be_present
              args    = sexp.pop
              message = s(:str, "can't be blank")
              if opts = args.find_node(:hash, true)
                if index  = opts.index( s(:lit, :message) )
                  message = opts[index + 1]
                end
              end
              args = args[1..-1].collect! do |cond|
                attribute = cond[2] == :[] ? cond.last.last.dup : s(:str, cond[2])
                s(:if, s(:not, cond), s(:call, s(:lvar, :errors), :add, s(:arglist, attribute, message.dup) ), nil)
              end
              args.unshift :block
            else
              if val_args.include?( sexp[1] )
                next sexp if sexp[2] == :[] or sexp.last.size > 1
                s(:source, "#{ sexp[1].last }.#{ sexp[2] }")
              else
                sexp
              end
            end
              

          end.to_js
          
          puts design['validate_doc_update'] = 
%(function(#{ val_args.collect{ |arg| arg.last }.join(', ') }) {
  
  function Errors() {};

  Errors.prototype.add = function(field, message) {
    this[field] = this[field] || [];
    this[field].push(message)
  };

  Errors.prototype.hasErrors = function(){
     for( var i in this ){
       if( typeof(this[i]) != "function" ) return true;
      }
     return false;
  };
  
  var error = new Errors;
  
  #{ body }
}  
)
        end
      end

    end
  end
end    