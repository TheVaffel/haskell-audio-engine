module Utils where

import qualified Synthesizer.Generic.Signal as SigG
import qualified Synthesizer.State.Signal as SigState

applyMaybe :: Maybe (a -> a) -> a -> a
applyMaybe Nothing value = value
applyMaybe (Just f) value = f value

unzipFunctor :: Functor f => f (a, b) -> (f a, f b)
unzipFunctor ff = (fmap fst ff, fmap snd ff)

sortMaybePair :: (Maybe a, Maybe a) -> (Maybe a, Maybe a)
sortMaybePair (Nothing, nothingOrSomething) = (Nothing, nothingOrSomething)
sortMaybePair (nothingOrSomething, Nothing) = (Nothing, nothingOrSomething)
sortMaybePair pair = pair

zipWith3 :: (a -> b -> c -> d) -> (SigState.T a -> SigState.T b -> SigState.T c -> SigState.T d)
zipWith3 f s0 s1 =
   SigG.zipWith (uncurry f) (SigG.zip s0 s1)
