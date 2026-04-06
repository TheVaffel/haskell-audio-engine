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

data StoreParameterizedStream = forall a. Storable a => StoreParamStream !(ParameterExtractor a) !(ParameterizedStream a ElementType) | CombinedStoreParamStream !(ElementType -> ElementType -> ElementType) !StoreParameterizedStream !StoreParameterizedStream

storeParameterizedStreamFromIndex :: Int -> ParameterizedStream ElementType ElementType -> StoreParameterizedStream
storeParameterizedStreamFromIndex index =
  StoreParamStream (\store -> toState $ fromMaybe zeroSignal $ store Map.!? index)

unparameterizedStream :: SignalType sig => sig ElementType -> StoreParameterizedStream
unparameterizedStream stream = StoreParamStream (const unitSignal) (Causal.feed stream)

mapStoreParameterized :: (ElementType -> ElementType) -> StoreParameterizedStream -> StoreParameterizedStream
mapStoreParameterized mapper (StoreParamStream ext stream) = StoreParamStream ext (fmap mapper stream)
mapStoreParameterized mapper (CombinedStoreParamStream fn stream0 stream1) = CombinedStoreParamStream fn (mapStoreParameterized mapper stream0) (mapStoreParameterized mapper stream1)

-- | Takes a parameterized stream and a store and returns a fading-out stream computed from
-- the store and the parameterized stream. Useful for deleting old streams
getFadeOutParamStream :: ParameterStore -> StoreParameterizedStream -> SigSt.T ElementType
getFadeOutParamStream store stream = let
  computedStream = getStreamFromParamStore store stream
  in
  fadeOut defaultFadeSize computedStream

getStreamFromParamStore :: ParameterStore -> StoreParameterizedStream -> SigSt.T ElementType
getStreamFromParamStore store (StoreParamStream paramExtractor stream) = let
  param = paramExtractor store
  in
  Causal.apply stream (toStorableSignal defaultChunkSize param)
getStreamFromParamStore store (CombinedStoreParamStream fn stream0 stream1) =
  SigG.zipWith fn (getStreamFromParamStore store stream0) (getStreamFromParamStore store stream1)

advanceWithStore :: Int -> ParameterStore -> StoreParameterizedStream -> (SigSt.T ElementType, Maybe StoreParameterizedStream)
advanceWithStore n parameterStore (StoreParamStream paramExtractor parameterizedStream) =
  let
    parameterStream = paramExtractor parameterStore
    (streamSegment, nextParamStreamMaybe) = generateNext n parameterizedStream parameterStream
  in
    (streamSegment, fmap (StoreParamStream paramExtractor) nextParamStreamMaybe)
advanceWithStore n parameterStore (CombinedStoreParamStream fn stream0 stream1) = let
  (segment0, maybeRest0) = advanceWithStore n parameterStore stream0
  (segment1, maybeRest1) = advanceWithStore n parameterStore stream1
  resultStream = SigG.zipWith fn segment0 segment1
  sortedMaybeRests = sortMaybePair (maybeRest0, maybeRest1)
  in
  case sortedMaybeRests of
    (Nothing, maybeOrNothingRest) -> (resultStream, maybeOrNothingRest)
    (Just something0, Just something1) -> (resultStream, Just $ CombinedStoreParamStream fn something0 something1)

combineParameterizedSignals :: (ElementType -> ElementType -> ElementType) -> StoreParameterizedStream -> StoreParameterizedStream -> StoreParameterizedStream
combineParameterizedSignals = CombinedStoreParamStream
