module Views.StravaLogin exposing (view)

import Html exposing (..)
import Html.Attributes exposing (href)
import Stylesheets exposing (loginNamespace, CssIds(..), CssClasses(..))
import Views.Assets as Assets


{ id, class, classList } =
    loginNamespace


view : Html msg
view =
    div
        [ class [ Login ] ]
        [ a
            [ href "/login" ]
            [ img [ Assets.src Assets.stravaLogin ] [] ]
        ]
