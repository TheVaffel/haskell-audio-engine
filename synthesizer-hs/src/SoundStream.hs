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

type ElementType = Float
type SoundStream = SigSt.T ElementType
type WaveDef = Wave.T Float Float



type SignalType sig = (SigG.Write sig ElementType,
                        SigG.Transform sig (UniFilter.Result ElementType),
                        SigG.Write sig (UniFilter.Parameter ElementType))

type SoundGenerator = SigState.T ElementType


fn :: SignalType sig => sig ElementType -> sig ElementType
fn sg = sg

b :: SoundGenerator
b = undefined

a = fn b

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
staticFrequencyWave :: SignalType sig =>  WaveDef -> Float -> sig ElementType
staticFrequencyWave wave frequency = Osci.static defaultLazySize wave zero (frequency / sampleRateF)
