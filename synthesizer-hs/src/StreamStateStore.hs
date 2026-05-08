module StreamStateStore (StreamStateStore, empty, insertStream, deleteStream, insertUnmanagedStream, getSoundStreamAndAdvance, markClosed, closed, setParameter) where

import StreamState (StreamState, defaultFadeSize, fromStream, crossFadeState, fadeOutState, advance)

import Synthesizer.Storable.Signal (mix)

import SoundStream (SoundStream, ElementType, sampleRateF, isEmpty)
import BaseStream (zeroSignal)

import qualified Data.Map as Map
import Data.Foldable (Foldable(foldl'))

import Synthesizer.Generic.Cut as Cut (splitAt, take)

import Debug.Trace
import Operations (crossFade, fadeOut)
import Synthesizer.Generic.Control (line, constant)
import Synthesizer.Generic.Signal (defaultLazySize)

import qualified Synthesizer.Generic.Signal as SigG
import Data.Maybe (fromMaybe, fromJust, isJust, isNothing)
import Parameterized (ParameterizedStream)
import ParameterStore (StoreParameterizedStream, advanceWithStore, getStreamFromParamStore, getFadeOutParamStream)
import Control.Applicative (liftA)

import Utils (unzipFunctor)
import Data.Tuple.Extra (second)

data StreamStateStore = StreamStateStore {
  streamMap :: !(Map.Map Int (StoreParameterizedStream ElementType)), -- Map of global sounds with filtered state
  unmanagedStreams :: !SoundStream, -- Stream combined of all "unmanaged" sound streams.
    -- These should not last longer than at most e.g. 10 seconds to ensure performance.
    -- Does not require further follow-up from controller
  parameterMap :: !(Map.Map Int SoundStream),
  closed :: !Bool
  }

empty :: StreamStateStore
empty = StreamStateStore {
  streamMap = Map.empty,
  unmanagedStreams = zeroSignal,
  parameterMap = Map.empty,
  closed = False
  }

insertStream :: Int -> StoreParameterizedStream ElementType -> StreamStateStore -> StreamStateStore
insertStream index stream store =
  let maybePreviousStream = streamMap store Map.!? index
  in
    case maybePreviousStream of
      Just previousStream -> let
        fadingOutStream = getFadeOutParamStream (parameterMap store) previousStream
        prevUnmanagedStream = unmanagedStreams store
        in
        store { streamMap = Map.insert index stream (streamMap store),
                unmanagedStreams = prevUnmanagedStream `mix` fadingOutStream }
      Nothing -> store { streamMap = Map.insert index stream (streamMap store) }

deleteStream :: Int -> StreamStateStore -> StreamStateStore
deleteStream index store =
  let maybePreviousStream = streamMap store Map.!? index
      paramStore = parameterMap store
  in
    case maybePreviousStream of
      Nothing -> store
      Just previousStream -> let
        fadingOutStream = getFadeOutParamStream (parameterMap store) previousStream
        prevUnmanagedStream = unmanagedStreams store
        -- if isEmpty (previousStream paramStore) then
        in
          store { streamMap = Map.delete index (streamMap store),
                  unmanagedStreams = prevUnmanagedStream `mix` fadingOutStream }

setParameter :: (Int, ElementType) -> ElementType -> StreamStateStore -> StreamStateStore
setParameter (index, value) duration store =
  let previousParameter = fromMaybe zeroSignal (parameterMap store Map.!? index)
      newParameter = line defaultLazySize (round (duration * sampleRateF)) (SigG.index previousParameter 0, value) <> constant defaultLazySize value
  in
    store { parameterMap = Map.insert index newParameter (parameterMap store) }

markClosed :: StreamStateStore -> StreamStateStore
markClosed store = store { closed = True }

insertUnmanagedStream :: SoundStream -> StreamStateStore -> StreamStateStore
insertUnmanagedStream stream store = store { unmanagedStreams = unmanagedStreams store `mix` stream }

getSoundStreamAndAdvance :: Int -> StreamStateStore -> (SoundStream, StreamStateStore)
getSoundStreamAndAdvance n store =
  let
    (paramSegments, restParams) = unzipFunctor $ Map.map (Cut.splitAt n) (parameterMap store)
    (streamSegments, restStreamMaybes) = unzipFunctor $ Map.map (advanceWithStore n paramSegments) (streamMap store)
    (unmanagedStreamSegment, restUnmanagedStream) = Cut.splitAt n $ unmanagedStreams store
    totalSignal = foldl' mix unmanagedStreamSegment $ Map.elems streamSegments

  in
    (totalSignal, store { parameterMap = restParams,
                          unmanagedStreams = restUnmanagedStream,
                          streamMap = concatMaybeMap restStreamMaybes  })



updateMap :: Ord a => [(a, Maybe b)] -> Map.Map a b -> Map.Map a b
updateMap updates mp = let
  insertElems = map (second fromJust) $ filter (isJust . snd) updates
  keysToDelete = map fst $ filter (isNothing . snd) updates
  insertElements = flip $ foldr (uncurry Map.insert)
  deleteKeys = flip $ foldr Map.delete
  in
    insertElements insertElems $ deleteKeys keysToDelete mp

concatMaybeMap :: Map.Map a (Maybe b) -> Map.Map a b
concatMaybeMap = Map.map fromJust . Map.filter isJust
