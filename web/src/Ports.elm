port module Ports exposing (storeSession, onSessionChange, up, down, setLayer, routeCreate, setAnchor, moveAnchor, removeAnchor, snapAnchor, displayRoute, removeRoute, clearRoute)

import Data.Map exposing (Point)
import Json.Encode exposing (Value)


port storeSession : Maybe String -> Cmd msg


port onSessionChange : (Value -> msg) -> Sub msg


port up : () -> Cmd msg


port down : () -> Cmd msg


port setLayer : String -> Cmd msg


port routeCreate : () -> Cmd msg


port setAnchor : (( String, Float, Float ) -> msg) -> Sub msg


port moveAnchor : (( String, Float, Float ) -> msg) -> Sub msg


port removeAnchor : (String -> msg) -> Sub msg


port snapAnchor : ( String, Point ) -> Cmd msg


port displayRoute : ( String, List ( Float, Float ) ) -> Cmd msg


port removeRoute : String -> Cmd msg


port clearRoute : () -> Cmd msg
