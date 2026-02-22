module Utils where

applyMaybe :: Maybe (a -> a) -> a -> a
applyMaybe Nothing value = value
applyMaybe (Just f) value = f value
