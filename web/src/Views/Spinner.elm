module Views.Spinner exposing (spinner)

import Html exposing (Html, Attribute, div, li)
import Html.Attributes exposing (class, style)


spinner : Html msg
spinner =
    li [ class "sk-three-bounce" ]
        [ div [ class "sk-child sk-bounce1" ] []
        , div [ class "sk-child sk-bounce2" ] []
        , div [ class "sk-child sk-bounce3" ] []
        ]
