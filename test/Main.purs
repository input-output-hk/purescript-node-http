module Test.Main where

import Prelude

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE, log, logShow)

import Data.Foldable (foldMap)
import Data.Maybe (Maybe(..))

import Node.Encoding (Encoding(..))
import Node.HTTP (HTTP, listen, createServer, setHeader, requestMethod, requestURL, responseAsStream, requestAsStream, setStatusCode)
import Node.HTTP.Client as Client
import Node.Stream (Writable, end, pipe, writeString)

import Partial.Unsafe (unsafeCrashWith)

foreign import stdout :: forall eff r. Writable r eff

main :: forall eff. Eff (console :: CONSOLE, http :: HTTP | eff) Unit
main = do
  testBasic
  testHttps
  testCookies

testBasic :: forall eff. Eff (console :: CONSOLE, http :: HTTP | eff) Unit
testBasic = do
  server <- createServer respond
  listen server { hostname: "localhost", port: 8080, backlog: Nothing } $ void do
    log "Listening on port 8080."
    simpleReq "http://localhost:8080"
  where
  respond req res = do
    setStatusCode res 200
    let inputStream  = requestAsStream req
        outputStream = responseAsStream res
    log (requestMethod req <> " " <> requestURL req)
    case requestMethod req of
      "GET" -> do
        let html = foldMap (_ <> "\n")
              [ "<form method='POST' action='/'>"
              , "  <input name='text' type='text'>"
              , "  <input type='submit'>"
              , "</form>"
              ]
        setHeader res "Content-Type" "text/html"
        _ <- writeString outputStream UTF8 html (pure unit)
        end outputStream (pure unit)
      "POST" -> void $ pipe inputStream outputStream
      _ -> unsafeCrashWith "Unexpected HTTP method"

testHttps :: forall eff. Eff (console :: CONSOLE, http :: HTTP | eff) Unit
testHttps =
  simpleReq "https://pursuit.purescript.org/packages/purescript-node-http/badge"

testCookies :: forall eff. Eff (console :: CONSOLE, http :: HTTP | eff) Unit
testCookies =
  simpleReq
    "https://httpbin.org/cookies/set?cookie1=firstcookie&cookie2=secondcookie"

simpleReq :: forall eff. String -> Eff (console :: CONSOLE, http :: HTTP | eff) Unit
simpleReq uri = do
  log ("GET " <> uri <> ":")
  req <- Client.requestFromURI uri \response -> void do
    log "Headers:"
    logShow $ Client.responseHeaders response
    log "Cookies:"
    logShow $ Client.responseCookies response
    log "Response:"
    let responseStream = Client.responseAsStream response
    pipe responseStream stdout
  end (Client.requestAsStream req) (pure unit)
