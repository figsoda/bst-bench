module Main where

import qualified Data.Set as Set
import Data.Word (Word64)

main :: IO ()
main = print $ Set.size $ foldl
  (flip Set.insert)
  (Set.empty :: Set.Set Word64)
  [0 .. 999999]
