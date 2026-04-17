{-# LANGUAGE ExistentialQuantification #-}

module ParameterStore where

import qualified Synthesizer.Causal.Process as Causal
import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.State.Signal as State
import qualified Synthesizer.Generic.Signal as SigG
import SoundStream (ElementType, SoundStream, SignalType, GeneralSignalType)
import Parameterized (ParameterizedStream, generateNext)

import qualified Data.Map as Map
import Data.Maybe (fromMaybe)
import BaseStream (zeroSignal, unitSignal)
import Foreign.Storable (Storable)
import Operations (fadeOut)
import StreamState (defaultFadeSize)
import Synthesizer.State.Signal (toStorableSignal)
import Data.StorableVector.Lazy (defaultChunkSize)
import Synthesizer.Generic.Signal (Read0(toState))
import Utils (sortMaybePair)

type ParameterStore = Map.Map Int SoundStream

type ParameterExtractor a = ParameterStore -> State.T a

-- data StoreParameterizedStream = forall a. Storable a => StoreParamStream !(ParameterExtractor a) !(ParameterizedStream a ElementType) | CombinedWithSurvivalParamStream !(ElementType -> ElementType -> ElementType) !StoreParameterizedStream !StoreParameterizedStream

data StoreParameterizedStream b = forall a. Storable a => StoreParamStream !(ParameterExtractor a) !(ParameterizedStream a b)

storeParameterizedStreamFromIndex :: Int -> ParameterizedStream ElementType b -> StoreParameterizedStream b
storeParameterizedStreamFromIndex index =
  StoreParamStream (\store -> toState $ fromMaybe zeroSignal $ store Map.!? index)

unparameterizedStream :: GeneralSignalType sig b => sig b -> StoreParameterizedStream b
unparameterizedStream stream = StoreParamStream (const unitSignal) (Causal.feed stream)


mapStoreParameterized :: (a -> b) -> StoreParameterizedStream a -> StoreParameterizedStream b
mapStoreParameterized mapper (StoreParamStream ext stream) = StoreParamStream ext (fmap mapper stream)
-- mapStoreParameterized mapper (CombinedWithSurvivalParamStream fn stream0 stream1) = CombinedWithSurvivalParamStream fn (mapStoreParameterized mapper stream0) (mapStoreParameterized mapper stream1)

composeParameterizedStream :: ParameterizedStream a b -> StoreParameterizedStream a -> StoreParameterizedStream b
composeParameterizedStream parameterizedStream (StoreParamStream ext stream) = let newStream = Causal.compose stream parameterizedStream
  in StoreParamStream ext newStream
-- composeParameterizedStream parameterizedStream (CombinedWithSurvivalParamStream fn stream0 stream1) =

-- | Takes a parameterized stream and a store and returns a fading-out stream computed from
-- the store and the parameterized stream. Useful for deleting old streams
getFadeOutParamStream :: ParameterStore -> StoreParameterizedStream ElementType -> SigSt.T ElementType
getFadeOutParamStream store stream = let
  computedStream = getStreamFromParamStore store stream
  in
  fadeOut defaultFadeSize computedStream

getStreamFromParamStore :: ParameterStore -> StoreParameterizedStream ElementType -> SigSt.T ElementType
getStreamFromParamStore store (StoreParamStream paramExtractor stream) = let
  param = paramExtractor store
  in
  Causal.apply stream (toStorableSignal defaultChunkSize param)
-- getStreamFromParamStore store (CombinedWithSurvivalParamStream fn stream0 stream1) =
--   SigG.zipWith fn (getStreamFromParamStore store stream0) (getStreamFromParamStore store stream1)

advanceWithStore :: Int -> ParameterStore -> StoreParameterizedStream ElementType -> (SigSt.T ElementType, Maybe (StoreParameterizedStream ElementType))
advanceWithStore n parameterStore (StoreParamStream paramExtractor parameterizedStream) =
  let
    parameterStream = paramExtractor parameterStore
    (streamSegment, nextParamStreamMaybe) = generateNext n parameterizedStream parameterStream
  in
    (streamSegment, fmap (StoreParamStream paramExtractor) nextParamStreamMaybe)
{- advanceWithStore n parameterStore (CombinedWithSurvivalParamStream fn stream0 stream1) = let
  (segment0, maybeRest0) = advanceWithStore n parameterStore stream0
  (segment1, maybeRest1) = advanceWithStore n parameterStore stream1
  resultStream = SigG.zipWith fn segment0 segment1
  sortedMaybeRests = sortMaybePair (maybeRest0, maybeRest1)
  in
  case sortedMaybeRests of
    (Nothing, maybeOrNothingRest) -> (resultStream, maybeOrNothingRest)
    (Just something0, Just something1) -> (resultStream, Just $ CombinedWithSurvivalParamStream fn something0 something1) -}

combineParameterizedSignals :: (a -> b -> c) -> StoreParameterizedStream a -> StoreParameterizedStream b -> StoreParameterizedStream c
combineParameterizedSignals fn (StoreParamStream ex0 st0) (StoreParamStream ex1 st1) = let
  newEx = liftA2 SigG.zip ex0 ex1
  constructedStream = Causal.split st0 st1
  output = fmap (uncurry fn) constructedStream --  ::  (Causal.T (u1, u2) a)
  in
  StoreParamStream newEx output

-- combineParameterizedSignals :: (ElementType -> ElementType -> ElementType) -> StoreParameterizedStream -> StoreParameterizedStream -> StoreParameterizedStream
-- combineParameterizedSignals = CombinedWithSurvivalParamStream
