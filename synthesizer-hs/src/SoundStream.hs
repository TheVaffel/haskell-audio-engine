module SoundStream where

import qualified Synthesizer.Generic.Signal as Sig
import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.Generic.Filter.NonRecursive as Filt
import qualified Synthesizer.Generic.Control as Con
import Synthesizer.Generic.Signal (defaultLazySize)
import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Generic.Cut as Cut

type ElementType = Float
type SoundStream = SigSt.T ElementType

sampleRate = 44100 :: Int

sampleRateF = fromIntegral sampleRate :: Float

interactiveBufferSize :: Int
interactiveBufferSize = 256

interactiveLazySize :: SigG.LazySize
interactiveLazySize = SigG.LazySize interactiveBufferSize

modulate :: SoundStream -> SoundStream -> SoundStream
modulate = SigG.zipWith (*)

fadeOut :: Int -> SoundStream -> SoundStream
fadeOut n stream =
  let envelope = Con.line defaultLazySize n (1.0, 0.0)
  in
    Filt.envelope envelope stream

fadeIn :: Int -> SoundStream -> SoundStream
fadeIn n stream =
  let envelope = Con.line defaultLazySize n (0.0, 1.0) <> Con.constant defaultLazySize 1.0
  in
    Filt.envelope envelope stream

crossFade :: Int -> SoundStream -> SoundStream -> SoundStream
crossFade n initial end =
  let initialFadeOut = fadeOut n initial
      endFadeIn = fadeIn n end
  in
    Sig.mix initialFadeOut endFadeIn
