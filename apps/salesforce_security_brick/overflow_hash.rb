require 'gdbm'
require 'tempfile'

class OverflowHash

  def initialize(max_memory_capacity)
    @max_memory_capacity = max_memory_capacity
    @memory_hash = {}
    @gdbm = GDBM.new(Tempfile.new('gdbm-overflow-hash.db').path)
  end

  def key?(key)
    @memory_hash.key?(key) || @gdbm.key?(key)
  end

  def[]=(key, value)
    if(@memory_hash.size < @max_memory_capacity)
      @memory_hash[key] = value
    else
      @gdbm[key] = value.to_s
    end
  end
  
  def clear 
     @memory_hash.clear
     @gdbm.clear
  end
  
end