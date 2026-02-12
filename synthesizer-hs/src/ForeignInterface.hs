-- WARNING: This file has been auto-generated. Modifications should be done to `typegen.py` rather than this file directly
module ForeignInterface where
insertAtIndexMarker = 0 :: Int
insertAndForgetMarker = 1 :: Int
stopAtIndexMarker = 2 :: Int
exitMarker = 3 :: Int
sineGeneratorMarker = 4 :: Int
sineGeneratorWithFrequencyMarker = 5 :: Int
modulateOpMarker = 6 :: Int
mixOpMarker = 7 :: Int
envelopeMarker = 8 :: Int
volumeMarker = 9 :: Int
bellMarker = 10 :: Int
customMarker = 11 :: Int
custom2Marker = 12 :: Int


data AudioCommand = InsertAtIndex !Int !AudioGenerator
    | InsertAndForget !AudioGenerator
    | StopAtIndex !Int
    | Exit 
    deriving Show

data AudioGenerator = SineGenerator 
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
