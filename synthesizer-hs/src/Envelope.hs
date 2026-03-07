module Envelope where

import qualified Synthesizer.Generic.Control as Con (line, constant)
import qualified Synthesizer.Generic.Signal as SigG (LazySize)
import qualified Synthesizer.Storable.Signal as SigSt

import SoundStream (SoundStream, ElementType, sampleRateF, SignalType)
import Synthesizer.Generic.Signal (defaultLazySize)

import qualified Foreign.Storable as Foreign

line :: SignalType sig => Int -> (ElementType, ElementType) -> sig ElementType
line = Con.line defaultLazySize

scaleDown = 0.2

envelope :: SignalType sig => ElementType -> ElementType -> ElementType -> sig ElementType
envelope attackT peakAmp descentT =
  line  (round $ sampleRateF * attackT) (0.0, peakAmp * scaleDown) <>
  line (round $ sampleRateF * descentT) (peakAmp * scaleDown, 1.0 * scaleDown) <>
  Con.constant defaultLazySize (1.0 * scaleDown)
