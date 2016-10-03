{-|
Module      : Name Generator
Description : A library for generating names.
License     : GPL-3
Maintainer  : pommicket@gmail.com
-}

module NameGenerator
(Trigrams,
getTrigrams,
first2Chars,
nextChar,
generateName)
where

import qualified Data.Map as Map
import Data.List (isPrefixOf)
import Data.Char (toUpper)
import Text.Read (readMaybe)
import System.Random (randomRIO)

-- | A type that represents all the frequencies of trigrams.
type Trigrams = Map.Map String Int

-- | Extract a trigram from a line
addTrigram :: Trigrams -- ^ Currrent trigrams
           -> String   -- ^ Line
           -> Trigrams -- ^ New trigrams
addTrigram trigrams line = case (readMaybe value :: Maybe Int) of
                                Just val -> Map.insert trigram val trigrams
                                Nothing  -> error "There was a problem reading trigrams.txt"
                         where trigram = take 3 line
                               value   = drop 4 line

-- | Get all trigrams from trigrams.txt
getTrigrams :: IO Trigrams
getTrigrams = do
                trigrams <- readFile "trigrams.txt"
                return $ foldl addTrigram Map.empty $ lines trigrams

-- | Filter out all trigrams that start with a string
filterStartsWith :: String   -- ^ Only include trigrams that start with...
                 -> Trigrams -- ^ Trigrams
                 -> Trigrams -- ^ New trigrams
filterStartsWith start trigrams = Map.fromList $ filter (\(k, _)->start `isPrefixOf` k) $ Map.toList trigrams

-- | Pick a trigram by the sum of all previous ones.
pick :: Int    -- ^ Which trigram
     -> (String, Int) -- ^ The accumulator. fst: \"\" if it hasn't been found, the trigram otherwise. snd: sum so far
     -> (String, Int) -- ^ (key, value)
     -> (String, Int)  -- ^ fst: The trigram. snd: sum so far

pick n ("", sumSoFar) (k, v)
                           | sum' >= n = (k, 0)
                           | otherwise = ("", sum')
                           where sum' = sumSoFar + v
pick _ x _ = x

-- | Pick a (weighted) random trigram from a list.
pickFromTrigrams :: Trigrams -- ^ Which trigrams to pick from
                 -> IO String -- ^ The trigram
pickFromTrigrams trigrams = do
                                let total = sum $ Map.elems trigrams
                                chosen <- randomRIO (0, total)
                                let (trigram, _) = foldl (pick chosen) ("", 0) $ Map.toList trigrams
                                return trigram

-- | Get the first 2 characters of a name.
first2Chars :: Trigrams        -- ^ List of trigrams
            -> IO String       -- ^ First 2 characters
first2Chars trigrams = do
                        let options = filterStartsWith " " trigrams
                        trigram <- pickFromTrigrams options
                        return $ drop 1 trigram

-- | Take off end of list
takeEnd :: Int -- ^ Number of items
        -> [a] -- ^ List
        -> [a] -- ^ Items

takeEnd n l = drop (length l - n) l

-- | Next character in a name.
nextChar :: Trigrams -- ^ List of trigrams
         -> String   -- ^ Name so far
         -> IO Char  -- ^ Next character

nextChar trigrams name = do
                            let options = filterStartsWith (takeEnd 2 name) trigrams
                            trigram <- pickFromTrigrams options
                            return $ last trigram

generateName' :: Trigrams -- ^ List of trigrams
              -> IO String -- ^ Name so far
              -> IO String -- ^ New name

generateName' trigrams currentName = do
    name <- currentName
    next <- nextChar trigrams name
    if next == ' ' then currentName else generateName' trigrams $ fmap (++[next]) currentName

-- | Capitalizes a string
capitalize :: String -- ^ the string
           -> String -- ^ The capitalized string
capitalize (first:rest) = (toUpper first):rest

-- | Generate a name.
generateName :: Trigrams  -- ^ The list of trigrams
             -> IO String -- ^ The name

generateName trigrams = fmap capitalize $ generateName' trigrams $ first2Chars trigrams
