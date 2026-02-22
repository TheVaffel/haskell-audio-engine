{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
module BaseStream where

import qualified Synthesizer.Generic.Noise as Noise
import SoundStream (SoundStream, interactiveLazySize, sampleRateF)

import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.Basic.Wave as Wave
import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Generic.Oscillator as Osci

import qualified Synthesizer.Generic.Cut as Cut
import qualified Synthesizer.Generic.Control as Con

import qualified Algebra.Ring as Ring

import CircularBuffer (ElementType)

import Filter (lowPassFilter)

import NumericPrelude.Numeric (zero)
import Synthesizer.Generic.Signal (defaultLazySize)

noise :: SoundStream
noise = SigG.map (*1.0) $ Noise.white defaultLazySize

positiveSquare :: (Num a, Ord a, Ring.C a) => Wave.T a a
positiveSquare = Wave.fromFunction $ \x -> if 2 * x < 1 then 1 else 0

lfo :: Float -> SoundStream
lfo frequency = let staticStream = Osci.static defaultLazySize positiveSquare zero (frequency / sampleRateF)
  in
  lowPassFilter 70 staticStream

sineWave :: SoundStream
sineWave = Osci.static interactiveLazySize Wave.sine zero (0.01::Float)

sineWaveWithFrequency :: ElementType -> SoundStream
sineWaveWithFrequency f = Osci.static interactiveLazySize Wave.sine zero (f / sampleRateF)

zeroSignal :: SoundStream
zeroSignal = Cut.cycle $ SigG.repeat interactiveLazySize 0.0

phasor :: Float -> SoundStream
phasor freq = let fracFreq = (freq / sampleRateF) :: Float
              in
                Osci.static defaultLazySize (Wave.fromFunction id) zero fracFreq
