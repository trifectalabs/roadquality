module Types exposing (..)

import Dict exposing (Dict)


type alias Model =
    { anchors : Dict Int Point
    , anchorOrder : List Int
    , route : Maybe Route
    , rating : Int
    , page : UrlRoute
    , host : String
    }


type UrlRoute
    = LoginPage
    | MainPage
    | AccountPage


type alias Route =
    { distance : Float
    , polyline : String
    }


type alias Point =
    { lat : Float
    , lng : Float
    }


type alias Segment =
    { id : String
    , name : String
    , description : String
    , start : Point
    , end : Point
    , polyline : String
    , rating : Float
    }
