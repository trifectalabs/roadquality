module Data.Map exposing (CycleRoute, decodeCycleRoute, Point, decodePoint, encodePoint, SurfaceType(..), PathType(..), Segment, decodeSegment, CreateSegmentForm, encodeCreateSegmentForm)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Util exposing ((=>))


type alias CycleRoute =
    { distance : Float
    , polyline : String
    }


decodeCycleRoute : Decoder CycleRoute
decodeCycleRoute =
    decode CycleRoute
        |> required "distance" Decode.float
        |> required "polyline" Decode.string


type alias Point =
    { lat : Float
    , lng : Float
    }


decodePoint : Decoder Point
decodePoint =
    decode Point
        |> required "lng" Decode.float
        |> required "lat" Decode.float


encodePoint : Point -> Value
encodePoint point =
    Encode.object
        [ "lat" => Encode.float point.lat
        , "lng" => Encode.float point.lng
        ]


type SurfaceType
    = Gravel
    | Asphalt
    | Dirt


surfaceTypeToString : SurfaceType -> String
surfaceTypeToString surfaceType =
    case surfaceType of
        Asphalt ->
            "asphalt"

        Dirt ->
            "dirt"

        Gravel ->
            "gravel"


type PathType
    = Shared
    | DedicatedLane
    | BikePath


pathTypeToString : PathType -> String
pathTypeToString pathType =
    case pathType of
        DedicatedLane ->
            "dedicatedLane"

        BikePath ->
            "bikePath"

        Shared ->
            "shared"


type alias Segment =
    { id : String
    , name : String
    , description : String
    , start : Point
    , end : Point
    , polyline : String
    , rating : Float
    }


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


type alias CreateSegmentForm =
    { name : String
    , description : String
    , polyline : String
    , surfaceRating : Int
    , trafficRating : Int
    , surface : SurfaceType
    , pathType : PathType
    }


encodeCreateSegmentForm : CreateSegmentForm -> Value
encodeCreateSegmentForm form =
    Encode.object
        [ "name" => Encode.string form.name
        , "description" => Encode.string form.description
        , "polyline" => Encode.string form.polyline
        , "surfaceRating" => Encode.int form.surfaceRating
        , "trafficRating" => Encode.int form.trafficRating
        , "surface" => (Encode.string <| surfaceTypeToString form.surface)
        , "pathType" => (Encode.string <| pathTypeToString form.pathType)
        ]
