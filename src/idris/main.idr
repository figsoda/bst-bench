module Main

%default total

data Tree a = Empty | Node Nat a (Tree a) (Tree a)

record Set a where
  constructor MkSet
  count : Nat
  tree : Tree a

empty : Set a
empty = MkSet 0 Empty

insert : Ord a => Set a -> a -> Set a
insert s@(MkSet n t) = maybe s (MkSet $ S n) . ins t where
  skew : Tree a -> Tree a
  skew t@(Node nx x (Node ny y ly ry) rx) =
    if nx == ny then Node ny y ly (Node nx x ry rx) else t
  skew t = t

  split : Tree a -> Tree a
  split t@(Node nx x lx (Node _ y ly tz@(Node nz _ _ _))) =
    if nx == nz then Node (S nx) y (Node nx x lx ly) tz else t
  split t = t

  ins : Tree a -> a -> Maybe (Tree a)
  ins Empty x = Just $ Node 1 x Empty Empty
  ins (Node n v l r) x = case compare x v of
    LT => map (split . skew . Node n v l) $ ins r x
    EQ => Nothing
    GT => map (\t => split $ skew $ Node n v t r) $ ins l x

main : IO ()
main = printLn $ count $ foldl insert empty [the Int 0 .. 999999]
