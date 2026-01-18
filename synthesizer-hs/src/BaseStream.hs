module BaseStream where

import qualified Synthesizer.Generic.Noise as Noise
import SoundStream (SoundStream, interactiveLazySize, sampleRateF)

import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.Basic.Wave as Wave
import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Generic.Oscillator as Osci

import qualified Synthesizer.Generic.Cut as Cut

import CircularBuffer (ElementType)

import Filter (lowPassFilter)

import NumericPrelude.Numeric (zero)
import Synthesizer.Generic.Signal (defaultLazySize)

noise :: SoundStream
noise = SigG.map (*1.0) $ Noise.white defaultLazySize

lfo :: Float -> SoundStream
lfo frequency = let staticStream = Osci.static defaultLazySize Wave.square zero (frequency / sampleRateF)
  in
  lowPassFilter (frequency * 40) staticStream

ampMultiplier = 0.06

sineWave :: SoundStream
sineWave = SigSt.map (*ampMultiplier) $ Osci.static interactiveLazySize Wave.sine zero (0.01::Float)

sineWaveWithFrequency :: ElementType -> SoundStream
sineWaveWithFrequency f = SigSt.map (*ampMultiplier) $ Osci.static interactiveLazySize Wave.sine zero (f / sampleRateF)

zeroSignal :: SoundStream
zeroSignal = Cut.cycle $ SigG.repeat interactiveLazySize 0.0
