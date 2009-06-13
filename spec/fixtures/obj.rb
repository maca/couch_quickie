class Obj
  def initialize( uno, dos, tres, cuatro, cinco )
    @uno, @dos, @tres, @cuatro, @cinco = uno, dos, tres, cuatro, cinco
  end
  
  def to_array
    [@uno, @dos, @tres, @cuatro, @cinco]
  end
  
  def == other
    giv( self ) == giv( other )
  end
  
  def giv obj
    obj.instance_variables.collect do |var| 
      obj.send :instance_variable_get, var
    end
  end
end