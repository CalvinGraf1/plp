module Main (main) where

import Control.Monad (when)
import Data.Time.Clock.POSIX (getPOSIXTime)
import System.Directory (doesFileExist)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.Info (os)
import System.IO (hPutStrLn, hSetEncoding, stderr, stdout, utf8)
import System.Process (callCommand)

import Args (parseArgs)
import Code (decodeCode, encodeCode)
import Difficulty (difficultyName, rateWord)
import Game (playGame, shareGrid)
import Picker (chooseWord)
import Types (Command (..), Settings (..))
import WordList (loadWords)

-- Liste de mots utilisée par défaut.
wordsFile :: FilePath
wordsFile = "data/words.csv"

-- Dictionnaire (~180 000 mots) qui sert uniquement à accepter ou refuser un essai.
-- Les réponses, elles, sont toujours tirées de wordsFile.
dictionaryFile :: FilePath
dictionaryFile = "data/dictionary.csv"

-- Charge le dictionnaire : un mot par ligne, déjà en minuscules, sans accents
-- et sans doublons. On n'utilise pas loadWords ici, car son nub (qui retire
-- les doublons) compare chaque mot à tous les autres : beaucoup trop lent
-- pour 180 000 mots.
-- Si le fichier n'existe pas, on joue simplement sans dictionnaire.
loadDictionary :: FilePath -> IO [String]
loadDictionary path = do
    exists <- doesFileExist path
    if exists
        then do
            contents <- readFile path
            return (lines (filter (/= '\r') contents))
        else return []

-- Prépare le terminal pour afficher les carrés et les accents.
-- Il faut deux choses :
--   1. Haskell doit écrire en UTF-8 (hSetEncoding).
--   2. Sous Windows, la console doit aussi LIRE de l'UTF-8. Par défaut elle
--      utilise une ancienne page de codes (850), et "🟩" s'affiche comme "ƒƒ®".
--      La commande "chcp 65001" passe la console en UTF-8.
setupConsole :: IO ()
setupConsole = do
    when (os == "mingw32") (callCommand "chcp 65001 > nul") -- "mingw32" = Windows
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

-- Point d'entrée : lit les arguments, charge les mots, puis lance la commande.
main :: IO ()
main = do
    setupConsole
    args <- getArgs
    case parseArgs args of
        Left err -> failWith err
        Right cmd -> do
            loaded <- loadWords wordsFile
            case loaded of
                Left err -> failWith err
                Right ws -> run ws cmd

-- Exécute une commande, une fois la liste de mots chargée.
run :: [String] -> Command -> IO ()
run ws (Rate w) = putStr (rateWord ws w)
run ws (Play s) = do
    puzzle <- choosePuzzle ws s
    case puzzle of
        Left err -> failWith err
        Right (len, maxTries, answer) -> do
            let puzzleCode = encodeCode len maxTries answer
            putStrLn ("Puzzle " ++ puzzleCode ++ " (" ++ show len ++ " lettres, "
                      ++ show maxTries ++ " essais)")
            putStrLn ""
            dict <- loadDictionary dictionaryFile
            -- Essais acceptés : le dictionnaire, la liste de mots, et la réponse
            -- (avec --code, elle pourrait venir d'une autre liste de mots).
            rows <- playGame maxTries (answer : ws ++ dict) answer
            putStrLn ""
            putStrLn "Partagez votre résultat :"
            putStr (shareGrid puzzleCode maxTries rows)

-- Trouve le puzzle à jouer : (longueur, essais, réponse).
--   avec --code : on décode le code
--   sinon       : on tire un mot selon les réglages (graine --seed, ou l'horloge)
choosePuzzle :: [String] -> Settings -> IO (Either String (Int, Int, String))
choosePuzzle ws s =
    case code s of
        Just c -> return (decodeCode c)
        Nothing -> do
            fallback <- clockSeed
            case chooseWord fallback ws s of
                Nothing -> return (Left noWord)
                Just w  -> return (Right (wordLength s, tries s, w))
  where
    noWord = "aucun mot de " ++ show (wordLength s) ++ " lettres avec la difficulté "
             ++ difficultyName (difficulty s) ++ " dans " ++ wordsFile ++ "."

-- Graine tirée de l'horloge (en millisecondes), utilisée quand il n'y a pas de --seed.
clockSeed :: IO Int
clockSeed = do
    t <- getPOSIXTime
    return (floor (t * 1000))

-- Affiche une erreur et quitte le programme avec un code d'échec.
failWith :: String -> IO ()
failWith err = do
    hPutStrLn stderr ("Erreur : " ++ err)
    exitFailure
