{-# LANGUAGE OverloadedStrings #-}
module Main where

import System.Environment
import Devrant
import Data.Aeson
import Data.List
import Data.List.Split

prettyPrintRant :: Rant -> String
prettyPrintRant x =
    "user: " ++ (Devrant.username . Devrant.user) x ++ ",\n" ++
    "id: " ++ show (Devrant.rantID x) ++ "\n" ++
    concatMap (\y -> "    " ++ y ++ "\n") (splitOn "\n" $ Devrant.text x) ++ "\n\n--------\n\n"

prettyPrintRants :: [Rant] -> String
prettyPrintRants = foldr ((++) . prettyPrintRant) ""

optStrArg :: String -> String -> [String] -> String
optStrArg name def args =
    case elemIndex name args of
        Nothing -> def
        Just i -> args !! (i +  1)

optArg :: (Read a) => String -> a -> [String] -> a
optArg name def args =
    case elemIndex name args of
        Nothing -> def
        Just i -> read $ args !! (i + 1)

get :: [String] -> IO ()
get ("rants":args) = do
    rants <- getRants (optStrArg "--sort" "algo" args)
                      (optArg "--limit" 10 args)
                      (optArg "--skip" 0 args)
    case rants of
        Error e -> putStrLn $ "Error: " ++ e
        Success v -> putStrLn $ prettyPrintRants v

get ("rant":rantID:args) = do
    res <- getRant (read rantID)
    case res of
        Error e -> putStrLn e
        Success v -> putStrLn $ prettyPrintRant v

get _ = putStrLn "Invalid command"

command :: [String] -> IO ()
command ("get":args) = get args
command ("search":term:args) = do
    res <- searchRants term
    case res of
        Error e -> putStrLn e
        Success v -> putStrLn $ prettyPrintRants v
command _ = putStrLn "Invalid command"

main :: IO ()
main = do
    args <- getArgs
    command $ if null args
                then ["help"]
                else args
