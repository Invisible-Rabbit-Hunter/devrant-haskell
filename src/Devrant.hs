{-# LANGUAGE OverloadedStrings #-}
module Devrant
    ( getRants
    , getRant
    , searchRants
    , Rant
    , rantID
    , text
    , user
    , User
    , username
    , userID
    , userScore
    ) where

import Network.HTTP.Simple
import qualified Data.ByteString.Lazy as BL
import Data.Aeson as JSON
import Data.Aeson.Types as JSON
import qualified Data.HashMap.Lazy as HM
import Foundation ((<>))
import qualified Data.Vector as V

data User = User { username :: String
                 , userID :: Int
                 , userScore :: Int
                 } deriving (Show)

data Rant = Rant { text :: String
                 , rantID :: Int
                 , user :: User
                 } deriving (Show)

noArgs :: [(String, String)]
noArgs = []

toRant :: Value -> Result Rant
toRant = parse $ withObject "rant" $ \obj -> do
    text <- obj .: "text"
    rantID <- obj .: "id"
    username <- obj .: "user_username"
    userID <- obj .: "user_id"
    userScore <- obj .: "user_score"
    return Rant { text = text
                , rantID = rantID
                , user = User { username = username
                              , userID = userID
                              , userScore = userScore}}

toRants :: Value -> Result [Rant]
toRants v = case parse (withArray "rants" $ return . V.map toRant) v of
    Error e -> Error e
    Success v -> if all (\x -> case x of
                        Error e -> False
                        Success v -> True) (V.toList v)
                    then Success $ map (\x -> case x of
                        Success v -> v) (V.toList v)
                    else Error "Something went wrong"

toUser :: Value -> Result User
toUser = parse $ withObject "user" $ \obj -> do
    username <- obj .: "username"
    userID <- obj .: "id"
    score <- obj .: "score"
    return User {username = username, userID = userID, userScore = score}

apiCall :: String -> [(String, String)] -> IO Object
apiCall path args = do
    req <- parseRequest $ "GET https://www.devrant.io/api/" ++ path ++ "?app=3" ++ foldl (\a b -> a ++ "&" ++ fst b ++ "=" ++ snd b) "" args
    res <- httpJSON req
    return $ getResponseBody res

getRants :: String -> Int -> Int -> IO (Result [Rant])
getRants sort limit skip = do
    res <- apiCall "devrant/rants" [("sort", sort), ("limit", show limit), ("skip", show skip)]
    return $ case HM.lookup "rants" res of
        Nothing ->  Error "Request Failed"
        Just v -> toRants v

getRant :: Int -> IO (Result Rant)
getRant rantID = do
    res <- apiCall ("devrant/rants/" ++ show rantID) noArgs
    return $ case HM.lookup "rant" res of
        Nothing -> Error "Request Failed"
        Just v -> toRant v

searchRants :: String -> IO (Result [Rant])
searchRants term = do
    res <- apiCall "devrant/search" [("term", term)]
    return $ case HM.lookup "results" res of
        Nothing -> Error "Request Failed"
        Just v -> toRants v

getProfileByID :: Int -> IO (Result User)
getProfileByID userID = do
    res <- apiCall ("users/" ++ show userID) noArgs
    return $ case HM.lookup "results" res of
        Nothing -> Error "Request Failed"
        Just v -> toUser v

getUser :: String -> IO (Result User)
getUser username = do
    res <- apiCall "get-user-id" [("username", username)]
    case HM.lookup "user_id" res of
        Nothing -> return $ Error "User does not exist"
        Just v -> case (fromJSON v :: Result Int) of
            Error e -> return $ Error e
            Success v -> getProfileByID v
