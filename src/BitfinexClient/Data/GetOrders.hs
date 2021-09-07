module BitfinexClient.Data.GetOrders
  ( Request (..),
  )
where

import BitfinexClient.Class.FromRpc
import BitfinexClient.Data.Kind
import BitfinexClient.Data.Money
import BitfinexClient.Data.Order
import BitfinexClient.Data.Type
import BitfinexClient.Import.External
import BitfinexClient.Util
import qualified Data.Aeson as A
import Data.Aeson.Lens
import qualified Data.Map as Map
import qualified Data.Text as T

data Request
  = Request
      { currencyPair :: CurrencyPair,
        orderIds :: Set OrderId
      }
  deriving (Eq, Ord, Show)

instance ToJSON Request where
  toJSON = toJSON . orderIds

instance FromRpc 'RetrieveOrders Request (Map OrderId Order) where
  fromRpc Rpc = parseOrderMap

instance FromRpc 'OrdersHistory Request (Map OrderId Order) where
  fromRpc Rpc = parseOrderMap

parseOrderMap :: Request -> RawResponse -> Either Error (Map OrderId Order)
parseOrderMap req res@(RawResponse raw) = do
  json <-
    first (failure . T.pack) $ A.eitherDecode raw
  case json of
    A.Array xs -> foldrM parser mempty xs
    _ -> Left $ failure "Json value is not an array"
  where
    failure =
      fromRpcError RetrieveOrders res
    parser x acc = do
      id0 <-
        maybeToRight (failure "OrderId is missing") $
          OrderId
            <$> x ^? nth 0 . _Integer
      amt <-
        maybeToRight (failure "OrderAmount is missing") $
          x ^? nth 7 . _Number
      ss0 <-
        maybeToRight (failure "OrderStatus is missing") $
          x ^? nth 13 . _String
      ss1 <-
        first failure $
          newOrderStatus ss0
      price <-
        maybeToRight
          (failure "ExchangeRate is missing")
          $ x ^? nth 16 . _Number
      rate <-
        newExchangeRate' (currencyPair req) (toRational price)
      let order =
            Order
              { orderId = id0,
                orderRate = rate,
                orderAmount = toRational amt,
                orderStatus = ss1
              }
      pure $
        Map.insert id0 order acc
