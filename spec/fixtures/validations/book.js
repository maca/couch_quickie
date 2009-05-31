function( newDoc, savedDoc, user ){
  var errors = {};

  function addError( field, message ){
    errors[field] = errors[field] || [];
    errors[field].push( message );
  }

  function isEmpty( obj ){
    for( var i in obj ){ return false; }
    return true;
  }

  function validatePresent( field, message ) {
    message = message || "can't be blank";
    if ( !newDoc[field] ){ addError( field, message ) };
  }

  if ( newDoc.json_class == 'Person' ){
    validatePresent( 'name' );
  }

  if ( !isEmpty( errors ) ){ throw( {forbidden : errors} ) };
} 

