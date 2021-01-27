module Array = Belt.Array
module Set = Belt.Set.Int

Array.range(0, 999999)
-> Array.reduce(Set.fromArray([]), Set.add)
-> Set.size
-> Belt.Int.toString
-> Js.log
