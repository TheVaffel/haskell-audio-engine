module Design.Alarm where

import SoundStream (SoundStream, sampleRateF, sampleRate)

import qualified Synthesizer.Generic.Oscillator as Osci
import qualified Synthesizer.Basic.Wave as Wave

import NumericPrelude.Numeric (zero)
import Synthesizer.Generic.Signal (defaultLazySize)

import Data.Ord
import qualified Synthesizer.Generic.Signal as SigG
import BaseStream (sineWaveWithFrequency, phasor)
import Operations (cycleSounds, modulate)
import Data.List (foldl1')
import Data.Tuple.Extra
import Synthesizer.Utility (fwrap)
import qualified Synthesizer.Generic.Control as Con
import Filter (highPassFilter)


-- | the cosc function from `Designing Sound by Andy Farnell`
-- It is essentially an oscillator whose phase is controlled by another oscillator
-- arg0: the frequency of the inner oscillation
-- arg1: the phase shift of the inner oscillation
-- i.e. a value of 0 gives sin(sin(wt)), a value of 1 gives cos(sin(wt))
cosc :: Float -> Float -> SoundStream
cosc frequency spectrum = let osc = Osci.static defaultLazySize Wave.sine zero (frequency / sampleRateF)

                          in
                            SigG.map (\x -> cos ((0.25 * spectrum + x) * 2 * pi)) osc

cosByPhase :: SoundStream -> SoundStream
cosByPhase inp = let wave = Osci.phaseMod Wave.cosine zero inp
  in
  wave

cyclingSounds = let sounds = [sineWaveWithFrequency 723
                             , sineWaveWithFrequency 932
                             , sineWaveWithFrequency 1012]
            in
              cycleSounds 1.0 sounds

-- | Returns a list of streams, each of which is a
-- repeated half-sine-period, with a pause in-between
-- only one stream will be non-zero at a time, making this
-- applicable for smooth sequencing of sounds
-- arg0: the number of streams to generate
-- arg1: the driver signal - in the base case a constantly rising line.
-- Its incline (multiplied by sample rate) indicates time per half-sine-period
cosFaderStreams :: Int -> SoundStream -> [SoundStream]
cosFaderStreams n driveSignal = let
  bigPhasor = SigG.map ((* fromIntegral n) . fwrap (0.0, 1.0)) driveSignal
  clampBands = map (\p -> (p, p + 1)) [0..n]
  phaseParts = map (\band -> SigG.map (\s -> clamp (both fromIntegral band) s * 0.5 - 0.25) bigPhasor) clampBands
  in
    map cosByPhase phaseParts

cosFadingStreams :: [SoundStream] -> SoundStream
cosFadingStreams streams = let
  driver = Con.linear defaultLazySize (0.7  / sampleRateF) 0.0
  cosFaders = cosFaderStreams (length streams) driver
  cosModulated = zipWith modulate streams cosFaders
  in
    foldl1' SigG.mix cosModulated

-- | A rising line that stops
-- arg0: time to rise to `scale` (in seconds)
-- arg1: scale
timeBase :: Float -> Float -> SoundStream
timeBase time scale = Con.line defaultLazySize (round (sampleRateF * time)) (0, scale)

type FullAlarmParams = ((Float, Float), (Float, Float, Float, Float), Float)

-- | From Designing sound, p. 352
-- duration and time scale: the duration of the ordeal in milliseconds (!),
-- and the number of repetitions
-- freqX; The base frequencies of the Cos waves
-- spectrum: The timbre/spectre of the Cos waves
fullAlarm :: FullAlarmParams -> SoundStream
fullAlarm ((duration, timeScale), (freq0, freq1, freq2, freq3), spectrum) =
  let coses = map (`cosc` spectrum) [freq0, freq1, freq2, freq3]
      control = timeBase (duration / 1000.0) timeScale
      cosHats = cosFaderStreams 4 control
      sum = foldl1' SigG.mix (zipWith modulate coses cosHats)
  in
    SigG.map (*0.2) $ highPassFilter 50.0 sum

-- ArgSets:
alarmHappyBlips = ((380.0, 2.0), (349.0, 0.0, 0.0, 0.0), 1.0) :: FullAlarmParams
alarmAffirmative = ((238, 1.0), (317, 0.0, 0.0, 476), 0.0) :: FullAlarmParams
alarmActivate = ((317, 7), (300, 125, 0, 0), 1) :: FullAlarmParams
alarmInvaders = ((1031, 9), (360, 238, 174, 158), 1) :: FullAlarmParams
alarmInformation = ((900, 4), (2000, 2010, 2000, 2010), 1) :: FullAlarmParams
alarmMessage = ((1428, 3), (619, 571, 365, 206), 1) :: FullAlarmParams
alarmFinished = ((450, 1), (365, 571, 619, 206), 0.5) :: FullAlarmParams
alarmError = ((714, 74), (1000, 0, 1000, 0), 0) :: FullAlarmParams
alarmBuzzer = ((200, 30), (1000, 476, 159, 0), 1) :: FullAlarmParams
alarmBuzzer2 = ((634, 61), (1000, 476, 159, 0), 1) :: FullAlarmParams
alarmCustom = ((400, 1), (220, 290, 390, 320), 0) :: FullAlarmParams
