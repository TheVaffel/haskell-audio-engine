module Parameterized where

import qualified Synthesizer.Causal.Process as Causal
import qualified Synthesizer.Causal.Oscillator as CausOsc
import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.State.Signal as State

import Control.Arrow ((^<<), (<<^), (^>>))
import Algebra.Additive (C(zero))

import Control.Monad.Trans.State (runStateT)

import qualified Synthesizer.Basic.Wave as Wave

import qualified Data.StorableVector as SV
import qualified Data.StorableVector.Lazy as SVL
import CircularBuffer (ElementType)
import Foreign (Storable)
import qualified Data.Map as Map
import SoundStream (SoundStream, SignalType, GeneralSignalType, sampleRateF)
import qualified  Data.Kind as Kind (Type)

type ParameterizedStream = Causal.T

freqParamSine :: ParameterizedStream ElementType ElementType
freqParamSine = (/ sampleRateF) ^>> CausOsc.freqMod Wave.sine zero

type CausalAndParamState a b = (Causal.T a b, State.T a)

generateNext :: (Storable b, GeneralSignalType sig a) => Int -> ParameterizedStream a b -> sig a -> (SigSt.T b, Maybe (ParameterizedStream a b))
generateNext n caus param =
  let
    initialState = (caus, SigG.toState param)
    transition (Causal.Cons causalTransition causalState,
                State.Cons stateTransition stateState) = do
      (stateValue, nextStateState) <- runStateT stateTransition stateState
      (causalValue, nextCausalState) <- runStateT (causalTransition stateValue) causalState
      return (causalValue,
              (Causal.Cons causalTransition nextCausalState,
               State.Cons stateTransition nextStateState))
    (storedResult, maybeFinalState) = SV.unfoldrN n transition initialState
  in
    (SVL.SV [storedResult], fmap fst maybeFinalState)
