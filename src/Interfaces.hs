module Interfaces where

import Domain
import Data.Text (Text)
import Data.Time (UTCTime)

data AccountRepo m = AccountRepo
  { getAccountById :: Text -> m (Maybe Account)
  , updateBalance  :: Text -> Double -> m ()
  }

data TransactionRepo m = TransactionRepo
  { createTransfer             :: Transfer -> m ()
  , getTransferById            :: Text -> m (Maybe Transfer)
  , getTransactionsByAccountId :: Text -> m [Transfer]
  }

data ExternalBankService m = ExternalBankService
  { checkRecipientExists :: Text -> m Bool
  }

data SystemService m = SystemService
  { generateUUID   :: m Text
  , getCurrentTime :: m UTCTime
  }