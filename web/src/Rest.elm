module Rest exposing (..)

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder, andThen)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Json.Encode as Encode exposing (encode, Value)
import Types
    exposing
        ( Segment
        , Point
        , Route
        , CreateSegmentForm
        , SurfaceType(..)
        , PathType(..)
        , User
        )


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


decodeUser : Decoder User
decodeUser =
    decode User
        |> required "id" Decode.string
        |> required "firstName" Decode.string
        |> required "lastName" Decode.string
        |> required "email" Decode.string
        |> optional "birthdate" (Decode.nullable decodeDate) Nothing
        |> optional "sex" (Decode.nullable Decode.string) Nothing
        |> required "stravaToken" Decode.string
        |> required "createdAt" decodeDate
        |> required "updatedAt" decodeDate


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
