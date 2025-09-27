module RawStream (sineWave, sineWaveWithFrequency, zeroSignal ) where
import SoundStream (SoundStream, interactiveLazySize, sampleRate)

import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.Basic.Wave as Wave
import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Generic.Oscillator as Osci

import qualified Synthesizer.Generic.Cut as Cut

import NumericPrelude.Numeric ( zero )
import CircularBuffer (ElementType)

ampMultiplier = 0.06

sineWave :: SoundStream
sineWave = SigSt.map (*ampMultiplier) $ Osci.static interactiveLazySize Wave.sine zero (0.01::Float)

sineWaveWithFrequency :: ElementType -> SoundStream
sineWaveWithFrequency f = SigSt.map (*ampMultiplier) $ Osci.static interactiveLazySize Wave.sine zero (f / fromIntegral sampleRate)

zeroSignal :: SoundStream
zeroSignal = Cut.cycle $ SigG.repeat interactiveLazySize 0.0
