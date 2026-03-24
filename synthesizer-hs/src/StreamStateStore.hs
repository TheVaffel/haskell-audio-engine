module StreamStateStore (StreamStateStore, empty, insertStream, deleteStream, insertUnmanagedStream, getSoundStreamAndAdvance, markClosed, closed) where

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
import Data.Maybe (fromMaybe)

data StreamStateStore = StreamStateStore {
  streamMap :: !(Map.Map Int SoundStream), -- Map of global sounds with filtered state
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

insertStream :: Int -> SoundStream -> StreamStateStore -> StreamStateStore
insertStream index stream store =
  let maybePreviousState = streamMap store Map.!? index
  in
    case maybePreviousState of
      Just previousStream -> let
        newStream = crossFade defaultFadeSize previousStream stream -- crossFadeState defaultFadeSize previousStreamState (fromStream stream)
        in
        store { streamMap = Map.insert index newStream (streamMap store) }
      Nothing -> store { streamMap = Map.insert index stream (streamMap store) }


deleteStream :: Int -> StreamStateStore -> StreamStateStore
deleteStream index store =
  let maybePreviousStream = streamMap store Map.!? index
  in
    case maybePreviousStream of
      Nothing -> store
      Just previousStream ->
        if isEmpty previousStream then
          store { streamMap = Map.delete index (streamMap store) }
        else
          store { streamMap = Map.insert index (fadeOut defaultFadeSize previousStream) (streamMap store) }

setParameter :: (Int, ElementType, ElementType) -> StreamStateStore -> StreamStateStore
setParameter (index, value, duration) store =
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
  let indexToStreamAndNextStream = Map.map (Cut.splitAt n) (streamMap store)
      indexToParamSegmentsAndTails = Map.map (Cut.splitAt n) (parameterMap store)
      streams = map fst $ Map.elems indexToStreamAndNextStream
      nextStreamMap = Map.map snd indexToStreamAndNextStream
      (unmanagedStreamSegment, restUnmanagedStream) = Cut.splitAt n $ unmanagedStreams store
  in
    (foldl' mix unmanagedStreamSegment streams,
     store { streamMap = nextStreamMap, unmanagedStreams = restUnmanagedStream })
