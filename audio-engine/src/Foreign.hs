{-# LANGUAGE ForeignFunctionInterface #-}

module Foreign where

import Foreign.C.Types
import Foreign.Ptr

import CircularBuffer (ElementType, constructCircularBuffer, extractElements)
import Loop (playWithCircularBuffer)

import Data.Int

-- Arguments are: buffer, buffer size, read index, write index
playHs :: Ptr ElementType -> Int32 -> Ptr Int32 -> Ptr Int32 -> IO ()
playHs buffer bufferSize readIndex writeIndex =
  let circularBuffer = constructCircularBuffer buffer bufferSize readIndex writeIndex
  in playWithCircularBuffer circularBuffer

play_hs = playHs

foreign export ccall play_hs :: Ptr ElementType -> Int32 -> Ptr Int32 -> Ptr Int32 -> IO ()
