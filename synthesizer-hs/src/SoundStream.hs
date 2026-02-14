module SoundStream where

import qualified Synthesizer.Generic.Signal as Sig
import qualified Synthesizer.Storable.Signal as SigSt
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

asStream :: Float -> SoundStream
asStream = Con.constant defaultLazySize
