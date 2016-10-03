{- Testing NameGenerator -}

module Main (main) where

import System.IO (hFlush, stdout)
import NameGenerator (generateName, getTrigrams)

main :: IO ()
main = do
            trigrams <- getTrigrams
            putStr "Number of names? "
            hFlush stdout
            num <- getLine
            names <- sequence $ replicate (read num :: Int) $ generateName trigrams
            mapM_ putStrLn names
