open Iter

module S = Set.Make(Int64);;

iterate Int64.succ 0L
  |> take 1000000
  |> fold (fun set x -> S.add x set) S.empty
  |> S.cardinal
  |> Printf.printf "%d\n"
