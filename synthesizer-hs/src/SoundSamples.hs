module SoundSamples where

import Data.Ord
import qualified Synthesizer.Generic.Signal as SigG
import BaseStream (sineWaveWithFrequency)
import Operations (cycleSounds, phasor, cosByPhase, modulate)
import Data.List (foldl1')

cyclingSounds = let sounds = [sineWaveWithFrequency 723
                             , sineWaveWithFrequency 932
                             , sineWaveWithFrequency 1012]
            in
              cycleSounds 1.0 sounds

cosFadingAlerts freq = let bigPhasor = SigG.map (*3) $ phasor 0.7
                           clampBands = map (\p -> (p, p + 1)) [0..2]
                           phaseParts = map (\band -> SigG.map (\s -> clamp band s * 0.5 - 0.25) bigPhasor) clampBands
                           -- freqs = [freq, freq * sqrt 2, freq * 2]
                           freqs = [723, 932, 1012]
                           cosModulated = zipWith (\freq cosPhase -> sineWaveWithFrequency freq `modulate` cosByPhase cosPhase) freqs phaseParts
                       in
                           foldl1' SigG.mix cosModulated
