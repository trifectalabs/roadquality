module Data.Map exposing (RoutingMode(..), MapLayer(..), CycleRoute, decodeCycleRoute, Point, decodePoint, encodePoint, SurfaceType(..), PathType(..), Segment, decodeSegment, CreateSegmentForm, encodeCreateSegmentForm)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required, optional)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import Util exposing ((=>))


type RoutingMode
    = SegmentsMode
    | CreateMode


type MapLayer
    = PlainMap
    | SurfaceQuality
    | TrafficSafety
    | SegmentsView


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
    , name : Maybe String
    , description : Maybe String
    , polyline : String
    , createdBy : String
    }


decodeSegment : Decoder Segment
decodeSegment =
    decode Segment
        |> required "id" Decode.string
        |> optional "name" (Decode.nullable Decode.string) Nothing
        |> optional "description" (Decode.nullable Decode.string) Nothing
        |> required "polyline" Decode.string
        |> required "created_by" Decode.string


type alias CreateSegmentForm =
    { name : Maybe String
    , description : Maybe String
    , polylines : List String
    , surfaceRating : Int
    , trafficRating : Int
    , surfaceType : SurfaceType
    , pathType : PathType
    }


encodeCreateSegmentForm : CreateSegmentForm -> Value
encodeCreateSegmentForm form =
    Encode.object
        [ "name" => EncodeExtra.maybe Encode.string form.name
        , "description" => EncodeExtra.maybe Encode.string form.description
        , "polylines" => (Encode.list <| List.map Encode.string form.polylines)
        , "surfaceRating" => Encode.int form.surfaceRating
        , "trafficRating" => Encode.int form.trafficRating
        , "surfaceType" => (Encode.string <| surfaceTypeToString form.surfaceType)
        , "pathType" => (Encode.string <| pathTypeToString form.pathType)
        ]
