{-# LANGUAGE ConstraintKinds #-}

module SoundStream where

import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.Generic.Control as Con
import Synthesizer.Generic.Signal (defaultLazySize)
import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.State.Signal as SigState
import qualified Synthesizer.Generic.Cut as Cut
import qualified Synthesizer.Basic.Wave as Wave
import qualified Synthesizer.Generic.Oscillator as Osci
import Algebra.Additive (C(zero))
import qualified Synthesizer.Plain.Filter.Recursive.Universal as UniFilter
import qualified Synthesizer.Causal.Oscillator as CausOsc

type ElementType = Float
type SoundStream = SigSt.T ElementType
type WaveDef = Wave.T Float Float



type GeneralSignalType sig a = (SigG.Write sig a,
                                SigG.Transform sig (UniFilter.Result a),
                                SigG.Write sig (UniFilter.Parameter a),
                                Cut.Transform (sig a))

type SignalType sig = GeneralSignalType sig ElementType

type SoundGenerator = SigState.T ElementType

sampleRate = 44100 :: Int

sampleRateF = fromIntegral sampleRate :: Float

interactiveBufferSize :: Int
interactiveBufferSize = 256

interactiveLazySize :: SigG.LazySize
interactiveLazySize = SigG.LazySize interactiveBufferSize

asStream :: Float -> SoundStream
asStream = Con.constant defaultLazySize

-- | Converts a wave definition to a sound stream of static frequency
-- arg0: Wave definition
-- arg1: frequency in Hz
staticFrequencyWave :: GeneralSignalType sig ElementType =>  WaveDef -> Float -> sig ElementType
staticFrequencyWave wave frequency = Osci.static defaultLazySize wave zero (frequency / sampleRateF)

isEmpty :: GeneralSignalType sig a => sig a -> Bool
isEmpty = not . Cut.lengthAtLeast 1
