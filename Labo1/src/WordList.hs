module WordList (loadWords,
                parseWords,
                filterByLength)
                where

import Data.Char (toLower) --  Converts all words in our .CSV file to lowercase
import Data.List (nub) -- Removes duplicate elements from a list

-- Reading of a file
loadWords :: FilePath -> IO (Either String [String])
loadWords path = do
    contents <- readFile path -- Read file (contents = String of all the file)
    case parseWords contents of
        Left err -> return (Left (path ++ ", " ++ err))
        Right ws -> return (Right ws)

-- backticks : Transforme "elem lettre liste" -> "lettre elem liste"
-- Pour avoir (all fonction liste) -> all Lettre1 elem Liste
-- Left : Error
-- Right : Good result
-- Check if a word is valid
checkWord :: String -> Either String String
checkWord raw
    | null raw                  = Left "The word is empty"
    | not (all (`elem` ['a' .. 'z']) w) = Left ("\"" ++ raw ++ "\" should contains only letters.")
    | otherwise                 = Right w
    where w = map toLower raw

-- Check if all rows are valid
checkRows :: [(Int, String)] -> Either String [String]
checkRows [] = Right []
checkRows ((numero, row) : rest) =
    case checkWord (cleanLine row) of
        Left err -> Left ("row " ++ show numero ++ " : " ++ err)
        Right w ->
            case checkRows rest of
                Left err -> Left err
                Right ws -> Right (w : ws)

-- Retire le \r d'un fichier Windows
cleanLine :: String -> String
cleanLine = filter (/= '\r')

-- Parse the words from the file contents
parseWords :: String -> Either String [String]
parseWords contents =
    case checkRows (zip [1 ..] (lines contents)) of
        Left err -> Left err
        Right [] -> Left "No words found."
        Right ws -> Right (nub ws)

filterByLength :: Int -> [String] -> [String]
filterByLength n ws = [w | w <- ws, length w == n]