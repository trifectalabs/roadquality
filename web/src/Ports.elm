port module Ports exposing (storeSession, onSessionChange, up, down, setLayer, refreshLayer, zoomLevel, routeCreate, addAnchor, setAnchor, moveAnchor, removedAnchor, removeAnchor, snapAnchor, displayRoute, removeRoute, clearRouting)

import Data.Map exposing (Point)
import Json.Encode exposing (Value)


port storeSession : Maybe String -> Cmd msg


port onSessionChange : (Value -> msg) -> Sub msg


port up : Maybe ( Maybe String, Maybe String, Maybe String ) -> Cmd msg


port down : () -> Cmd msg


port setLayer : String -> Cmd msg


port refreshLayer : String -> Cmd msg


port zoomLevel : (Float -> msg) -> Sub msg


port routeCreate : () -> Cmd msg


port addAnchor : ( String, Float, Float ) -> Cmd msg


port setAnchor : (( Float, Float ) -> msg) -> Sub msg


port moveAnchor : (( String, Float, Float ) -> msg) -> Sub msg


port removedAnchor : (String -> msg) -> Sub msg


port removeAnchor : String -> Cmd msg


port snapAnchor : ( String, Point ) -> Cmd msg


port displayRoute : ( String, String, List ( Float, Float ) ) -> Cmd msg


port removeRoute : String -> Cmd msg


port clearRouting : List String -> Cmd msg
