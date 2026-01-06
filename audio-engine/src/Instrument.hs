module Instrument where

import SoundStream (ElementType, SoundStream, sampleRate)
import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Generic.Control as Con
import qualified Synthesizer.Generic.Oscillator as Osci
import Synthesizer.Generic.Signal (defaultLazySize)

import Synthesizer.Basic.Phase (fromRepresentative)
import RawStream (sineWave, sineWaveWithFrequency)
import Data.Foldable1 (Foldable1(toNonEmpty))
import qualified Synthesizer.Generic.Cut as Cut


bell :: ElementType -> SoundStream
bell frequency = let halfLife = 0.5
                     sampleRateF = fromIntegral sampleRate
                     indices = [1.0, 2.0, 2.4, 3.0, 4.0]
                     streams = foldl1 SigG.mix $ map (\index -> bellHarmonic sampleRateF index halfLife frequency) indices
                     lenF = (fromIntegral . length) indices
     in Cut.take (3 * sampleRate) $ SigG.map (/ lenF) streams
bellHarmonic :: ElementType -> ElementType -> ElementType -> ElementType -> SoundStream
bellHarmonic sampleRate n halfLife freq =
    SigG.zipWith (*) (Osci.freqModSine (fromRepresentative 0)
                      (SigG.map (\modu -> freq / sampleRate * n * (1.0 + 0.005 * modu))
                        (Osci.staticSine defaultLazySize (fromRepresentative 0) (5.0 / sampleRate))))
                (Con.exponential2 defaultLazySize (halfLife/ n * sampleRate ) 1)
