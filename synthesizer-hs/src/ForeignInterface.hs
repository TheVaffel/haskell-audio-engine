-- WARNING: This file has been auto-generated. Modifications should be done to `typegen.py` rather than this file directly
module ForeignInterface where
insertAtIndexMarker = 0 :: Int
insertAndForgetMarker = 1 :: Int
stopAtIndexMarker = 2 :: Int
exitMarker = 3 :: Int
setExternalParameterMarker = 4 :: Int
setExternalParameter2Marker = 5 :: Int
setExternalParameter3Marker = 6 :: Int
sineGeneratorMarker = 7 :: Int
sineGeneratorWithFrequencyMarker = 8 :: Int
modulateOpMarker = 9 :: Int
mixOpMarker = 10 :: Int
envelopeMarker = 11 :: Int
volumeMarker = 12 :: Int
distanceFactorMarker = 13 :: Int
bellMarker = 14 :: Int
externalParameterMarker = 15 :: Int
customMarker = 16 :: Int
custom2Marker = 17 :: Int


data AudioCommand = InsertAtIndex !Int !AudioGenerator
    | InsertAndForget !AudioGenerator
    | StopAtIndex !Int
    | Exit 
    | SetExternalParameter !Int !Float !Float
    | SetExternalParameter2 !(Int, Int) !(Float, Float) !Float
    | SetExternalParameter3 !(Int, Int, Int) !(Float, Float, Float) !Float
    deriving Show

data AudioGenerator = SineGenerator !AudioGenerator
    | SineGeneratorWithFrequency !Float
    | ModulateOp !AudioGenerator !AudioGenerator
    | MixOp !AudioGenerator !AudioGenerator
    | Envelope !Float !Float !Float
    | Volume !Float !AudioGenerator
    | DistanceFactor !(Int, Int, Int) !AudioGenerator
    | Bell !Float
    | ExternalParameter !Int
    | Custom !Float
    | Custom2 !Float
    | NoGenerator
    deriving Show

paramIndexListenerX = -1000 :: Float
paramIndexListenerY = -1001 :: Float
paramIndexListenerZ = -1002 :: Float