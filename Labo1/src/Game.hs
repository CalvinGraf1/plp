module Game
    ( evaluateGuess,
      validateGuess,
      markSquare,
      showMarks,
      playGame
    ) where

import Data.Char (toLower, toUpper)
import Data.List (delete, intercalate)
import System.IO (hFlush, stdout)
import Types (Mark (..))

-- Vérifie qu'un essai tapé par le joueur est acceptable.
--   validateGuess longueur listeDeMots essai
--
-- Right mot   -> l'essai est valide (mis en minuscules)
-- Left raison -> l'essai est refusé, avec le message à afficher
--
-- Les vérifications se font dans l'ordre : longueur, lettres, présence dans la liste.
-- La première qui échoue donne le message d'erreur.

-- ValidateGuess : prend la longueur du mot, la liste de mots et l'essai, et retourne soit un message d'erreur (Left) soit l'essai validé (Right)
validateGuess :: Int -> [String] -> String -> Either String String
validateGuess n ws raw -- n est la longueur du mot, ws est la liste de mots, raw est l'essai tapé par le joueur
    | length guess /= n                 = Left ("\"" ++ raw ++ "\" doit contenir " ++ show n ++ " lettres.") -- si la longueur de l'essai n'est pas égale à n, on retourne un message d'erreur
    | not (all (`elem` ['a' .. 'z']) guess) = Left ("\"" ++ raw ++ "\" ne doit contenir que des lettres.") -- si l'essai contient des caractères qui ne sont pas des lettres, on retourne un message d'erreur
    | guess `notElem` ws                = Left ("\"" ++ raw ++ "\" n'est pas dans la liste de mots.") -- on cherche si le mot existe dans le dictionnaire français
    | otherwise                         = Right guess -- si toutes les vérifications passent, on retourne l'essai validé
  where
    guess = map toLower raw -- on met l'essai en minuscules pour éviter les problèmes de casse

-- Compare un essai à la réponse et donne une couleur par lettre.
--   evaluateGuess reponse essai
--
-- On travaille en deux temps pour gérer les lettres répétées :
--   1. "restantes" = les lettres de la réponse qui ne sont PAS bien placées.
--      Ce sont les seules qui peuvent encore donner un jaune.
--   2. On parcourt l'essai lettre par lettre :
--        - même lettre au même endroit   -> Green
--        - lettre présente dans restantes -> Yellow, et on l'enlève de restantes
--          (pour qu'elle ne serve pas deux fois)
--        - sinon                          -> Gray
--
-- Exemple : evaluateGuess "grave" "pause" == [Gray, Yellow, Gray, Gray, Green]

-- EvaluateGuess : prend la réponse et l'essai, et retourne une liste de marques (Green, Yellow, Gray) pour chaque lettre de l'essai.
evaluateGuess :: String -> String -> [Mark] -- Permet de comparer l'essai à la réponse et de donner une couleur par lettre
evaluateGuess answer guess = marks (zip guess answer) leftovers -- zip permet de créer une liste de paires (lettre de l'essai, lettre de la réponse) pour chaque position
  where 
    leftovers = [a | (g, a) <- zip guess answer, g /= a]  -- leftovers contient les lettres de la réponse qui ne sont pas bien placées, c'est-à-dire celles qui peuvent encore donner un jaune

    marks [] _ = [] -- Si la liste est vide, on retourne une liste vide
    marks ((g, a) : rest) pool -- On parcourt l'essai lettre par lettre, en comparant chaque lettre de l'essai (g) avec la lettre correspondante de la réponse (a)
        | g == a        = Green  : marks rest pool -- Si la lettre de l'essai est la même que celle de la réponse, on retourne Green et on continue avec le reste de l'essai
        | g `elem` pool = Yellow : marks rest (delete g pool) -- Si la lettre de l'essai est présente dans les lettres restantes de la réponse, on retourne Yellow et on enlève cette lettre de la liste des lettres restantes (pour qu'elle ne serve pas deux fois)
        | otherwise     = Gray   : marks rest pool -- Sinon, on retourne Gray et on continue avec le reste de l'essai

-- Donne le carré de couleur correspondant à une marque.
-- Servira aussi pour la grille de partage (shareGrid).
markSquare :: Mark -> String
markSquare Green  = "🟩"
markSquare Yellow = "🟨"
markSquare Gray   = "⬛"

-- Affiche un essai sur deux lignes : les lettres en majuscules, puis les carrés.
--   showMarks "pause" [Gray, Yellow, Gray, Gray, Green]
--   P  A  U  S  E
--   ⬛ 🟨 ⬛ ⬛ 🟩
-- Un carré prend la largeur de deux caractères dans le terminal : on met donc
-- deux espaces entre les lettres et un seul entre les carrés pour qu'ils soient alignés.

-- ShowMarks : prend un essai et une liste de marques, et retourne une chaîne de caractères représentant l'essai avec les lettres en majuscules et les carrés de couleur correspondants
showMarks :: String -> [Mark] -> String
showMarks guess ms = letters ++ "\n" ++ squares -- On concatène les lettres et les carrés avec un retour à la ligne entre les deux
  where
    letters = intercalate "  " [[toUpper c] | c <- guess] -- letters contient les lettres de l'essai en majuscules, séparées par deux espaces (car un carré prend la largeur de deux caractères dans le terminal)
    squares = unwords (map markSquare ms) -- squares contient les carrés de couleur correspondant aux marques, séparés par un espace

-- Boucle de jeu dans le terminal.
--   playGame essaisMax listeDeMots reponse
--
-- Retourne la liste des marques de chaque essai valide (pour la grille de partage).
--
-- loop k historique :
--   k          = numéro de l'essai en cours (commence à 1)
--   historique = marques des essais valides déjà joués
--
-- Un essai invalide relance loop avec le même k : il ne consomme pas d'essai.

-- PlayGame : prend le nombre maximum d'essais, la liste de mots et la réponse, et lance la boucle de jeu dans le terminal
playGame :: Int -> [String] -> String -> IO [[Mark]]
playGame maxTries ws answer = loop 1 []
  where
    n = length answer -- n est la longueur du mot à deviner

    loop k history -- On boucle tant que k <= maxTries, sinon on a perdu
        | k > maxTries = do -- Si k est supérieur au nombre maximum d'essais, on a perdu
            putStrLn ("Perdu ! Le mot était " ++ map toUpper answer ++ ".") -- On affiche le mot à deviner en majuscules
            return history -- On retourne l'historique des essais valides

        | otherwise = do -- On affiche le numéro de l'essai en cours et on attend la saisie du joueur
            putStr ("Essai " ++ show k ++ "/" ++ show maxTries ++ " > ") -- On affiche le numéro de l'essai en cours
            hFlush stdout -- affiche le texte tout de suite, avant d'attendre la saisie
            input <- getLine -- On lit la saisie du joueur
            case validateGuess n ws input of -- On valide l'essai du joueur
                Left err -> do -- Si l'essai est invalide, on affiche le message d'erreur et on relance la boucle avec le même k (l'essai n'est pas compté)
                    putStrLn ("Essai invalide : " ++ err)
                    putStrLn ""
                    loop k history -- même k : l'essai n'est pas compté
                
                Right guess -> do -- Si l'essai est valide, on évalue l'essai et on affiche les marques correspondantes
                    let ms = evaluateGuess answer guess -- On évalue l'essai et on obtient la liste des marques correspondantes
                    putStrLn (showMarks guess ms) -- On affiche les marques correspondantes à l'essai
                    putStrLn ""
                    if all (== Green) ms -- Si toutes les marques sont Green, le joueur a gagné
                        then do
                            putStrLn ("Gagné en " ++ show k ++ "/" ++ show maxTries ++ " !")
                            return (history ++ [ms])
                        else loop (k + 1) (history ++ [ms]) -- On relance la boucle avec k + 1 et on ajoute les marques de l'essai à l'historique
