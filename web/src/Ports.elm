port module Ports exposing (storeSession, onSessionChange, up, down, setLayer, refreshLayer, zoomLevel, isRouting, hideSources, addSource, setAnchor, movedAnchor, removedAnchor)

import Json.Encode exposing (Value)


port storeSession : Maybe String -> Cmd msg


port onSessionChange : (Value -> msg) -> Sub msg


port up : Maybe ( Maybe String, Maybe String, Maybe String ) -> Cmd msg


port down : () -> Cmd msg


port setLayer : String -> Cmd msg


port refreshLayer : String -> Cmd msg


port zoomLevel : (Float -> msg) -> Sub msg


port isRouting : Bool -> Cmd msg


port hideSources : List String -> Cmd msg


port addSource : ( String, Maybe String, Maybe Value, List ( Float, Float ) ) -> Cmd msg


port setAnchor : (( Float, Float ) -> msg) -> Sub msg


port movedAnchor : (( String, Float, Float ) -> msg) -> Sub msg


port removedAnchor : (String -> msg) -> Sub msg
