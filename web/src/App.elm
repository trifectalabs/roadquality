module App exposing (..)

import Navigation
import State exposing (Msg(UrlChange), init, update, subscriptions)
import Types exposing (Model)
import View exposing (view)


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
