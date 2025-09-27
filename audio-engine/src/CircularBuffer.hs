module CircularBuffer ( CircularBuffer
                      , constructCircularBuffer
                      , ElementType
                      , hasContent
                      , contentSize
                      , peekElement
                      , extractElements) where

import Foreign.Marshal.Array (peekArray, advancePtr)
import Foreign.Ptr (Ptr)
import Foreign.Storable (peek, poke)

import Data.Int (Int32)

import Debug.Trace


type ElementType = Float;

data CircularBuffer = CircularBuffer {
  _buffer :: !(Ptr ElementType),
  _bufferSize :: !Int32,
  _readIndex :: !(Ptr Int32),
  _writeIndex :: !(Ptr Int32)
  }

constructCircularBuffer :: Ptr ElementType -> Int32 -> Ptr Int32 -> Ptr Int32 -> CircularBuffer
constructCircularBuffer buffer bufferSize readIndex writeIndex =
  CircularBuffer { _buffer = buffer,
                   _bufferSize = bufferSize,
                   _readIndex = readIndex,
                   _writeIndex = writeIndex
                 }

getBuffer :: CircularBuffer -> Ptr ElementType
getBuffer = _buffer



getBufferWithOffset :: Int -> CircularBuffer -> Ptr ElementType
getBufferWithOffset count circularBuffer = advancePtr (getBuffer circularBuffer) count

getReadIndexPtr :: CircularBuffer -> Ptr Int32
getReadIndexPtr = _readIndex

getWriteIndexPtr :: CircularBuffer -> Ptr Int32
getWriteIndexPtr = _writeIndex

getReadIndex :: CircularBuffer -> IO Int
getReadIndex = fmap fromIntegral . peek . _readIndex

getWriteIndex :: CircularBuffer -> IO Int
getWriteIndex = fmap fromIntegral . peek . _writeIndex

getBufferSize :: CircularBuffer -> Int
getBufferSize = fromIntegral . _bufferSize

hasContent :: CircularBuffer -> IO Bool
hasContent circularBuffer = do
  rIndex <- getReadIndex circularBuffer
  wIndex <- getWriteIndex circularBuffer
  pure (rIndex /= wIndex)

contentSize :: CircularBuffer -> IO Int
contentSize circularBuffer = do
  wInd <- getWriteIndex circularBuffer
  rInd <- getReadIndex circularBuffer
  let difference = wInd - rInd
  pure $ if difference < 0 then
           fromIntegral (difference + getBufferSize circularBuffer)
         else
           fromIntegral difference

peekElement :: CircularBuffer -> IO (Maybe ElementType)
peekElement circularBuffer = do
  canReadElement <- hasContent circularBuffer
  readIndex <- getReadIndex circularBuffer

  if canReadElement then do
    [elementAt] <- peekArray 1 (getBufferWithOffset readIndex circularBuffer)
    pure $ Just elementAt
    else
    pure Nothing

extractElements :: Int -> CircularBuffer -> IO (Maybe [ElementType])
extractElements numElements circularBuffer = do
  size <- contentSize circularBuffer
  let notEnoughContent = numElements > size
  if notEnoughContent then do
    -- If trying to read more elements than applicable range, reset buffer and return nothing
    currentWrite <- getWriteIndex circularBuffer
    poke (getReadIndexPtr circularBuffer) (fromIntegral currentWrite)
    pure Nothing
    else do
    rIndex <- getReadIndex circularBuffer
    let nextReadIndex = rem (rIndex + numElements) (getBufferSize circularBuffer)
        numUpToBufferSize = min numElements (getBufferSize circularBuffer - rIndex)
        numAfterBufferSize = numElements - numUpToBufferSize
    endElements <- peekArray numUpToBufferSize (getBufferWithOffset rIndex circularBuffer)
    wrappingElements <- peekArray numAfterBufferSize (getBufferWithOffset 0 circularBuffer)
    poke (getReadIndexPtr circularBuffer) (fromIntegral nextReadIndex)
    pure $ Just (endElements ++ wrappingElements)
