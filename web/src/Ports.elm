port module Ports exposing (storeSession, onSessionChange, up, setAnchor, snapAnchor, displayRoute, clearRoute)

import Data.Map exposing (Point)
import Json.Encode exposing (Value)


port storeSession : Maybe String -> Cmd msg


port onSessionChange : (Value -> msg) -> Sub msg


port up : Bool -> Cmd msg


port setAnchor : (( Int, Float, Float ) -> msg) -> Sub msg


port snapAnchor : ( Int, Point ) -> Cmd msg


port displayRoute : List ( Float, Float ) -> Cmd msg


port clearRoute : () -> Cmd msg
