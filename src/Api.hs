{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Api where

import Servant
import Data.Aeson
import Data.Text (Text)
import qualified Data.Text.Encoding as TE
import qualified Data.ByteString.Lazy as BL
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (runReaderT)

import Domain
import App (Env, App, runApp)
import UseCases.ExecuteTransfer (executeTransfer)
import UseCases.GetAccountInfo (getAccountInfo)
import UseCases.GetTransferStatus (getTransferStatus)
import UseCases.GetTransactionHistory (getTransactionHistory)


data TransferReqDTO = TransferReqDTO 
  { to_acc :: Text
  , amount :: Double 
  } deriving (Generic)

data TransferResDTO = TransferResDTO 
  { id     :: Text
  , status :: Text 
  } deriving (Generic)

data AccountBalDTO = AccountBalDTO 
  { acc :: Text
  , bal :: Double 
  } deriving (Generic)

data HistoryResDTO = HistoryResDTO 
  { h_id        :: Text
  , h_amount    :: Double
  , h_status    :: Text
  , h_timestamp :: UTCTime
  } deriving (Generic)

instance FromJSON TransferReqDTO
instance ToJSON TransferResDTO
instance ToJSON AccountBalDTO
instance ToJSON HistoryResDTO

statusToText :: TransferStatus -> Text
statusToText PENDING = "PENDING"
statusToText OK      = "OK"
statusToText FAILED  = "FAILED"

transferToResDTO :: Transfer -> TransferResDTO
transferToResDTO tx = TransferResDTO (trId tx) (statusToText $ trStatus tx)

accountToBalDTO :: Account -> AccountBalDTO
accountToBalDTO a = AccountBalDTO (accId a) (balance a)

transferToHistoryDTO :: Transfer -> HistoryResDTO
transferToHistoryDTO tx = HistoryResDTO 
  { h_id = trId tx
  , h_amount = trAmount tx
  , h_status = statusToText (trStatus tx)
  , h_timestamp = trTimestamp tx
  }


type BankAPI = 
       "api" :> "v1" :> "transfers" :> ReqBody '[JSON] TransferReqDTO :> Post '[JSON] TransferResDTO
  :<|> "api" :> "v1" :> "accounts" :> "me" :> Get '[JSON] AccountBalDTO
  :<|> "api" :> "v1" :> "transfers" :> Capture "id" Text :> Get '[JSON] TransferResDTO
  :<|> "api" :> "v1" :> "accounts" :> "me" :> "history" :> Get '[JSON] [HistoryResDTO]

bankAPI :: Proxy BankAPI
bankAPI = Proxy


mapErrorToHTTP :: AppError -> ServerError
mapErrorToHTTP err = case err of
  ValidationError msg -> err400 { errBody = BL.fromStrict $ TE.encodeUtf8 msg }
  NotFoundError msg   -> err404 { errBody = BL.fromStrict $ TE.encodeUtf8 msg }
  NotEnoughFundsError -> err422 { errBody = "No Funds" }
  BusinessError msg   -> err400 { errBody = BL.fromStrict $ TE.encodeUtf8 msg }
  ForbiddenError      -> err401 { errBody = "Unauthorized" }
  InternalError msg   -> err500 { errBody = BL.fromStrict $ TE.encodeUtf8 msg }

runUseCase :: Env -> App (Either AppError a) -> (a -> b) -> Handler b
runUseCase env usecase mapper = do
  result <- liftIO $ runReaderT (runApp usecase) env
  case result of


server :: Env -> Server BankAPI
server env = handlePostTransfer 
        :<|> handleGetMe 
        :<|> handleGetTransfer 
        :<|> handleGetHistory 
  where
    currentUserId = "MY001"

    handlePostTransfer req = 
      runUseCase env (executeTransfer currentUserId (to_acc req) (amount req)) transferToResDTO
      
    handleGetMe = 
      runUseCase env (getAccountInfo currentUserId) accountToBalDTO
      
    handleGetTransfer txId = 
      runUseCase env (getTransferStatus txId currentUserId) transferToResDTO
      
    handleGetHistory = 
      runUseCase env (getTransactionHistory currentUserId currentUserId) (map transferToHistoryDTO)

app :: Env -> Application
app env = serve bankAPI (server env)