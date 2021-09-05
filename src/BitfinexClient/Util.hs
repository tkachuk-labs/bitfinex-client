module BitfinexClient.Util
  ( fromRpcError,
    newNonce,
  )
where

import BitfinexClient.Data.Kind
import BitfinexClient.Data.Type
import BitfinexClient.Import.External
import Data.Time.Clock.POSIX (posixSecondsToUTCTime)

fromRpcError :: Method -> RawResponse -> Text -> Error
fromRpcError method res err =
  ErrorFromRpc $
    show method
      <> " FromRpc failed because "
      <> err
      <> " in "
      <> show res

newNonce :: MonadIO m => m Nonce
newNonce = liftIO $ Nonce . utcTimeToMicros <$> getCurrentTime

utcTimeToMicros :: UTCTime -> Integer
utcTimeToMicros x =
  diffTimeToPicoseconds
    ( fromRational
        . toRational
        $ diffUTCTime x epoch
    )
    `div` 1000000

epoch :: UTCTime
epoch = posixSecondsToUTCTime 0
