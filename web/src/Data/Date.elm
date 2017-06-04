module Data.Date exposing (encodeDate, decodeDate)

import Date exposing (Date)
import Date.Format exposing (format)
import Json.Decode as Decode exposing (Decoder, andThen)
import Json.Encode as Encode exposing (Value)


decodeDate : Decoder Date
decodeDate =
    Decode.string
        |> andThen
            (\val ->
                case Date.fromString val of
                    Err err ->
                        Decode.fail err

                    Ok date ->
                        Decode.succeed date
            )


encodeDate : Date -> Value
encodeDate date =
    Encode.string <| format "%Y-%m-%dT%H:%M:%S" date
