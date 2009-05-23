
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

class Hash
  #from Rails
  def strigify_keys
    inject({}) do |options, (key, value)|
      options[key.to_s] = value
      options
    end
  end
  
  # Returns a new hash with +self+ and +other_hash+ merged recursively. 
  # From Rails
  def deep_merge(other_hash)
    self.merge(other_hash) do |key, oldval, newval|
      oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
      newval = newval.to_hash if newval.respond_to?(:to_hash)
      oldval.class.to_s == 'Hash' && newval.class.to_s == 'Hash' ? oldval.deep_merge(newval) : newval
    end
  end

  # Returns a new hash with +self+ and +other_hash+ merged recursively.
  # Modifies the receiver in place.
  # From Rails
  def deep_merge!(other_hash)
    replace(deep_merge(other_hash))
  end
  
end

class Symbol
  def to_proc
    Proc.new { |obj, *args| obj.__send__(self, *args) }
  end
end