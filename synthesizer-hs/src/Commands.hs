module Commands (updateStoreFromEvent) where

import CircularBuffer (ElementType)
import SoundStream (SoundStream, sampleRate, sampleRateF)
import StreamStateStore (StreamStateStore, insertStream, deleteStream, insertUnmanagedStream, markClosed)
import BaseStream (sineWave, sineWaveWithFrequency, zeroSignal, noise, lfo)

import qualified Synthesizer.Generic.Cut as Cut (take)
import qualified Synthesizer.Generic.Filter.NonRecursive as Filt (envelope)
import qualified Synthesizer.Generic.Control as Con (line, constant)
import qualified Synthesizer.Generic.Signal as Sig (map, mix, zipWith)

import qualified Envelope as Env (envelope)

import Instrument (bell, boing, staticSaw)
import Filter (lowPassFilter)
import Operations (cycleSounds, modulate)

import Data.Maybe

import Debug.Trace (trace)
import qualified Data.Map as Map
import Synthesizer.Generic.Signal (defaultLazySize)

import ForeignInterface
    ( AudioGenerator(NoGenerator, SineGenerator,
                     SineGeneratorWithFrequency, MixOp, ModulateOp, Envelope, Volume,
                     Bell, Custom, Custom2),
      AudioCommand(..),
      insertAtIndexMarker,
      insertAndForgetMarker,
      stopAtIndexMarker,
      exitMarker,
      sineGeneratorMarker,
      sineGeneratorWithFrequencyMarker,
      modulateOpMarker,
      mixOpMarker,
      volumeMarker,
      bellMarker,
      customMarker,
      custom2Marker, envelopeMarker )

import Design.Alarm (cosc, cosFadingStreams, cyclingSounds, fullAlarm, alarmHappyBlips, alarmAffirmative, alarmActivate, alarmInvaders, alarmInformation, alarmMessage, alarmFinished, alarmError, alarmBuzzer, alarmBuzzer2, alarmCustom)


eventGeneratorMap = Map.fromList [(insertAtIndexMarker, \(index:restArgs) -> InsertAtIndex (round index) $ createAudioCommandFromInput restArgs),
                                  (insertAndForgetMarker, InsertAndForget . createAudioCommandFromInput),
                                  (stopAtIndexMarker, StopAtIndex . round . head),
                                  (exitMarker, const Exit)
                                  ]

generatorCommandMap :: Map.Map Int ([ElementType] -> (AudioGenerator, [ElementType]))
generatorCommandMap = Map.fromList [(sineGeneratorMarker, (,) SineGenerator),
                                    (sineGeneratorWithFrequencyMarker, \(f:rest) -> (SineGeneratorWithFrequency f, rest)),
                                     (modulateOpMarker, parseBinaryOperation ModulateOp),
                                     (mixOpMarker, parseBinaryOperation MixOp),
                                     (envelopeMarker, \(attackT:peakAmp:descentT:rest) -> (Envelope attackT peakAmp descentT, rest)),
                                     (volumeMarker, \(f:commandOp:r0) ->
                                         let (command, rest) = (generatorCommandMap Map.! round commandOp) r0 in
                                           (Volume f command, rest)),
                                     (bellMarker, \(f:rest) -> (Bell f, rest)),
                                     (customMarker, \(f:rest) -> (Custom f, rest)),
                                     (custom2Marker, \(f:rest) -> (Custom2 f, rest))
                                   ] :: Map.Map Int ([ElementType] -> (AudioGenerator, [ElementType]))

parseBinaryOperation :: (AudioGenerator -> AudioGenerator -> AudioGenerator) -> [ElementType] -> (AudioGenerator, [ElementType])
parseBinaryOperation op (id0:r0) = let (gen0, id1:r1) = (generatorCommandMap Map.! round id0) r0
                                       (gen1, r2) = (generatorCommandMap Map.! round id1) r1
  in (op gen0 gen1, r2)

updateStoreFromEvent :: [ElementType] -> StreamStateStore -> StreamStateStore
updateStoreFromEvent eventElements = maybe id updateStoreFromCommand command
  where
  command = createCommandFromEventElements eventElements

createCommandFromEventElements :: [ElementType] -> Maybe AudioCommand
createCommandFromEventElements (eventTypeF:arguments) =
  let eventType = round eventTypeF
      generator = eventGeneratorMap Map.!? eventType

  in
     generator <*> Just arguments

createAudioCommandFromInput :: [ElementType] -> AudioGenerator
createAudioCommandFromInput (commandTypeF:restArgs) =
  let commandType = round commandTypeF
      maybeGeneratorFunction = generatorCommandMap Map.!? commandType
      maybeGenerator = maybeGeneratorFunction <*> Just restArgs
  in
    maybe NoGenerator fst maybeGenerator

createStreamFromAudioCommand generatorCommand =
  case generatorCommand of
    SineGenerator -> Cut.take (3 * sampleRate) sineWave
    SineGeneratorWithFrequency freq -> sineWaveWithFrequency freq
    MixOp gen0 gen1 -> Sig.mix (createStreamFromAudioCommand gen0) (createStreamFromAudioCommand gen1)
    ModulateOp gen0 gen1 -> Filt.envelope (createStreamFromAudioCommand gen0)  (createStreamFromAudioCommand gen1)
    Envelope attackT peakAmp descentT -> Env.envelope attackT peakAmp descentT
    Volume volume gen0 -> Sig.zipWith (*) (Con.constant defaultLazySize volume) (createStreamFromAudioCommand gen0)
    Bell frequency -> bell frequency
    Custom frequency -> Sig.map (*0.2) $ cosFadingStreams (map sineWaveWithFrequency [frequency, frequency * 1.4, frequency * 1.8])
    -- Custom2 frequency -> Sig.map (*0.2) cyclingSounds
    -- Custom frequency -> Sig.map (*0.2) $ cosc frequency 0.0
    -- Custom2 frequency -> Sig.map (*0.2) $ cosc frequency 0.2
    Custom2 frequency -> fullAlarm alarmCustom
    NoGenerator -> zeroSignal

custom frequency = let lf = lfo 2
                       invLf = Sig.map (1.0 -) lf
                   in
                     Sig.mix (modulate (sineWaveWithFrequency 800) lf) (modulate (sineWaveWithFrequency 600) invLf)


updateStoreFromCommand :: AudioCommand -> StreamStateStore -> StreamStateStore
updateStoreFromCommand command store =
  case command of
    InsertAtIndex index generatorCommand -> trace ("Inserting stream at index " ++ show index) $ insertStream index stream store
      where
        stream = createStreamFromAudioCommand generatorCommand
    StopAtIndex index -> deleteStream index store
    InsertAndForget generatorCommand -> insertUnmanagedStream (Cut.take (10 * sampleRate) stream) store
      where
        stream = createStreamFromAudioCommand generatorCommand
    Exit -> markClosed store
