module Envelope where

import qualified Synthesizer.Generic.Control as Con (line, constant)
import qualified Synthesizer.Generic.Signal as SigG (LazySize)
import qualified Synthesizer.Storable.Signal as SigSt

import SoundStream (SoundStream, ElementType, sampleRateF)
import Synthesizer.Generic.Signal (defaultLazySize)

import qualified Foreign.Storable as Foreign

line :: Int -> (ElementType, ElementType) -> SoundStream
line = Con.line defaultLazySize

scaleDown = 0.2

envelope attackT peakAmp descentT =
  line  (round $ sampleRateF * attackT) (0.0, peakAmp * scaleDown) <>
  line (round $ sampleRateF * descentT) (peakAmp * scaleDown, 1.0 * scaleDown) <>
  Con.constant defaultLazySize (1.0 * scaleDown)
