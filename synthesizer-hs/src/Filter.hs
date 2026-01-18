module Filter where
import SoundStream (SoundStream, sampleRateF)
import Synthesizer.Generic.Signal (defaultLazySize)

import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.Generic.Control as Con
import qualified Synthesizer.Plain.Filter.Recursive as FiltRec

import qualified Synthesizer.Plain.Filter.Recursive.Universal as UniFilter

lowPassFilter :: Float -> SoundStream -> SoundStream
lowPassFilter frequency = SigG.map UniFilter.bandpass . uniFilter 30.0 frequency

highPassFilter :: Float -> SoundStream -> SoundStream
highPassFilter frequency = SigG.map UniFilter.highpass . uniFilter 10.0 frequency

uniFilter :: Float -> Float -> SoundStream -> SigSt.T (UniFilter.Result Float)
-- uniFilter :: Float -> Float -> SoundStream -> SoundStream
uniFilter pole frequency  =
  let poleSpec = FiltRec.Pole pole (frequency / sampleRateF)
      parameter = UniFilter.parameter poleSpec
      parameterStream = Con.constant defaultLazySize parameter
      resultStreamFunc = SigG.modifyModulated UniFilter.modifier parameterStream
  in
    resultStreamFunc
