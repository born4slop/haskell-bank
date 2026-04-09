module UseCases.GetTransactionHistory where

import Data.Text (Text)
import App
import Domain
import Interfaces
import Control.Monad.Reader

getTransactionHistory :: Text -> Text -> App (Either AppError [Transfer])
getTransactionHistory reqAccountId currentAccountId = do
  if reqAccountId /= currentAccountId
    then return $ Left ForbiddenError
    else do
      env <- ask
      let repo = envTransactionRepo (env :: Env)
      Right <$> getTransactionsByAccountId repo reqAccountId