module Main (main) where

-- Tests à lancer avec : runghc -isrc tests/Spec.hs

import Data.List (isInfixOf)
import System.Exit (exitFailure)

import Args (defaultSettings, parseArgs)
import Code (decodeCode, encodeCode)
import Difficulty (classify, difficultyScore, hasRepeats, neighbors, rareCount)
import Game (evaluateGuess, shareGrid, validateGuess)
import Picker (chooseWord)
import Types (Command (..), Difficulty (..), Mark (..), Settings (..))
import WordList (parseWords)

tests :: [(String, Bool)]
tests =
    -- evaluateGuess réponse essai : une couleur par lettre de l'essai.
    -- Green = bonne lettre bien placée, Yellow = présente ailleurs, Gray = absente.

    -- Réponse "grave", essai "pause" :
    --   P absente, A présente ailleurs, U et S absentes, E bien placée.
    [ ("evaluateGuess : exemple du README",
        evaluateGuess "grave" "pause" == [Gray, Yellow, Gray, Gray, Green])
    -- Si l'essai est la réponse, chaque lettre est bien placée.
    , ("evaluateGuess : bonne réponse = tout vert",
        evaluateGuess "grave" "grave" == replicate 5 Green)
    -- Cas difficile des lettres répétées. Réponse "abbey" (deux B), essai "bobby" (trois B) :
    --   le B en position 3 est vert et utilise un des deux B de la réponse ;
    --   il reste un seul B libre, donc seul le premier B de l'essai est jaune,
    --   et le B en position 4 est gris (sinon on annoncerait trois B).
    , ("evaluateGuess : lettre répétée jaune une seule fois",
        evaluateGuess "abbey" "bobby" == [Yellow, Gray, Green, Gray, Green])

    -- validateGuess longueur listeDeMots essai : Right mot si accepté, Left message sinon.
    -- On vérifie un cas accepté, puis un cas refusé pour chaque règle.
    , ("validateGuess : mot valide mis en minuscules",
        validateGuess 5 dict "GRAVE" == Right "grave")
    , ("validateGuess : mauvaise longueur", isLeft (validateGuess 5 dict "abc"))
    , ("validateGuess : caractère interdit", isLeft (validateGuess 5 dict "gr4ve"))
    , ("validateGuess : mot absent de la liste", isLeft (validateGuess 5 dict "xyzzy"))

    -- Codes de puzzle : décoder un code qu'on vient de créer doit redonner
    -- exactement le même puzzle (longueur, essais, réponse).
    , ("encodeCode puis decodeCode redonne le puzzle",
        decodeCode (encodeCode 5 6 "grave") == Right (5, 6, "grave"))
    -- Un code tapé en minuscules doit donner le même résultat qu'en majuscules.
    , ("decodeCode accepte les minuscules",
        decodeCode "hl1-5-6-jbrtj" == decodeCode "HL1-5-6-JBRTJ")
    -- Codes invalides : chaque vérification de decodeCode doit renvoyer une erreur.
    , ("decodeCode : mauvaise version", isLeft (decodeCode "XX1-5-6-JBRTJ"))
    , ("decodeCode : longueur incohérente", isLeft (decodeCode "HL1-5-6-ABC")) -- annonce 5 lettres, en donne 3
    , ("decodeCode : format invalide", isLeft (decodeCode "n'importe quoi"))
    , ("decodeCode : zéro essai refusé", isLeft (decodeCode "HL1-5-0-JBRTJ"))

    -- parseArgs : transforme les arguments de la ligne de commande en Command.
    -- Sans option, on doit obtenir les réglages par défaut.
    , ("parseArgs : play sans option = réglages par défaut",
        parseArgs ["play"] == Right (Play defaultSettings))
    -- Chaque option modifie seulement son champ ; la difficulté accepte les majuscules.
    , ("parseArgs : play avec options",
        parseArgs ["play", "--length", "7", "--difficulty", "HARD", "--seed", "3"]
            == Right (Play defaultSettings { wordLength = 7, difficulty = Hard, seed = Just 3 }))
    -- --code est gardé tel quel : c'est decodeCode qui le vérifie plus tard.
    , ("parseArgs : --tries et --code",
        parseArgs ["play", "--tries", "3", "--code", "HL1-5-6-JBRTJ"]
            == Right (Play defaultSettings { tries = 3, code = Just "HL1-5-6-JBRTJ" }))
    , ("parseArgs : zéro essai refusé", isLeft (parseArgs ["play", "--tries", "0"]))
    , ("parseArgs : rate met le mot en minuscules",
        parseArgs ["rate", "Terre"] == Right (Rate "terre"))
    -- Entrées incorrectes : on doit obtenir une erreur, pas un plantage.
    , ("parseArgs : commande inconnue", isLeft (parseArgs ["dance"]))
    , ("parseArgs : option sans valeur", isLeft (parseArgs ["play", "--length"]))
    , ("parseArgs : longueur nulle refusée", isLeft (parseArgs ["play", "--length", "0"]))
    , ("parseArgs : difficulté inconnue", isLeft (parseArgs ["play", "--difficulty", "insane"]))

    -- parseWords : lit le contenu d'un CSV (un mot par ligne).
    -- "Grave" passe en minuscules, le \r des fins de ligne Windows est retiré,
    -- et le doublon "grave" n'est gardé qu'une fois.
    , ("parseWords : minuscules, \\r retiré, sans doublons",
        parseWords "Grave\r\npause\ngrave\n" == Right ["grave", "pause"])
    -- Un mot invalide en ligne 2 : le message d'erreur doit indiquer cette ligne.
    , ("parseWords : erreur avec numéro de ligne",
        either ("row 2" `isInfixOf`) (const False) (parseWords "grave\nb0njour\n"))
    , ("parseWords : fichier vide refusé", isLeft (parseWords ""))

    -- Critères de difficulté.
    -- Voisins de "light" = mots qui diffèrent d'une seule lettre : fight et might.
    -- ("light" lui-même diffère de 0 lettre et "grave" de 5 : pas des voisins.)
    , ("neighbors : mots à une lettre près",
        neighbors ["light", "fight", "might", "grave"] "light" == 2)
    , ("hasRepeats", hasRepeats "terre" && not (hasRepeats "grave"))
    -- Seuils : < 25 Easy, < 50 Medium, sinon Hard. On teste juste autour de chaque seuil.
    , ("classify : seuils",
        map classify [0, 24, 25, 49, 50, 100] == [Easy, Easy, Medium, Medium, Hard, Hard])

    -- rareCount : une lettre est rare si elle fait moins de 1 % des lettres de la liste.
    -- Ici la liste a 100 lettres : 'b' apparaît 1 fois (= 1 %, pas rare),
    -- 'z' 0 fois (rare). Donc "bz" a une seule lettre rare.
    , ("rareCount : seuil de 1 %",
        rareCount ['b' : replicate 99 'a'] "bz" == 1)

    -- difficultyScore = voisins (4 pts chacun, max 40) + lettres répétées (20)
    --                 + lettres rares (20 chacune, max 40).
    -- "grave" dans dict : 1 voisin (grive) = 4, pas de répétition, pas de lettre rare.
    , ("difficultyScore : cas simple", difficultyScore dict "grave" == 4)
    -- "mat" parmi aat, bat, ..., mat : 12 voisins = 48 points, plafonnés à 40.
    , ("difficultyScore : plafond des voisins",
        difficultyScore [c : "at" | c <- ['a' .. 'm']] "mat" == 40)
    -- "xyz" face à une liste de 'a' : 3 lettres rares = 60 points, plafonnés à 40.
    , ("difficultyScore : plafond des lettres rares",
        difficultyScore (replicate 10 "aaaaa") "xyz" == 40)
    -- "terre" dans dict : 0 voisin, lettres répétées (r, e) = 20.
    , ("difficultyScore : lettres répétées", difficultyScore dict "terre" == 20)

    -- chooseWord graineDeSecours mots réglages.
    -- Avec --seed, la graine de secours (l'horloge) est ignorée : même graine => même mot.
    , ("chooseWord : même graine = même mot",
        chooseWord 0 dict withSeed == chooseWord 999 dict withSeed)
    , ("chooseWord : le mot a la bonne longueur",
        fmap length (chooseWord 0 dict withSeed) == Just 5)
    -- Aucun mot de 12 lettres dans la liste : Nothing (Main affiche alors une erreur).
    , ("chooseWord : aucun mot de 12 lettres",
        chooseWord 0 dict defaultSettings { wordLength = 12 } == Nothing)

    -- shareGrid code essaisMax lignes : en-tête avec le score, puis une ligne de carrés par essai.
    -- Dernière ligne toute verte => gagné, le score est le nombre d'essais (2/6).
    , ("shareGrid : partie gagnée",
        shareGrid "HL1" 6 [[Gray, Green], [Green, Green]] == "hordle HL1 2/6\n⬛🟩\n🟩🟩\n")
    -- Dernière ligne pas toute verte => perdu, le score est X.
    , ("shareGrid : partie perdue = X",
        shareGrid "HL1" 1 [[Gray, Green]] == "hordle HL1 X/1\n⬛🟩\n")
    ]
  where
    -- Petite liste de mots utilisée par plusieurs tests.
    dict = ["grave", "pause", "terre", "aride", "grive"]
    -- Easy : seule difficulté garantie présente dans cette petite liste.
    withSeed = defaultSettings { difficulty = Easy, seed = Just 42 }

-- Vrai si le résultat est une erreur (Left), quel que soit le message.
isLeft :: Either a b -> Bool
isLeft (Left _) = True
isLeft _        = False

-- Garde les noms des tests dont la condition est fausse, les affiche,
-- puis quitte avec un code d'échec s'il y en a au moins un.
main :: IO ()
main = do
    let failed = [name | (name, ok) <- tests, not ok]
    mapM_ (putStrLn . ("ECHEC : " ++)) failed
    putStrLn (show (length tests - length failed) ++ "/" ++ show (length tests) ++ " tests reussis")
    if null failed then return () else exitFailure
