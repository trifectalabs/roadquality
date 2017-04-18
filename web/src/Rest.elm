module Rest exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (encode, Value)
import Types exposing (Segment, Point, Route)


decodeSegment : Decoder Segment
decodeSegment =
    decode Segment
        |> required "id" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "start" decodePoint
        |> required "end" decodePoint
        |> required "polyline" Decode.string
        |> required "rating" Decode.float


decodePoint : Decoder Point
decodePoint =
    decode Point
        |> required "lng" Decode.float
        |> required "lat" Decode.float


encodePoint : Point -> Value
encodePoint point =
    Encode.object
        [ ( "lat", Encode.float point.lat )
        , ( "lng", Encode.float point.lng )
        ]


decodeRoute : Decoder Route
decodeRoute =
    decode Route
        |> required "distance" Decode.float
        |> required "polyline" Decode.string
