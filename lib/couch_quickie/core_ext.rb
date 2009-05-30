
# Provides a simple and generic way of (de)serializing JSON representations of an Object, hopefully it will restore
# the object to the state prior to serializing.
class Object
  # Encodes all instance variables to JSON
  def self.json_create( object )
    obj = allocate
    for key, value in object
      next if key == 'json_class'
      obj.__send__ :instance_variable_set, "@#{key}", value
    end
    obj
  end
  
  def to_a
    [self]
  end
end

class Array
  def to_a
    self
  end
end

module Enumerable
  # Returns a new hash with +self+ and +other_hash+ merged recursively. 
  # From Rails
  def deep_combine(other_hash)
    self.merge(other_hash) do |key, oldval, newval|
      if oldval.kind_of?( Hash ) and newval.kind_of?( Hash ) 
        oldval.deep_combine newval
      elsif oldval.kind_of?( Array ) or oldval.kind_of?( Array )
        oldval.to_a + newval.to_a
      else
        newval
      end
    end
  end

  # Returns a new hash with +self+ and +other_hash+ merged recursively.
  # Modifies the receiver in place.
  # From Rails
  def deep_combine!(other_hash)
    replace( deep_merge(other_hash) )
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
  
  def deep_merge(other_hash)
    self.merge(other_hash) do |key, oldval, newval|
      oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
      newval = newval.to_hash if newval.respond_to?(:to_hash)
      oldval.class.to_s == 'Hash' && newval.class.to_s == 'Hash' ? oldval.deep_merge(newval) : newval
    end
  end

  # Returns a new hash with +self+ and +other_hash+ merged recursively.
  # Modifies the receiver in place.
  def deep_merge!(other_hash)
    replace(deep_merge(other_hash))
  end
  
  # Returns a hash that represents the difference between two hashes.
  #
  # Examples:
  #
  #   {1 => 2}.diff(1 => 2)         # => {}
  #   {1 => 2}.diff(1 => 3)         # => {1 => 2}
  #   {}.diff(1 => 2)               # => {1 => 2}
  #   {1 => 2, 3 => 4}.diff(1 => 2) # => {3 => 4}
  # From Rails
  def diff(h2)
    self.dup.delete_if { |k, v| h2[k] == v }.merge( h2.dup.delete_if { |k, v| self.has_key?(k) } )
  end
end

class Symbol
  def to_proc
    Proc.new { |obj, *args| obj.__send__(self, *args) }
  end
end