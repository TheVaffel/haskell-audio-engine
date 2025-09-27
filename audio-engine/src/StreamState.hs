module StreamState (StreamState
                   , getCurrentStream
                   , getOriginalStream
                   , defaultFadeSize
                   , fromStream
                   , advance
                   , isEmpty
                   , fadeOutState
                   , crossFadeState) where

import SoundStream (SoundStream, sampleRate, fadeOut, crossFade)

import qualified Synthesizer.Generic.Cut as Cut
import Synthesizer.Generic.Signal (defaultLazySize)

{-
  A StreamState represents a sound coming from a specific source, but modified and perceived differently at the
destination. For instance, a sound originating from a particular point in a space, while the destination is
hidden behind some construction, or far away.

The structure contains a pair of sound streams, one "original" and one "current". The "original" represents the sound at the source, while the "current" is the sound at the receiving destination. Keeping track of both makes it easy
to apply and unapply effects on the stream.
-}
data StreamState = StreamState { originalStream :: SoundStream, currentStream :: SoundStream }

defaultFadeSize = round (0.01 * fromIntegral sampleRate) :: Int

getCurrentStream :: StreamState -> SoundStream
getCurrentStream = currentStream

getOriginalStream :: StreamState -> SoundStream
getOriginalStream = originalStream

fromOriginalAndCurrentStream :: SoundStream -> SoundStream -> StreamState
fromOriginalAndCurrentStream original current = StreamState { originalStream = original, currentStream = current }

fromStream :: SoundStream -> StreamState
fromStream stream = StreamState { originalStream = stream, currentStream = stream }

advance :: Int -> StreamState -> (SoundStream, StreamState)
advance n streamState =
  let restOriginal = Cut.drop n $ getOriginalStream streamState
      (headCurrent, restCurrent) = Cut.splitAt n $ getCurrentStream streamState
  in
    (headCurrent, StreamState { originalStream = restOriginal, currentStream = restCurrent })

fadeOutState :: Int -> StreamState -> StreamState
fadeOutState n streamState =
  let endOriginal = fadeOut n $ getCurrentStream streamState
      endCurrent = fadeOut n $ getOriginalStream streamState
  in
    StreamState { originalStream = endOriginal, currentStream = endCurrent }

crossFadeState :: Int -> StreamState -> StreamState -> StreamState
crossFadeState n initialState newState =
  let crossOriginal = crossFade n (getOriginalStream initialState) (getOriginalStream newState)
      crossCurrent = crossFade n (getCurrentStream initialState) (getCurrentStream newState)
  in
    StreamState { originalStream = crossOriginal, currentStream = crossCurrent }

isEmpty :: StreamState -> Bool
isEmpty = not . Cut.lengthAtLeast 1 . getOriginalStream
