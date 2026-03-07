module Filter where
import SoundStream (SoundStream, sampleRateF, ElementType, SignalType)
import Synthesizer.Generic.Signal (defaultLazySize)

import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.Storable.Signal as SigSt
import qualified Synthesizer.Generic.Control as Con
import qualified Synthesizer.Plain.Filter.Recursive as FiltRec

import qualified Synthesizer.Plain.Filter.Recursive.Universal as UniFilter

lowPassFilter :: SignalType sig => ElementType -> sig ElementType -> sig ElementType
lowPassFilter frequency = SigG.map UniFilter.lowpass . uniFilter 1.0 frequency

highPassFilter :: SignalType sig => Float -> sig ElementType -> sig ElementType
highPassFilter frequency = SigG.map UniFilter.highpass . uniFilter 10.0 frequency

bandPassFilter :: SignalType sig => Float -> Float -> sig ElementType -> sig ElementType
bandPassFilter pole frequency = SigG.map UniFilter.bandpass . uniFilter pole frequency

uniFilter :: SignalType sig => Float -> Float -> sig ElementType -> sig (UniFilter.Result ElementType)
uniFilter pole frequency  =
  let poleSpec = FiltRec.Pole pole (frequency / sampleRateF)
      parameter = UniFilter.parameter poleSpec
      parameterStream = Con.constant defaultLazySize parameter
      resultStreamFunc = SigG.modifyModulated UniFilter.modifier parameterStream
  in
    resultStreamFunc
