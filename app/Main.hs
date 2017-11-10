module Main where

import Lib

main :: IO ()
main = do
  s <- read <$> getLine
  print $ solve s
