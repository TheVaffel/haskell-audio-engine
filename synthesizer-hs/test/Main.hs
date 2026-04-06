module Main where

import System.Exit (ExitCode)
import Data.Functor (($>))

import qualified Synthesizer.Storable.Signal as Sig
import qualified Synthesizer.Generic.Cut as Cut
import Algebra.Additive (C(zero))
import Synthesizer.Basic.Phase

import qualified Synthesizer.Generic.Oscillator as Osci
import Synthesizer.Generic.Signal (defaultLazySize, LazySize (LazySize))
import SoundStream (SoundStream, sampleRateF)
import Text.ParserCombinators.ReadP (string)

import PlayInterleave (playWithInterleavedStoreUpdates)
import StreamStateStore (empty)


import Design.Police
import BaseStream (sineWave)
import Operations (fadeOut)
import StreamState (defaultFadeSize)

fileName0 = "./test_plot_data.txt"
fileName1 = "./test_plot_data2.txt"


main :: IO ()
main = do
  -- writeIt fileName0 byWaveDefinition
  -- writeIt fileName1 byBookWaveDefinition
  writeIt fileName0 fadeOutSine
  printLazySize

writeIt fileName stream = do
  writeFile fileName (createString stream)
  putStrLn ("Wrote stream to file " ++ fileName)


createString stream = unlines . map show  $ Sig.toList $ Cut.take 44100 stream

byWaveDefinition :: SoundStream
byWaveDefinition = Osci.static defaultLazySize (exponentialOscillatorWave 2.72) (fromRepresentative 0.5) (2.0 / sampleRateF)

fadeOutSine :: SoundStream
fadeOutSine = fadeOut defaultFadeSize sineWave

byBookWaveDefinition :: SoundStream
byBookWaveDefinition = Osci.static defaultLazySize exponentialOscillatorByTheBookWave zero (2.0 / sampleRateF)

printLazySize :: IO ()
printLazySize = print $ fromLazySize defaultLazySize

fromLazySize :: LazySize -> Int
fromLazySize (LazySize n) = n
