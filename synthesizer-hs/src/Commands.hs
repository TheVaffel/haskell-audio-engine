module Commands (updateStoreFromEvent) where

import SoundStream (SoundStream, sampleRate, sampleRateF, SignalType, ElementType)
import StreamStateStore (StreamStateStore, insertStream, deleteStream, insertUnmanagedStream, markClosed, setParameter)
import BaseStream (sineWave, sineWaveWithFrequency, zeroSignal, noise, lfo)

import qualified Synthesizer.Generic.Cut as Cut (take)
import qualified Synthesizer.Generic.Filter.NonRecursive as Filt (envelope)
import qualified Synthesizer.Generic.Control as Con (line, constant)
import qualified Synthesizer.Generic.Signal as Sig (fromState, map, mix, zipWith)
import qualified Synthesizer.State.Signal as SigState

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
                     ExternalParameter, Bell, Custom, Custom2),
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
      custom2Marker, envelopeMarker, setExternalParameterMarker, externalParameterMarker )

import Design.Alarm (cosc, cosFadingStreams, cyclingSounds, fullAlarm, alarmHappyBlips, alarmAffirmative, alarmActivate, alarmInvaders, alarmInformation, alarmMessage, alarmFinished, alarmError, alarmBuzzer, alarmBuzzer2, alarmCustom)
import Design.Police (exponentialOscillator, exponentialFreq, fullSiren, semiFullSiren)
import Synthesizer.Storable.Signal (defaultChunkSize)
import ParameterStore (StoreParameterizedStream, unparameterizedStream, storeParameterizedStreamFromIndex, mapStoreParameterized, getStreamFromParamStore, composeParameterizedStream, combineParameterizedSignals)
import Synthesizer.State.Signal (toStorableSignal)
import Parameterized (freqParamSine, ParameterizedStream)
import qualified Synthesizer.Causal.Process as Causal

eventGeneratorMap = Map.fromList [(insertAtIndexMarker, \(index:restArgs) -> InsertAtIndex (round index) $ createAudioCommandFromInput restArgs),
                                  (insertAndForgetMarker, InsertAndForget . createAudioCommandFromInput),
                                  (stopAtIndexMarker, StopAtIndex . round . head),
                                  (setExternalParameterMarker, \(index:value:duration:rest) -> SetExternalParameter (round index) value duration),
                                  (exitMarker, const Exit)
                                  ]

generatorCommandMap :: Map.Map Int ([ElementType] -> (AudioGenerator, [ElementType]))
generatorCommandMap = Map.fromList [(sineGeneratorMarker, parseUnaryOperation SineGenerator ),
                                    (sineGeneratorWithFrequencyMarker, \(f:rest) -> (SineGeneratorWithFrequency f, rest)),
                                     (modulateOpMarker, parseBinaryOperation ModulateOp),
                                     (mixOpMarker, parseBinaryOperation MixOp),
                                     (envelopeMarker, \(attackT:peakAmp:descentT:rest) -> (Envelope attackT peakAmp descentT, rest)),
                                     (volumeMarker, \(f:rest) -> parseUnaryOperation (Volume f) rest),
                                     (bellMarker, \(f:rest) -> (Bell f, rest)),
                                     (externalParameterMarker, \(f:rest) -> (ExternalParameter $ round f, rest)),
                                     (customMarker, \(f:rest) -> (Custom f, rest)),
                                     (custom2Marker, \(f:rest) -> (Custom2 f, rest))
                                   ] :: Map.Map Int ([ElementType] -> (AudioGenerator, [ElementType]))

parseUnaryOperation :: (AudioGenerator -> AudioGenerator) -> [ElementType] -> (AudioGenerator, [ElementType])
parseUnaryOperation op (id0:r0) = let (gen0, rest) = (generatorCommandMap Map.! round id0) r0
                                  in
                                    (op gen0, rest)

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

createStreamFromAudioCommand :: AudioGenerator -> StoreParameterizedStream ElementType -- sig ElementType
createStreamFromAudioCommand generatorCommand =
  case generatorCommand of
    -- SineGenerator _ -> Cut.take (3 * sampleRate) sineWave
    SineGenerator gen0 -> composeParameterizedStream (fmap (*0.1) freqParamSine) (createStreamFromAudioCommand gen0)
    SineGeneratorWithFrequency freq -> unparameterizedStream $  (sineWaveWithFrequency freq :: SigState.T ElementType)
    MixOp gen0 gen1 -> combineParameterizedSignals (+) (createStreamFromAudioCommand gen0) (createStreamFromAudioCommand gen1)
    ModulateOp gen0 gen1 -> combineParameterizedSignals (*) (createStreamFromAudioCommand gen0)  (createStreamFromAudioCommand gen1)
    Envelope attackT peakAmp descentT -> unparameterizedStream $ (Env.envelope attackT peakAmp descentT :: SigState.T ElementType)
    Volume volume gen0 -> mapStoreParameterized (* volume) $ createStreamFromAudioCommand gen0
    Bell frequency -> unparameterizedStream $ (bell frequency :: SigState.T ElementType)
    -- Custom frequency -> Sig.map (*0.2) $ cosFadingStreams (map sineWaveWithFrequency [frequency, frequency * 1.4, frequency * 1.8])
    Custom _ -> unparameterizedStream $ Sig.map (*0.1) (semiFullSiren 0)
    -- Custom2 frequency -> Sig.map (*0.2) cyclingSounds
    -- Custom frequency -> Sig.map (*0.2) $ cosc frequency 0.0
    -- Custom2 frequency -> Sig.map (*0.2) $ cosc frequency 0.2
    -- Custom2 frequency -> fullAlarm alarmCustom
    -- Custom2 frequency -> Sig.map (*0.1) $ exponentialFreq 2.0
    Custom2 _ -> unparameterizedStream $ Sig.map (*0.1) (fullSiren 0)
    ExternalParameter ind -> storeParameterizedStreamFromIndex ind Causal.id
    NoGenerator -> unparameterizedStream (zeroSignal :: SigState.T ElementType)

{- getParameterizedStream :: ParameterizedStream ElementType ElementType -> AudioGenerator -> StoreParameterizedStream
getParameterizedStream paramStream (ExternalParameter ind) = storeParameterizedStreamFromIndex ind paramStream
getParameterizedStream paramStream otherGenerator = let innerStreamGenerator = createStreamFromAudioCommand otherGenerator -}


custom :: SignalType sig => ElementType -> sig ElementType
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
    InsertAndForget generatorCommand -> insertUnmanagedStream (Cut.take (10 * sampleRate) $ getStreamFromParamStore Map.empty stream) store
      where
        stream = createStreamFromAudioCommand generatorCommand
    SetExternalParameter index value duration  -> setParameter (index, value, duration) store
    Exit -> markClosed store
