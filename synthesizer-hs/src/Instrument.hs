{-# LANGUAGE FlexibleContexts #-}
module Instrument where

import SoundStream (ElementType, SoundStream, sampleRate, sampleRateF)
import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.Generic.Control as Con
import qualified Synthesizer.Generic.Oscillator as Osci
import Synthesizer.Generic.Signal (defaultLazySize)
import qualified Synthesizer.Basic.Wave as Wave
import qualified Synthesizer.Basic.Phase as Phase

import qualified Synthesizer.Generic.Filter.Recursive.Comb as Comb

import qualified Synthesizer.Plain.Filter.Recursive as FiltRec
import qualified Synthesizer.Plain.Filter.Recursive.Butterworth as Butter
import qualified Synthesizer.Plain.Modifier as Modifier

import Synthesizer.Basic.Phase (fromRepresentative)
import BaseStream (sineWave, sineWaveWithFrequency)
import Data.Foldable1 (Foldable1(toNonEmpty))
import qualified Synthesizer.Generic.Cut as Cut

import qualified Synthesizer.Plain.Filter.Recursive.Universal as UniFilter

import Envelope (envelope)

import NumericPrelude.Numeric
import NumericPrelude.Base

import Prelude ()

import qualified Algebra.Transcendental        as Trans
import qualified Algebra.RealField             as RealField
import Operations (modulate)

freqModSaw  = Osci.freqMod Wave.saw

staticSaw :: (Trans.C a, RealField.C a, SigG.Write sig a) => a -> sig a
staticSaw  = Osci.static defaultLazySize Wave.saw zero

bell :: ElementType -> SoundStream
bell frequency = let halfLife = 0.5
                     indices = [1.0, 2.0, 2.4, 3.0, 4.0]
                     streams = foldl1 SigG.mix $ map (\index -> bellHarmonic sampleRateF index halfLife frequency) indices
                     lenF = (fromIntegral . length) indices
     in Cut.take (3 * sampleRate) $ SigG.map (/ lenF) streams
bellHarmonic :: ElementType -> ElementType -> ElementType -> ElementType -> SoundStream
bellHarmonic sampleRate n halfLife freq =
    modulate (Osci.freqModSine (fromRepresentative 0)
                      (SigG.map (\modu -> freq / sampleRate * n * (1.0 + 0.005 * modu))
                        (Osci.staticSine defaultLazySize (fromRepresentative 0) (5.0 / sampleRate))))
                (Con.exponential2 defaultLazySize (halfLife/ n * sampleRate ) 1)

boing :: ElementType -> SoundStream
boing frequency = let
  degrade = Con.exponential2 defaultLazySize (0.5 * sampleRateF) 1.0 :: SoundStream
  freqModulatingSine = {- modulate degrade $ -} Con.constant defaultLazySize (frequency / sampleRateF) {- SigG.map (\perturbation -> 0.1 {- perturbation * 0.05 + frequency -} ) $
    Osci.staticSine defaultLazySize (fromRepresentative 0) (8.0 / sampleRateF) -}
  ampModulatingSine = staticSaw (2.1233 / sampleRateF) :: SoundStream
  baseWave = envelope 0.05 5.0 0.05 `modulate` freqModSaw zero freqModulatingSine
  combIt = Comb.run (round (0.12 * sampleRateF)) (0.4 :: Float)
  in
    degrade `modulate` combIt baseWave -- `modulate` ampModulatingSine

alert :: Float -> SoundStream
alert frequency = let sqWave = Osci.static defaultLazySize Wave.square zero (frequency / sampleRateF)
                  in
                    sqWave
