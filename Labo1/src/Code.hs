module Code
    ( encodeCode,
      decodeCode
    ) where

import Data.Char (chr, isDigit, ord, toLower, toUpper)
import Data.List (intercalate)

-- Un code de puzzle ressemble à : HL1-5-6-JBRTJ  (réponse "grave")
--   HL1   = version du format (HL pour Hordle)
--   5     = longueur du mot
--   6     = nombre d'essais
--   JBRTJ = la réponse, brouillée pour ne pas être lisible au premier coup d'œil
codeVersion :: String
codeVersion = "HL1"

-- Crée le code d'un puzzle.
--   encodeCode longueur essaisMax reponse
encodeCode :: Int -> Int -> String -> String
encodeCode len maxTries answer =
    intercalate "-" [codeVersion, show len, show maxTries, scramble answer]

-- Lit un code et retrouve (longueur, essaisMax, reponse).
-- Les vérifications se font dans l'ordre ; la première qui échoue donne l'erreur.
decodeCode :: String -> Either String (Int, Int, String)
decodeCode raw =
    case splitOn '-' code of
        [v, l, t, w]
            | v /= codeVersion                 -> bad ("version \"" ++ v ++ "\" inconnue")
            | not (isNumber l && isNumber t)   -> bad "la longueur et le nombre d'essais doivent être des nombres"
            | read t < 1                       -> bad "il faut au moins un essai"
            | not (all (`elem` ['A' .. 'Z']) w) -> bad "le mot ne doit contenir que des lettres"
            | length w /= read l               -> bad "la longueur ne correspond pas au mot"
            | otherwise                        -> Right (read l, read t, unscramble w)
        _ -> bad "format attendu : HL1-longueur-essais-MOT"
  where
    code = map toUpper raw -- accepte aussi un code tapé en minuscules
    bad reason = Left ("code \"" ++ raw ++ "\" invalide : " ++ reason ++ ".")
    isNumber s = not (null s) && all isDigit s

-- Découpe une chaîne à chaque séparateur.
--   splitOn '-' "HL1-5-6-ABC" == ["HL1", "5", "6", "ABC"]
splitOn :: Char -> String -> [String]
splitOn sep s =
    case break (== sep) s of
        (part, [])       -> [part]
        (part, _ : rest) -> part : splitOn sep rest

-- Brouillage : chaque lettre avance dans l'alphabet d'un décalage qui dépend
-- de sa position (3, puis 10, puis 17, ...). Une même lettre ne donne donc pas
-- toujours la même lettre brouillée.
shiftAt :: Int -> Int
shiftAt i = 3 + 7 * i

-- Avance une lettre minuscule de k places, en revenant à 'a' après 'z'.
-- `mod` 26 marche aussi avec k négatif : (-1) `mod` 26 == 25.
shiftLetter :: Int -> Char -> Char
shiftLetter k c = chr (ord 'a' + (ord c - ord 'a' + k) `mod` 26)

scramble :: String -> String
scramble w = [toUpper (shiftLetter (shiftAt i) c) | (i, c) <- zip [0 ..] w]

-- Fait le chemin inverse : on recule du même décalage.
unscramble :: String -> String
unscramble w = [shiftLetter (negate (shiftAt i)) (toLower c) | (i, c) <- zip [0 ..] w]
