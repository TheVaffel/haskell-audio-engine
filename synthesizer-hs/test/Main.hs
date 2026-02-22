
module Main where

import System.Exit (ExitCode)
import Data.Functor (($>))

import qualified Synthesizer.Storable.Signal as Sig
import qualified Synthesizer.Generic.Cut as Cut

import Design.Police

main :: IO ()
main = writeFile "./test_plot_data.txt" createString

createString = let stream = exponentialOscillator 36.0 2.0
               in
                 unlines . map show  $ Sig.toList $ Cut.take 44100 stream
