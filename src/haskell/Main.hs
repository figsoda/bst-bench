module Main where

import qualified Data.Set as Set

main :: IO ()
main = print $ Set.size $ foldl (flip Set.insert) Set.empty [0 .. 999999]
