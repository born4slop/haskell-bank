{-# LANGUAGE OverloadedStrings #-}

module UseCases.ExecuteTransfer where

import Data.Text (Text)
import App
import Domain
import Interfaces
import Control.Monad.Reader
import Control.Monad.Except (ExceptT, runExceptT, liftEither, throwError)
import Control.Monad.IO.Class (liftIO)

executeTransfer :: Text -> Text -> Double -> App (Either AppError Transfer)
executeTransfer senderId receiverId amount = runExceptT $ do
  env <- ask
  let accRepo = envAccountRepo env
      bankSvc = envExternalBank env
      txRepo  = envTransactionRepo env
      sysSvc  = envSystemService env

  liftEither $ validateTransferAmount amount

  senderOpt <- lift $ getAccountById accRepo senderId
  sender <- case senderOpt of
    Just acc -> return acc
    Nothing  -> throwError $ NotFoundError "Sender account not found"

  liftEither $ checkFunds sender amount

  isRecipientValid <- lift $ checkRecipientExists bankSvc receiverId
  if not isRecipientValid
    then throwError $ BusinessError "Recipient account rejected by external bank"
    else return ()

  lift $ updateBalance accRepo senderId (-amount)
  lift $ updateBalance accRepo receiverId amount
  
  newTxId <- lift $ generateUUID sysSvc
  now     <- lift $ getCurrentTime sysSvc

  let transfer = Transfer 
        { trId = newTxId
        , trSender = senderId
        , trReceiver = receiverId
        , trAmount = amount
        , trStatus = OK
        , trTimestamp = now
        }
        
  lift $ createTransfer txRepo transfer

  return transfer