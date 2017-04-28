module Rest exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (encode, Value)
import Types
    exposing
        ( Segment
        , Point
        , Route
        , CreateSegmentForm
        , SurfaceType(..)
        , PathType(..)
        )


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


surfaceTypeToString : SurfaceType -> String
surfaceTypeToString surfaceType =
    case surfaceType of
        Asphalt ->
            "asphalt"

        Dirt ->
            "dirt"

        Gravel ->
            "gravel"


pathTypeToString : PathType -> String
pathTypeToString pathType =
    case pathType of
        DedicatedLane ->
            "dedicatedLane"

        BikePath ->
            "bikePath"

        Shared ->
            "shared"


encodeCreateSegmentForm : CreateSegmentForm -> Value
encodeCreateSegmentForm form =
    Encode.object
        [ ( "name", Encode.string form.name )
        , ( "description", Encode.string form.description )
        , ( "points", Encode.list <| List.map encodePoint form.points )
        , ( "surfaceRating", Encode.int form.surfaceRating )
        , ( "trafficRating", Encode.int form.trafficRating )
        , ( "surface", Encode.string <| surfaceTypeToString form.surface )
        , ( "pathType", Encode.string <| pathTypeToString form.pathType )
        ]


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
