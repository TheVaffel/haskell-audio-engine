module Design.Police where

import Data.Ord
import BaseStream (phasor, sineWaveWithFrequency, zeroSignal)
import SoundStream (sampleRateF, SoundStream, WaveDef, staticFrequencyWave, SoundGenerator, ElementType, SignalType)
import qualified  Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.State.Signal as SigState
import qualified Synthesizer.Generic.Oscillator as Osci
import Synthesizer.Generic.Signal (defaultLazySize, mix)
import qualified Synthesizer.Basic.Wave as Wave
import Algebra.Additive (C(zero))
import Filter (bandPassFilter)
import Synthesizer.Basic.Wave (triangle)
import qualified Synthesizer.State.Signal as SigState
import Synthesizer.ALSA.Storable.Play (defaultChunkSize)

-- | An oscillator mimicing astable capacitor-based oscillator circuits
-- arg0: base used for the exponential. Values of 30 and up give noticable exponentiation
exponentialOscillatorWave :: Float -> WaveDef
exponentialOscillatorWave base = Wave.fromFunction (\t ->
                                                      let scaledPhasorValue = t * 2
                                                          toUpExp v = let timeBase = 2 - max 1 v
                                                            in
                                                            (base ** timeBase - base) / (1 - base)
                                                          toDownExp v = let timeBase = 1 - min 1 v
                                                            in
                                                            (base ** timeBase - 1) / (base - 1)
                                  in
                                    toUpExp scaledPhasorValue + toDownExp scaledPhasorValue)

exponentialOscillator :: Float -> Float -> SoundGenerator
exponentialOscillator base frequency =
  Osci.static defaultLazySize (exponentialOscillatorWave base) zero (frequency / sampleRateF)

exponentialFreq frequency =
  Osci.freqMod Wave.sine zero $ SigG.map (\v -> (v * 300 + 700) / sampleRateF) (exponentialOscillator 36.0 frequency)

exponentialOscillatorByTheBookWave :: WaveDef
exponentialOscillatorByTheBookWave =
  Wave.fromFunction (\t ->
                       let scaledPhasorValue = t * 2
                           toUpExp v = let timeBase = 1 - min 1 v
                             in
                             1 - exp timeBase
                           toDownExp v = let timeBase = 2 - max 1 v
                             in
                             exp timeBase
                       in
                         ((toUpExp scaledPhasorValue + toDownExp scaledPhasorValue) - 1) / 1.75)

exponentialOscillatorByTheBook :: Float -> SoundGenerator
exponentialOscillatorByTheBook frequency =
  Osci.static defaultLazySize exponentialOscillatorByTheBookWave zero (frequency / sampleRateF)

plasticHorn :: SignalType sig => sig ElementType -> sig ElementType
plasticHorn driver = let clamped = SigG.map (clamp (-0.2, 0.2)) driver
                     in
                       bandPassFilter 4.0 1500.0 clamped

delay seconds signal = SigG.take (round (seconds * sampleRateF)) zeroSignal <> signal

subUrbanEnvironment :: SoundGenerator -> SoundGenerator
subUrbanEnvironment input = let delayerDimFn sig = let
                                  del0 = delay 0.165 sig
                                  del1 = delay 0.121 sig
                                  del2 = delay 0.33 sig
                                  in
                                  SigG.map (*0.1) (del0 `mix` del1 `mix` del2)
                                output = SigState.toStorableSignal defaultChunkSize input `mix` delayerDimFn output
                            in
                              SigG.toState output

-- | Electronic signal from siren, without amplification and environment involved
-- arg0: dummy argument that is ignored, but used to ensure that the result is garbage-collected properly
-- (Not sure if it actually works, but oh well)
semiFullSiren :: Float -> SoundGenerator
semiFullSiren _ =
  let modulatingWave = exponentialOscillatorByTheBookWave -- exponentialOscillatorWave 2.72
      baseSoundWave = modulatingWave -- triangle
      modulatorFrequency = 0.2
      modulator = SigG.map (\v -> (v * 800.0 + 300.0) / sampleRateF) $
        staticFrequencyWave modulatingWave modulatorFrequency
      modulatedOscillator = Osci.freqMod baseSoundWave zero modulator
  in
    modulatedOscillator

fullSiren :: Float -> SoundGenerator
fullSiren _ = subUrbanEnvironment $
            plasticHorn $
            semiFullSiren 0
