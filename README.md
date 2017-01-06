# devrant-haskell
Unofficial devRant haskell api

## API
```
User = {
  username :: String
  userID :: Int
  userScore :: Int
}
```
  

```
Rant = {
  text :: String
  rantID :: Int
  user :: User
}
```

```
getRant :: Int -> IO (Result Rant)
getRant id
```

```
searchRants :: String -> IO (Result [Rant])
searchRants term
```

```
getProfileByID :: Int -> IO (Result User)
getProfileByID id
```

```
getUser :: String -> IO (Result User)
getUser username
```

## Note
This project is mostly for learning haskell and is written by a complete amateur. Help is most definately wanted.  
Also badly commented
