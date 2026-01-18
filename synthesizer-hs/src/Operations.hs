module Operations where

import Data.List (foldl')

import Synthesizer.Storable.Signal (mix)
import qualified Synthesizer.Generic.Cut as Cut (take)
import Synthesizer.Generic.Control (constant)

import SoundStream (SoundStream, sampleRateF)
import BaseStream (zeroSignal)
import Synthesizer.Generic.Signal (defaultLazySize)

repeatWithTimings :: Int -> [(Float, SoundStream)] -> SoundStream
repeatWithTimings maxLength = foldl' (repeatWithTimings' maxLength) zeroSignal

repeatWithTimings' :: Int -> SoundStream -> (Float, SoundStream) -> SoundStream
repeatWithTimings' maxLength prevStream (deltaT, newStream) =
  let delay = Cut.take (round (sampleRateF * deltaT)) $ constant defaultLazySize 0.0
  in

  mix prevStream $ delay <> Cut.take maxLength newStream
