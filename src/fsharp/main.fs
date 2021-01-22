open System

[<EntryPoint>]
let main _ =
    seq { 0UL .. 999999UL }
        |> Seq.fold (fun set x -> Set.add x set) Set.empty
        |> Set.count
        |> printfn "%i"
    0
