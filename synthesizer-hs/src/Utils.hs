module Utils where

applyMaybe :: Maybe (a -> a) -> a -> a
applyMaybe Nothing value = value
applyMaybe (Just f) value = f value

unzipFunctor :: Functor f => f (a, b) -> (f a, f b)
unzipFunctor ff = (fmap fst ff, fmap snd ff)

sortMaybePair :: (Maybe a, Maybe a) -> (Maybe a, Maybe a)
sortMaybePair (Nothing, nothingOrSomething) = (Nothing, nothingOrSomething)
sortMaybePair (nothingOrSomething, Nothing) = (Nothing, nothingOrSomething)
sortMaybePair pair = pair
