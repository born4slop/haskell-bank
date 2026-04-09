{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE DeriveFunctor #-}

module App where

import Control.Monad.Reader
import Interfaces

data Env = Env
  { envAccountRepo       :: AccountRepo App
  , envTransactionRepo   :: TransactionRepo App
  , envExternalBank      :: ExternalBankService App
  , envSystemService     :: SystemService App
  }

newtype App a = App { runApp :: ReaderT Env IO a }
  deriving (Functor, Applicative, Monad, MonadReader Env, MonadIO)