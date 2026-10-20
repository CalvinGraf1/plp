import Types
import WordList (filterByLength)
import Difficulty (difficultyScore, classify)

-- Generate a random number using a linear congruential generator
nextRandom :: Int -> Int
nextRandom x = (1103515245 * (x `mod` 2147483648) + 12345) `mod` 2147483648 -- Linear congruential generator

-- Transforme une graine en un indice valide (entre 0 et n - 1).
-- 1. nextRandom s donne un grand nombre pseudo-aléatoire.
-- 2. `div` 65536 (2^16) supprime ses 16 bits de poids faible : avec ce type
--     de générateur, ils sont peu aléatoires (le dernier alterne pair/impair).
-- 3. `mod` n ramène le résultat dans la plage des indices d'une liste de
--     n éléments.
-- Exemple : nextRandom : 1250496027 `div` 65536  →  19081
--           pickIndex  : 19081 `mod` 86          →  75
pickIndex :: Int -> Int -> Int
pickIndex s n (nextRandom s `div` 65536) `mod` n

-- Generate a list of candidate words based on the settings
candidates :: [String] -> Settings -> [String]
candidates ws settings = [w | w <- filterByLength (wordLength settings) ws,
                     classify (difficultyScore ws w) == difficulty settings]



-- Choose a word based on the settings and a fallback seed
chooseWord :: Int -> [String] -> Settings -> Maybe String
chooseWord fallbackSeed ws settings =
    case candidates ws settings of
        [] -> Nothing
        cs -> Just (cs !! pickIndex s (length cs)) -- !! return the element at the given index in the list
    where
        s = case seed settings of
            Nothing -> fallbackSeed
            Just n  -> n
