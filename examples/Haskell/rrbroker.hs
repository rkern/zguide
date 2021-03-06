module Main where

import System.ZMQ
import Control.Monad (forever)
    
main :: IO ()
main = withContext 1 $ \context -> do
    withSocket context Router $ \frontend -> do
        bind frontend "tcp://*:5559"
        withSocket context Dealer $ \backend -> do
            bind backend "tcp://*5560"
            forever $ loop_function frontend backend (-1)

loop_function :: Socket a -> Socket b -> Timeout -> IO ()
loop_function front back timeout = do
    [S _front' status1, S _back' status2] <- poll [S front In, S back In] timeout
    process front back status1
    process back front status2

process sock_recv sock_to_send None = return ()
process sock_recv sock_to_send In = do
    msg <- receive sock_recv []
    more <- moreToReceive sock_recv
    if more then (send sock_to_send msg [SndMore] >> 
                  process sock_recv sock_to_send In) 
        else (send sock_to_send msg [])