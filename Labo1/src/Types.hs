module Types
    ( Difficulty (..),  -- (..) Permet d'afficher les constructeurs
      Mark (..),        -- et pas seulement le nom. (Donc pouvoir
      Conig (..),       -- utiliser (Easy, Medium, Hard) pour Difficulty)
      Command (..)
    ) where

-- Difficulty levels for a word
data Difficulty = Easy | Medium | Hard
    deriving (Show, Eq)

-- Result after a guess
data Mark = Green | Yellow | Gray
    deriving (Show, Eq)

-- Settings of the game
data Settings = Settings {
    wordLength :: Int,
    difficulty :: Difficulty,
    tries :: Int,
    seed :: Maybe Int, -- Maybe because optionnal
    code :: Maybe String -- Maybe because optionnal
}

-- Commands of the game
data Command = Play Config | Rate String deriving Show