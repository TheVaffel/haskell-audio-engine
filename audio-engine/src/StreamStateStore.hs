module StreamStateStore (StreamStateStore, empty, insertStream, deleteStream, insertUnmanagedStream, getSoundStreamAndAdvance) where

import StreamState (StreamState, defaultFadeSize, fromStream, crossFadeState, fadeOutState, isEmpty, advance)

import Synthesizer.Storable.Signal (mix)

import SoundStream (SoundStream)
import RawStream (zeroSignal)

import qualified Data.Map as Map
import Data.Foldable (Foldable(foldl))

import Synthesizer.Generic.Cut as Cut (splitAt, take)

import Debug.Trace

data StreamStateStore = StreamStateStore {
  streamMap :: Map.Map Int StreamState, -- Map of global sounds with filtered state
  unmanagedStreams :: SoundStream -- Map of a stream with "unmanaged" sound streams.
    -- These should not last longer than at most 10 seconds.
    -- Does not require further follow-up from controller
  }

empty :: StreamStateStore
empty = StreamStateStore { streamMap = Map.empty, unmanagedStreams = zeroSignal }

insertStream :: Int -> SoundStream -> StreamStateStore -> StreamStateStore
insertStream index stream store =
  let maybePreviousState = streamMap store Map.!? index
  in
    case maybePreviousState of
      Just previousStreamState -> let
        newStreamState = crossFadeState defaultFadeSize previousStreamState (fromStream stream)
        in
        trace "Cross-fading with previous signal and index" $ store { streamMap = Map.insert index newStreamState (streamMap store) }
      Nothing -> store { streamMap = Map.insert index (fromStream stream) (streamMap store) }


deleteStream :: Int -> StreamStateStore -> StreamStateStore
deleteStream index store =
  let maybePreviousStream = streamMap store Map.!? index
  in
    case maybePreviousStream of
      Nothing -> store
      Just previousStreamState ->
        if isEmpty previousStreamState then
          trace ("Trashing state now") $ store { streamMap = Map.delete index (streamMap store) }
        else
          trace ("Fading out state now with fade size " ++ show defaultFadeSize) $ store { streamMap = Map.insert index (fadeOutState defaultFadeSize previousStreamState) (streamMap store) }

insertUnmanagedStream :: SoundStream -> StreamStateStore -> StreamStateStore
insertUnmanagedStream stream store = store { unmanagedStreams = unmanagedStreams store `mix` stream }

getSoundStreamAndAdvance :: Int -> StreamStateStore -> (SoundStream, StreamStateStore)
getSoundStreamAndAdvance n store =
  let indexToStreamAndNextState = Map.map (advance n) (streamMap store)
      streams = map fst $ Map.elems indexToStreamAndNextState
      nextStreamMap = Map.map snd indexToStreamAndNextState
      (unmanagedStreamSegment, restUnmanagedStream) = Cut.splitAt n $ unmanagedStreams store
  in
    (foldl mix unmanagedStreamSegment streams,
     store { streamMap = nextStreamMap, unmanagedStreams = restUnmanagedStream })
