module Instrument where

import SoundStream (ElementType, SoundStream, sampleRate)
import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Generic.Control as Con
import qualified Synthesizer.Generic.Oscillator as Osci
import Synthesizer.Generic.Signal (defaultLazySize)

import Synthesizer.Basic.Phase (fromRepresentative)
import RawStream (sineWave, sineWaveWithFrequency)


bell :: ElementType -> SoundStream
bell frequency = let halfLife = 0.5
                     sampleRateF = fromIntegral sampleRate
     in SigG.zipWith3 (\x y z -> (x + y + z) / 3)
        (bellHarmonic sampleRateF 1.0 halfLife frequency)
        (bellHarmonic sampleRateF 4.0 halfLife frequency)
        (bellHarmonic sampleRateF 7.0 halfLife frequency)

bellHarmonic :: ElementType -> ElementType -> ElementType -> ElementType -> SoundStream
bellHarmonic sampleRate n halfLife freq =
    SigG.zipWith (*) (Osci.freqModSine (fromRepresentative 0)
                      (SigG.map (\modu -> freq / sampleRate * n * (1.0 + 0.005 * modu))
                        (Osci.staticSine defaultLazySize (fromRepresentative 0) (5.0 / sampleRate))))
                (Con.exponential2 defaultLazySize (halfLife/ n * sampleRate ) 1)
