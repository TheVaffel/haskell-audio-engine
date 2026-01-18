module Commands (updateStoreFromEvent) where

import CircularBuffer (ElementType)
import SoundStream (SoundStream, sampleRate, sampleRateF)
import StreamStateStore (StreamStateStore, insertStream, deleteStream, insertUnmanagedStream, markClosed)
import BaseStream (sineWave, sineWaveWithFrequency, zeroSignal, noise)

import qualified Synthesizer.Generic.Cut as Cut (take)
import qualified Synthesizer.Generic.Filter.NonRecursive as Filt (envelope)
import qualified Synthesizer.Generic.Control as Con (line, constant)
import qualified Synthesizer.Generic.Signal as Sig (map, mix, zipWith)

import qualified Envelope as Env (envelope)

import Instrument (bell, boing, staticSaw)
import Filter (lowPassFilter)

import Data.Maybe

import Debug.Trace (trace)
import qualified Data.Map as Map
import Synthesizer.Generic.Signal (defaultLazySize)

insertAtIndex = 2
insertAndForget = 3
stopAtIndex = 4
exit = 5

sineGenerator = 1000
sineFrequency = 1001
modulateOp = 1002
mixOp = 1003
envelope = 1004
volumeMarker = 1005
bellMarker = 2001
customMarker = 2002

data StreamCommand = InsertStreamAtIndex !Int !GeneratorCommand
                   | DeleteStreamAtIndex !Int
                   | InsertAndForget !GeneratorCommand
                   | Exit
                   deriving Show

data GeneratorCommand = SineWave
                      | SineWaveWithFrequency !ElementType
                      | Modulate !GeneratorCommand !GeneratorCommand
                      | Mix !GeneratorCommand !GeneratorCommand
                      | Envelope !ElementType !ElementType !ElementType
                      | Volume !ElementType !GeneratorCommand
                      | Custom !ElementType
                      | Bell !ElementType
                      | NoGenerator deriving Show

eventGeneratorMap = Map.fromList [(insertAtIndex, \(index:restArgs) -> InsertStreamAtIndex (round index) $ createGeneratorCommandFromInput restArgs),
                                  (insertAndForget, InsertAndForget . createGeneratorCommandFromInput),
                                  (stopAtIndex, DeleteStreamAtIndex . round . head),
                                  (exit, const Exit)
                                  ]

generatorCommandMap = Map.fromList [(sineGenerator, (,) SineWave),
                                    (sineFrequency, \(f:rest) -> (SineWaveWithFrequency f, rest)),
                                     (modulateOp, parseBinaryOperation Modulate),
                                     (mixOp, parseBinaryOperation Mix),
                                     (envelope, \(attackT:peakAmp:descentT:rest) -> (Envelope attackT peakAmp descentT, rest)),
                                     (volumeMarker, \(f:commandOp:r0) ->
                                         let (command, rest) = (generatorCommandMap Map.! round commandOp) r0 in
                                           (Volume f command, rest)),
                                     (bellMarker, \(f:rest) -> (Bell f, rest)),
                                     (customMarker, \(f:rest) -> (Custom f, rest))
                                   ] :: Map.Map Int ([ElementType] -> (GeneratorCommand, [ElementType]))

parseBinaryOperation :: (GeneratorCommand -> GeneratorCommand -> GeneratorCommand) -> [ElementType] -> (GeneratorCommand, [ElementType])
parseBinaryOperation op (id0:r0) = let (gen0, id1:r1) = (generatorCommandMap Map.! round id0) r0
                                       (gen1, r2) = (generatorCommandMap Map.! round id1) r1
  in (op gen0 gen1, r2)

updateStoreFromEvent :: [ElementType] -> StreamStateStore -> StreamStateStore
updateStoreFromEvent eventElements = maybe id updateStoreFromCommand command
  where
  command = createCommandFromEventElements eventElements

createCommandFromEventElements :: [ElementType] -> Maybe StreamCommand
createCommandFromEventElements (eventTypeF:arguments) =
  let eventType = round eventTypeF
      generator = eventGeneratorMap Map.!? eventType

  in
     generator <*> Just arguments

createGeneratorCommandFromInput :: [ElementType] -> GeneratorCommand
createGeneratorCommandFromInput (commandTypeF:restArgs) =
  let commandType = round commandTypeF
      maybeGeneratorFunction = generatorCommandMap Map.!? commandType
      maybeGenerator = maybeGeneratorFunction <*> Just restArgs
  in
    maybe NoGenerator fst maybeGenerator

createStreamFromGeneratorCommand generatorCommand =
  case generatorCommand of
    SineWave -> Cut.take (3 * sampleRate) sineWave
    SineWaveWithFrequency freq -> sineWaveWithFrequency freq
    Mix gen0 gen1 -> Sig.mix (createStreamFromGeneratorCommand gen0) (createStreamFromGeneratorCommand gen1)
    Modulate gen0 gen1 -> Filt.envelope (createStreamFromGeneratorCommand gen0)  (createStreamFromGeneratorCommand gen1)
    Envelope attackT peakAmp descentT -> Env.envelope attackT peakAmp descentT
    Volume volume gen0 -> Sig.zipWith (*) (Con.constant defaultLazySize volume) (createStreamFromGeneratorCommand gen0)
    Bell frequency -> bell frequency
    Custom frequency -> Sig.map (*0.2) $ lowPassFilter frequency noise
    NoGenerator -> zeroSignal

updateStoreFromCommand :: StreamCommand -> StreamStateStore -> StreamStateStore
updateStoreFromCommand command store =
  case command of
    InsertStreamAtIndex index generatorCommand -> trace ("Inserting stream at index " ++ show index) $ insertStream index stream store
      where
        stream = createStreamFromGeneratorCommand generatorCommand
    DeleteStreamAtIndex index -> deleteStream index store
    InsertAndForget generatorCommand -> insertUnmanagedStream (Cut.take (10 * sampleRate) stream) store
      where
        stream = createStreamFromGeneratorCommand generatorCommand
    Exit -> markClosed store
