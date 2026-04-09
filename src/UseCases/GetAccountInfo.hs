{-# LANGUAGE OverloadedStrings #-}

module UseCases.GetAccountInfo where

import Data.Text (Text)
import App
import Domain
import Interfaces
import Control.Monad.Reader

getAccountInfo :: Text -> App (Either AppError Account)
getAccountInfo accId = do
  env <- ask
  let repo = envAccountRepo env
  
  result <- getAccountById repo accId
  case result of
    Just acc -> return $ Right acc
    Nothing  -> return $ Left $ NotFoundError "Account not found"