{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE OverloadedStrings #-}

module Domain where 

import Data.Text (Text)
import Data.Time (UTCTime)

data Account = Account
  { accId :: Text
  , balance :: Double
  } deriving (Show, Eq)

data TransferStatus 
  = PENDING 
  | OK 
  | FAILED
  deriving (Show, Eq)

data Transfer = Transfer
  { trId        :: Text
  , trSender    :: Text
  , trReceiver  :: Text
  , trAmount    :: Double
  , trStatus    :: TransferStatus
  , trTimestamp :: UTCTime
  } deriving (Show, Eq)

data AppError = ValidationError Text
  | NotFoundError Text
  | BusinessError Text
  | NotEnoughFundsError
  | ForbiddenError
  | InternalError Text
  deriving (Show, Eq)

validateTransferAmount :: Double -> Either AppError ()
validateTransferAmount amount
  | amount <= 0 = Left $ ValidationError "Amount must be greater than zero"
  | otherwise   = Right ()

checkFunds :: Account -> Double -> Either AppError ()
checkFunds account amount
  | balance account < amount = Left NotEnoughFundsError
  | otherwise                = Right ()