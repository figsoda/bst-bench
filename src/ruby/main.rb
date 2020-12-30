require "set"

set = SortedSet.new
for i in 0..999999
  set.add i
end
puts set.size
