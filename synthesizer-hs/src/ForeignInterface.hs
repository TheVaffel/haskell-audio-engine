-- WARNING: This file has been auto-generated. Modifications should be done to `typegen.py` rather than this file directly
module ForeignInterface where
insertAtIndexMarker = 0 :: Int
insertAndForgetMarker = 1 :: Int
stopAtIndexMarker = 2 :: Int
exitMarker = 3 :: Int
setExternalParameterMarker = 4 :: Int
sineGeneratorMarker = 5 :: Int
sineGeneratorWithFrequencyMarker = 6 :: Int
modulateOpMarker = 7 :: Int
mixOpMarker = 8 :: Int
envelopeMarker = 9 :: Int
volumeMarker = 10 :: Int
bellMarker = 11 :: Int
customMarker = 12 :: Int
custom2Marker = 13 :: Int
externalMarker = 14 :: Int
constantMarker = 15 :: Int
signalMarker = 16 :: Int


data AudioCommand = InsertAtIndex !Int !AudioGenerator
    | InsertAndForget !AudioGenerator
    | StopAtIndex !Int
    | Exit 
    | SetExternalParameter !Int !Float !Float
    deriving Show

data AudioParameter = External !Int
    | Constant !Float
    | Signal !AudioGenerator
    deriving Show

data AudioGenerator = SineGenerator !AudioParameter
    | SineGeneratorWithFrequency !Float
    | ModulateOp !AudioGenerator !AudioGenerator
    | MixOp !AudioGenerator !AudioGenerator
    | Envelope !Float !Float !Float
    | Volume !Float !AudioGenerator
    | Bell !Float
    | Custom !Float
    | Custom2 !Float
    | NoGenerator
    deriving Show
