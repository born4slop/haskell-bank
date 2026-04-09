module Main where

import Network.Wai.Handler.Warp (run)
import Infrastructure (initDB, mkAccountRepo, mkTransactionRepo, mkExternalBank, mkSystemService)
import App (Env(..))
import Api (app)

main :: IO ()
main = do
  putStrLn "Starting In-Memory Database..."
  db <- initDB
  
  let env = Env
        { envAccountRepo     = mkAccountRepo db
        , envTransactionRepo = mkTransactionRepo db
        , envExternalBank    = mkExternalBank
        , envSystemService   = mkSystemService
        }
        
  putStrLn "Starting Bank API Server on port 8080..."
  run 8080 (app env)