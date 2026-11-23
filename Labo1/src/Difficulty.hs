    module Difficulty
             ( differences,
               letterCount,
               neighbors,
               hasRepeats,
               rareCount,
               difficultyScore,
               classify,
               difficultyName,
               rateWord,
             ) where

    import Data.Char (toLower, toUpper)
    import Data.List (nub)
    import Types (Difficulty (..))

    -- The criteria

    -- Number of letters in which two words of the same length differ
    differences :: String -> String -> Int
    differences a b = length [() | (x, y) <- zip a b, x /= y]

    -- Number of adjacent words that differ by only one letter
    neighbors :: [String] -> String -> Int
    neighbors ws w = length [x | x <- ws, length x == length w, differences x w == 1]

    -- Check whether the word contains at least one repeated letter.
    hasRepeats :: String -> Bool
    hasRepeats w = length (nub w) /= length w

    -- Count the occurences of one letter in the list of words
    letterCount :: [String] -> Char -> Int
    letterCount ws c = length [letter | word <- ws, letter <- word, letter == c]

    -- Count the occurences of rare letters in a word.
    -- Rare = Represent less than 1% of all the letter of the list
    rareCount :: [String] -> String -> Int
    rareCount ws w = length[c | c <- (nub w), letterCount ws c * 100 < total]
                        where total = length[x | v <- ws, x <- v]

    -- Calculate the difficulty score of a word
    -- Neighbor : 4 points foreach neighbor (max 40)
    -- Repeated letters : 20 points
    -- Rare letters : 20 points each (max 40)
    difficultyScore :: [String] -> String -> Int
    difficultyScore ws w = neighborPoints + repeatPoints + rarePoints
        where
            neighborPoints  = min 40 (4 * neighbors ws w) -- Take minimum between 40 and the result
            repeatPoints    = if hasRepeats w then 20 else 0
            rarePoints      = min 40 (20 * rareCount ws w)

    -- Classify a word based on its difficulty score
    classify :: Int -> Difficulty
    classify s
        | s < 25    = Easy
        | s < 50    = Medium
        | otherwise = Hard

    difficultyName :: Difficulty -> String
    difficultyName d = case d of
        Easy ->    "Easy"
        Medium ->  "Medium"
        Hard ->    "Hard"

    -- Show difficulty's detail of a word
    rateWord :: [String] -> String -> String
    rateWord ws raw = unlines
             [ "Mot               : " ++ map toUpper w,
               "Voisins           : " ++ show (neighbors ws w),
               "Lettres répétées  : " ++ (if hasRepeats w then "YES" else "NO"),
               "Lettres rares     : " ++ show (rareCount ws w),
               "Difficulté        : " ++ show s ++ "/100 (" ++ difficultyName (classify s) ++ ")"
             ]
             where
                w = map toLower raw
                s = difficultyScore ws w