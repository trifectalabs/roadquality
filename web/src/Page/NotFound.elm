module Page.NotFound exposing (view)

import Html exposing (Html, h1, div, img, text, span, a)
import Html.Attributes exposing (class, id, src, alt, href)
import Data.Session as Session exposing (Session)
import Views.Assets as Assets
import Stylesheets exposing (errorNamespace, CssIds(..), CssClasses(..))
import Route


-- VIEW --


{ id, class, classList } =
    errorNamespace


view : Session -> Html msg
view session =
    div [ id Content, class [ NotFound ] ]
        [ h1 []
            [ text "Looks like you're lost. Time to head "
            , a [ Route.href Route.Home ] [ text "home" ]
            , text "."
            ]
        , div []
            [ img
                [ Assets.src Assets.error
                , alt "cyclist lost in the snow"
                ]
                []
            ]
        ]
