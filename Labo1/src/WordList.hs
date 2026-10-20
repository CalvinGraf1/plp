module WordList (loadWords) where


-- Reading of a file
loadWords :: FilePath -> IO [String]
loadWords path = do
    contents <- readFile path
    return (lines contents)