{-# LANGUAGE OverloadedStrings #-}

module Infrastructure where

import Control.Concurrent.STM
import qualified Data.Map as M
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Time.Clock as Time
import Data.UUID.V4 (nextRandom)
import qualified Data.UUID as UUID

import Domain
import Interfaces
import App (App(..))
import Control.Monad.IO.Class (liftIO)


data Database = Database
  { dbAccounts  :: TVar (M.Map Text Account)
  , dbTransfers :: TVar (M.Map Text Transfer)
  }

initDB :: IO Database
initDB = do
  accountsTVar <- newTVarIO $ M.fromList 
    [ ("MY001", Account "MY001" 1500.0)
    , ("ACC123", Account "ACC123" 5000.0)
    , ("TEST01", Account "TEST01" 100.0)
    ]
  transfersTVar <- newTVarIO M.empty
  
  return $ Database accountsTVar transfersTVar



mkAccountRepo :: Database -> AccountRepo App
mkAccountRepo db = AccountRepo
  { getAccountById = \accId -> liftIO $ do
      accountsMap <- readTVarIO (dbAccounts db)
      return $ M.lookup accId accountsMap
      
  , updateBalance = \accId amountDiff -> liftIO $ atomically $ do
      accountsMap <- readTVar (dbAccounts db)
      let updatedMap = M.adjust (\acc -> acc { balance = balance acc + amountDiff }) accId accountsMap
      writeTVar (dbAccounts db) updatedMap
  }

mkTransactionRepo :: Database -> TransactionRepo App
mkTransactionRepo db = TransactionRepo
  { createTransfer = \transfer -> liftIO $ atomically $ do
      transfersMap <- readTVar (dbTransfers db)
      let updatedMap = M.insert (trId transfer) transfer transfersMap
      writeTVar (dbTransfers db) updatedMap
      
  , getTransferById = \txId -> liftIO $ do
      transfersMap <- readTVarIO (dbTransfers db)
      return $ M.lookup txId transfersMap
      
  , getTransactionsByAccountId = \accId -> liftIO $ do
      transfersMap <- readTVarIO (dbTransfers db)
      let allTransfers = M.elems transfersMap
      return $ filter (\tx -> trSender tx == accId || trReceiver tx == accId) allTransfers
  }

mkExternalBank :: ExternalBankService App
mkExternalBank = ExternalBankService
  { checkRecipientExists = \accId -> 
      return $ "ACC" `T.isPrefixOf` accId
  }

mkSystemService :: SystemService App
mkSystemService = SystemService
  { generateUUID = liftIO $ do
      uuid <- nextRandom
      return $ T.pack (UUID.toString uuid)
      
  , getCurrentTime = liftIO Time.getCurrentTime
  }