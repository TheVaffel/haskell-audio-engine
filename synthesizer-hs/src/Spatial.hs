module Spatial (distanceFactorStream) where

import SoundStream (SignalType, ElementType, GeneralSignalType)
import qualified Synthesizer.Generic.Signal as Sig
import qualified Synthesizer.Causal.Process as Causal

import Data.Tuple.Extra
import ForeignInterface (paramIndexListenerZ, paramIndexListenerY, paramIndexListenerX)
import ParameterStore (storeParameterizedStreamFromIndex3, StoreParameterizedStream, combineParameterizedSignals)
import Number.FixedPoint (fromFloat)
import Synthesizer.Generic.Fourier (Element)

maxAmplification = 3.0

listenerParams = (round paramIndexListenerX, round paramIndexListenerY, round paramIndexListenerZ) :: (Int, Int, Int)

listenerPositionParameterizedStream = storeParameterizedStreamFromIndex3 listenerParams Causal.id

distanceFactorStream :: StoreParameterizedStream (ElementType, ElementType, ElementType)  -> StoreParameterizedStream ElementType
distanceFactorStream = combineParameterizedSignals withDistance3 listenerPositionParameterizedStream

withDistance3Signal :: (GeneralSignalType sig (ElementType, ElementType, ElementType),
                  GeneralSignalType sig ElementType) => sig (ElementType, ElementType, ElementType) -> sig ElementType -> sig ElementType
withDistance3Signal = Sig.zipWith (\ds u -> u * min maxAmplification (uncurry3 distanceFactor ds))

withDistance3 :: (ElementType, ElementType, ElementType) -> (ElementType, ElementType, ElementType) -> ElementType
withDistance3 (x0, y0, z0) (x1, y1, z1) = distanceFactor (x0 - x1) (y0 - y1) (z0 - z1)

distanceFactor :: ElementType -> ElementType -> ElementType -> ElementType
distanceFactor dx dy dz = 1.0 / sqrt (dx * dx + dy * dy + dz * dz)
