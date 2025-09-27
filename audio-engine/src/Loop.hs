module Loop (playWithCircularBuffer) where

import CircularBuffer (CircularBuffer, ElementType, hasContent, peekElement, extractElements)
import StreamStateStore (StreamStateStore, empty)

import Commands (updateStoreFromEvent)
import PlayInterleave (playWithInterleavedStoreUpdates)

import Data.Maybe
import Control.Monad

playWithCircularBuffer :: CircularBuffer -> IO ()
playWithCircularBuffer circularBuffer =
  playWithInterleavedStoreUpdates (updateStoreFromEventsIOAction circularBuffer)

updateStoreFromEventsIOAction :: CircularBuffer -> StreamStateStore -> IO StreamStateStore
updateStoreFromEventsIOAction circularBuffer store = do
  maybeEventElements <- getEventFromCircularBuffer circularBuffer
  pure $ case maybeEventElements of
           Just eventElements -> updateStoreFromEvent eventElements store
           _ -> store

getEventFromCircularBuffer :: CircularBuffer -> IO (Maybe [ElementType])
getEventFromCircularBuffer circularBuffer = do
  withContent <- hasContent circularBuffer
  if not withContent
    then pure Nothing
    else do
    Just eventSize <- fmap round <$> peekElement circularBuffer
    -- Remove element describing size
    sizeElement <- peekElement circularBuffer
    fmap tail <$> extractElements eventSize circularBuffer
