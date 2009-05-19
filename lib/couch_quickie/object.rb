
# Provides a simple and generic way of (de)serializing JSON representations of an Object, hopefully it will restore
# the object to the state prior to serializing.
class Object
  def self.json_create( object )
    obj = allocate
    for key, value in object
      next if key == 'json_class'
      obj.__send__ :instance_variable_set, "@#{key}", value
    end
    obj
  end
end