module CouchQuickie
  module Document
    module Validation
      
      VALIDATIONS = {
        :must_be_present => 
%(
function must_be_present(args){
  for ( var i in args.values ) {
    var key = args.values[i]
    if (!doc[key]) errors.add( key, args.message || "can't be blank" )
  }
})
      }

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
          calls = []
          
          body  = Ruby2JS.new( sexp.pop, :implicit_ret => false, :pretty_print => true ) do |sexp|
            next sexp unless sexp.first == :call
            next sexp unless VALIDATIONS.keys.include? sexp[2]            
            calls  << sexp[2]
            args    = sexp.pop
            args[0] = :array
            sexp.push ( args.find_node(:hash, true) || s(:hash) ).push( s(:lit, :values), args )
          end.to_js
                    
          puts design['validate_doc_update'] = 
%(function(#{ sexp[2].last[1..-1].collect{ |e| e.last.to_s }.join(', ') }) {
  
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
  #{ calls.uniq.collect{ |c| VALIDATIONS[c] }.join(";\n") };
  
  #{ body }
}  
)
        end
      end

    end
  end
end    