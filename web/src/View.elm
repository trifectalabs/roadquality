module View exposing (..)

import Html exposing (Html, a, div, text, input, button)
import Html.Attributes exposing (href, type_, value, target)
import Html.Events exposing (onClick, onInput)
import State exposing (Msg(..))
import Stylesheets exposing (mapNamespace, CssIds(..))
import Types exposing (Model, UrlRoute(..))


{ id, class, classList } =
    mapNamespace


view : Model -> Html Msg
view model =
    case model.page of
        LoginPage ->
            loginView

        MainPage ->
            mainView model

        AccountPage ->
            div [] [ text "account" ]


loginView : Html Msg
loginView =
    div [] [ a [ href "/login" ] [ text "Connect to Strava" ] ]


mainView : Model -> Html Msg
mainView model =
    div []
        [ div [ id MainView ] []
        , input
            [ type_ "number"
            , value <| toString model.rating
            , onInput ChangeRating
            ]
            []
        , button [ onClick SaveSegment ] [ text "Save Segment" ]
        , button [ onClick ClearAnchors ] [ text "Clear" ]
        ]
