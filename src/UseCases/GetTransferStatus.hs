{-# LANGUAGE OverloadedStrings #-}

module UseCases.GetTransferStatus where

import Data.Text (Text)
import App
import Domain
import Interfaces
import Control.Monad.Reader
import Control.Monad.Except

getTransferStatus :: Text -> Text -> App (Either AppError Transfer)
getTransferStatus txId currentAccountId = runExceptT $ do
  env <- ask
  let repo = envTransactionRepo env
  
  txOpt <- lift $ getTransferById repo txId
  tx <- case txOpt of
    Just t  -> return t
    Nothing -> throwError $ NotFoundError "Transaction not found"
    
  if trSender tx == currentAccountId || trReceiver tx == currentAccountId
    then return tx
    else throwError ForbiddenError