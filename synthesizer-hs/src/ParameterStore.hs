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
import Utils (sortMaybePair, zipWith3)

type ParameterStore = Map.Map Int SoundStream

type ParameterExtractor a = ParameterStore -> State.T a

data StoreParameterizedStream b = forall a. Storable a => StoreParamStream !(ParameterExtractor a) !(ParameterizedStream a b)

storeParameterizedStreamFromIndex :: Int -> ParameterizedStream ElementType b -> StoreParameterizedStream b
storeParameterizedStreamFromIndex index =
  StoreParamStream (\store -> toState $ fromMaybe zeroSignal $ store Map.!? index)

storeParameterizedStreamFromIndex3 :: (Int, Int, Int) -> ParameterizedStream (ElementType, ElementType, ElementType) b -> StoreParameterizedStream b
storeParameterizedStreamFromIndex3 (i0, i1, i2) = StoreParamStream (\store ->
  let constituent0 = (toState $ fromMaybe zeroSignal $ store Map.!? i0) :: State.T ElementType
      constituent1 = (toState $ fromMaybe zeroSignal $ store Map.!? i1) :: State.T ElementType
      constituent2 = (toState $ fromMaybe zeroSignal $ store Map.!? i2) :: State.T ElementType
  in
    Utils.zipWith3 toTuple3 constituent0 constituent1 constituent2 :: State.T (ElementType, ElementType, ElementType))

toTuple3 a b c = (a, b, c)

unparameterizedStream :: GeneralSignalType sig b => sig b -> StoreParameterizedStream b
unparameterizedStream stream = StoreParamStream (const unitSignal) (Causal.feed stream)


mapStoreParameterized :: (a -> b) -> StoreParameterizedStream a -> StoreParameterizedStream b
mapStoreParameterized mapper (StoreParamStream ext stream) = StoreParamStream ext (fmap mapper stream)

composeParameterizedStream :: ParameterizedStream a b -> StoreParameterizedStream a -> StoreParameterizedStream b
composeParameterizedStream parameterizedStream (StoreParamStream ext stream) = let newStream = Causal.compose stream parameterizedStream
  in StoreParamStream ext newStream

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

advanceWithStore :: Int -> ParameterStore -> StoreParameterizedStream ElementType -> (SigSt.T ElementType, Maybe (StoreParameterizedStream ElementType))
advanceWithStore n parameterStore (StoreParamStream paramExtractor parameterizedStream) =
  let
    parameterStream = paramExtractor parameterStore
    (streamSegment, nextParamStreamMaybe) = generateNext n parameterizedStream parameterStream
  in
    (streamSegment, fmap (StoreParamStream paramExtractor) nextParamStreamMaybe)

combineParameterizedSignals :: (a -> b -> c) -> StoreParameterizedStream a -> StoreParameterizedStream b -> StoreParameterizedStream c
combineParameterizedSignals fn (StoreParamStream ex0 st0) (StoreParamStream ex1 st1) = let
  newEx = liftA2 SigG.zip ex0 ex1
  constructedStream = Causal.split st0 st1
  output = fmap (uncurry fn) constructedStream
  in
  StoreParamStream newEx output
