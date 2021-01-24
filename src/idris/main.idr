module Main

%default total

data Tree : Type -> Type where
  Empty : Tree a
  Node : Nat -> a -> Tree a -> Tree a -> Tree a

insert : Ord a => Tree a -> a -> Tree a
insert Empty x = Node 1 x Empty Empty
insert t@(Node n v l r) x =
  case compare x v of
    LT => fixup $ Node n v (insert l x) r
    EQ => t
    GT => fixup $ Node n v l (insert r x)
  where
    skew : Tree a -> Tree a
    skew t@(Node nx x (Node ny y ly ry) rx) =
      if nx == ny then Node ny y ly (Node nx x ry rx) else t
    skew t = t

    split : Tree a -> Tree a
    split t@(Node nx x lx (Node _ y ly tz@(Node nz _ _ _))) =
      if nx == nz then Node (S nx) y (Node nx x lx ly) tz else t
    split t = t

    fixup : Tree a -> Tree a
    fixup = split . skew

count : Tree a -> Nat
count Empty = Z
count (Node _ _ l r) = S $ count l + count r

main : IO ()
main = printLn $ count $ foldl insert Empty [the Int 0 .. 999999]
