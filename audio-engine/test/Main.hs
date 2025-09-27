
module Main where

import Play (sinWave, playInterleave)

import System.Exit (ExitCode)
import Data.Functor (($>))


main :: IO ExitCode
main = playInterleave (\signal -> putStrLn "Hreee" $> signal) sinWave
-- main = playSplit sinWave
-- main = playWithIO (putStrLn "haha") sinWave
