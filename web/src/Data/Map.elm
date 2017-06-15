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
    | UnknownSurface


surfaceTypeToString : SurfaceType -> String
surfaceTypeToString surfaceType =
    case surfaceType of
        Asphalt ->
            "asphalt"

        Dirt ->
            "dirt"

        Gravel ->
            "gravel"

        UnknownSurface ->
            "unknown"


type PathType
    = Shared
    | DedicatedLane
    | BikePath
    | UnknownPath


pathTypeToString : PathType -> String
pathTypeToString pathType =
    case pathType of
        DedicatedLane ->
            "dedicatedLane"

        BikePath ->
            "bikePath"

        Shared ->
            "shared"

        UnknownPath ->
            "unknown"


type alias Segment =
    { id : String
    , name : String
    , description : String
    , polyline : String
    , createdBy : String
    }


decodeSegment : Decoder Segment
decodeSegment =
    decode Segment
        |> required "id" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "polyline" Decode.string
        |> required "created_by" Decode.string


type alias CreateSegmentForm =
    { name : String
    , description : String
    , polylines : List String
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
        , "polylines" => (Encode.list <| List.map Encode.string form.polylines)
        , "surfaceRating" => Encode.int form.surfaceRating
        , "trafficRating" => Encode.int form.trafficRating
        , "surface" => (Encode.string <| surfaceTypeToString form.surface)
        , "pathType" => (Encode.string <| pathTypeToString form.pathType)
        ]
