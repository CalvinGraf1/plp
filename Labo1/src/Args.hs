module Args
    ( parseArgs,
      defaultSettings
    ) where

import Data.Char (isDigit, toLower)
import Types (Command (..), Difficulty (..), Settings (..))

-- Réglages utilisés quand le joueur ne précise rien.
defaultSettings :: Settings
defaultSettings = Settings
    { wordLength = 5,
      difficulty = Medium,
      tries      = 6,
      seed       = Nothing,
      code       = Nothing
    }

-- Transforme les arguments de la ligne de commande en une commande.
--   ["play", "--length", "7"] -> Right (Play (Settings {wordLength = 7, ...}))
--   ["rate", "terre"]         -> Right (Rate "terre")
--   ["dance"]                 -> Left "commande inconnue : dance. ..."
parseArgs :: [String] -> Either String Command
parseArgs ("play" : opts) =
    case parseOptions defaultSettings opts of
        Left err -> Left err
        Right s  -> Right (Play s)
parseArgs ["rate", w] = Right (Rate (map toLower w))
parseArgs ("rate" : _) = Left "utilisation : hordle rate MOT"
parseArgs (cmd : _)   = Left ("commande inconnue : " ++ cmd ++ ". Commandes : play, rate.")
parseArgs []          = Left "utilisation : hordle play [options] ou hordle rate MOT"

-- Lit les options deux par deux (nom, valeur) et met à jour les réglages.
-- La syntaxe  s { wordLength = n }  crée une copie de s où seul wordLength change.
parseOptions :: Settings -> [String] -> Either String Settings
parseOptions s [] = Right s
parseOptions s ("--length" : v : rest) = do
    n <- readPositive "--length" v
    parseOptions s { wordLength = n } rest
parseOptions s ("--tries" : v : rest) = do
    n <- readPositive "--tries" v
    parseOptions s { tries = n } rest
parseOptions s ("--difficulty" : v : rest) = do
    d <- readDifficulty v
    parseOptions s { difficulty = d } rest
parseOptions s ("--seed" : v : rest) = do
    n <- readNumber "--seed" v
    parseOptions s { seed = Just n } rest
parseOptions s ("--code" : v : rest) =
    parseOptions s { code = Just v } rest
parseOptions _ [opt]
    | opt `elem` knownOptions = Left ("l'option " ++ opt ++ " attend une valeur.")
parseOptions _ (opt : _) = Left ("option inconnue : " ++ opt ++ ".")

knownOptions :: [String]
knownOptions = ["--length", "--tries", "--difficulty", "--seed", "--code"]

-- Lit un nombre entier positif ou nul (uniquement des chiffres).
readNumber :: String -> String -> Either String Int
readNumber opt v
    | not (null v) && all isDigit v = Right (read v)
    | otherwise                     = Left (opt ++ " attend un nombre, pas \"" ++ v ++ "\".")

-- Comme readNumber, mais refuse 0.
readPositive :: String -> String -> Either String Int
readPositive opt v = do
    n <- readNumber opt v
    if n > 0
        then Right n
        else Left (opt ++ " doit être plus grand que 0.")

readDifficulty :: String -> Either String Difficulty
readDifficulty v =
    case map toLower v of
        "easy"   -> Right Easy
        "medium" -> Right Medium
        "hard"   -> Right Hard
        _        -> Left ("difficulté inconnue : \"" ++ v ++ "\". Choix : easy, medium, hard.")
