module PlayInterleave (playWithInterleavedStoreUpdates) where

import SoundStream (SoundStream, sampleRate, interactiveBufferSize)

import Utils (applyMaybe)
import StreamStateStore (StreamStateStore, empty, getSoundStreamAndAdvance)

import qualified Sound.Sox.Play as Play

import qualified Sound.Sox.Option.Format as SoxOpt
import qualified Synthesizer.Basic.Binary as BinSmp


import qualified Synthesizer.Generic.Signal as SigG

import Synthesizer.Storable.Signal (mix, mixSize, mixSndPattern, defaultChunkSize)

import qualified Synthesizer.Generic.Cut as Cut (splitAt, lengthAtLeast, take)
import NumericPrelude.Base ( IO, (.), putStrLn, Functor (fmap), Maybe)

import qualified Synthesizer.ALSA.Storable.Play as AlsaPlay
import qualified Sound.ALSA.PCM as Alsa

import Control.Monad (when)

ioInterleave :: (SoundStream -> IO ()) -> (StreamStateStore -> IO StreamStateStore) -> StreamStateStore -> IO ()
ioInterleave handler updateStore store  = do
  -- additionalOutput <- io
  updatedStore <- updateStore store
  let (signalFromStore, advancedStore) = getSoundStreamAndAdvance interactiveBufferSize updatedStore -- Cut.take interactiveBufferSize (getSoundStream newStore)
  -- let (immediateOutputSignal, restSignal) = Cut.splitAt interactiveBufferSize mixedSignal
  handler signalFromStore
  ioInterleave handler updateStore advancedStore

{- playInterleave :: IO (Maybe SoundStream) -> SoundStream -> IO ExitCode
playInterleave io =
  Play.simple ioAndHput SoxOpt.none sampleRate
  where ioAndHput handle = ioInterleave (SigSt.hPut handle) io -}

{-
Play a sound stream interleaved with IO actions at a pre-defined interval
-}
playWithInterleavedStoreUpdates :: (StreamStateStore -> IO StreamStateStore) -> IO ()
playWithInterleavedStoreUpdates updateStore = do
  Alsa.withSoundSink sink ioAndPut
  where
    initialStore = empty
    sink = AlsaPlay.makeSink AlsaPlay.defaultDevice (0.02::Float) sampleRate
    ioAndPut handle = ioInterleave (AlsaPlay.writeLazy sink handle) updateStore initialStore

{- play :: SoundStream -> IO ()
play = fmap void $ Play.simple SigSt.hPut SoxOpt.none sampleRate


playAlsa :: SoundStream -> IO ()
playAlsa stream = do
  let sink = AlsaPlay.makeSink AlsaPlay.defaultDevice (0.02::Float) sampleRate
  AlsaPlay.auto sink stream -}
