module Design.Police where

import BaseStream (phasor, sineWaveWithFrequency)
import SoundStream (sampleRateF, SoundStream)
import qualified  Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Generic.Oscillator as Osci
import Synthesizer.Generic.Signal (defaultLazySize)
import qualified Synthesizer.Basic.Wave as Wave
import Algebra.Additive (C(zero))

-- | An oscillator mimicing astable capacitor-based oscillator circuits
-- arg0: base used for the exponential. Values of 30 and up give noticable exponentiation
-- arg1: frequency of oscillation (in Hz)
exponentialOscillator :: Float -> Float -> SoundStream
exponentialOscillator base frequency = let scaledPhasor = SigG.map (*2) $  phasor frequency
                                           toUpExp v = let timeBase = 2 - max 1 v
                                             in
                                             (base ** timeBase - base) / (1 - base)
                                           toDownExp v = let timeBase = 1 - min 1 v
                                             in
                                             (base ** timeBase - 1) / (base - 1)
                                  in
                                    SigG.mix (SigG.map toUpExp scaledPhasor) ( SigG.map toDownExp scaledPhasor)

exponentialFreq frequency =
  Osci.freqMod Wave.sine zero $ SigG.map (\v -> (v * 300 + 700) / sampleRateF) (exponentialOscillator 36.0 frequency)
