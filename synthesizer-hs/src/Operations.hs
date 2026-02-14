module Operations where

import Data.List (foldl')

import Synthesizer.Storable.Signal (mix)
import qualified Synthesizer.Storable.Signal as SigG
import qualified Synthesizer.Generic.Cut as Cut (take)
import Synthesizer.Generic.Control (constant, line, linear)
import qualified Synthesizer.Basic.Wave as Wave
import qualified Synthesizer.Generic.Oscillator as Osci
import qualified Synthesizer.Generic.Filter.NonRecursive as Filt

import SoundStream (SoundStream, sampleRateF)
import BaseStream (zeroSignal)
import Synthesizer.Generic.Signal (defaultLazySize)

import Filter (lowPassFilter)

import NumericPrelude.Numeric (zero)

runWithTimings :: Int -> [(Float, SoundStream)] -> SoundStream
runWithTimings maxLength = foldl' (runWithTimings' maxLength) zeroSignal

runWithTimings' :: Int -> SoundStream -> (Float, SoundStream) -> SoundStream
runWithTimings' maxLength prevStream (deltaT, newStream) =
  let delay = Cut.take (round (sampleRateF * deltaT)) $ constant defaultLazySize 0.0
  in

  mix prevStream $ delay <> Cut.take maxLength newStream


secondsSignal :: SoundStream
secondsSignal = linear defaultLazySize (1.0 / sampleRateF) 0

cycleSounds :: Float -> [SoundStream] -> SoundStream
cycleSounds fullCycleTime streams = let l = length streams
                                        hatFuncs = map (lowPassFilter 70 . hatFunc fullCycleTime (fromIntegral l)) [0 .. (l-1)]
  in
  foldl1 mix (zipWith modulate hatFuncs streams)


hatFunc :: Float -> Float -> Int -> SoundStream
hatFunc fullCycleTime l i = let wave = Wave.fromFunction $ \x -> if x * l >= fromIntegral i && x * l < (fromIntegral i + 1) then 1 else 0
                            in
                              Osci.static defaultLazySize wave zero (1.0 / (fullCycleTime * sampleRateF))

modulate :: SoundStream -> SoundStream -> SoundStream
modulate = SigG.zipWith (*)

fadeOut :: Int -> SoundStream -> SoundStream
fadeOut n stream =
  let envelope = line defaultLazySize n (1.0, 0.0)
  in
    Filt.envelope envelope stream

fadeIn :: Int -> SoundStream -> SoundStream
fadeIn n stream =
  let envelope = line defaultLazySize n (0.0, 1.0) <> constant defaultLazySize 1.0
  in
    Filt.envelope envelope stream

crossFade :: Int -> SoundStream -> SoundStream -> SoundStream
crossFade n initial end =
  let initialFadeOut = fadeOut n initial
      endFadeIn = fadeIn n end
  in
    SigG.mix initialFadeOut endFadeIn
