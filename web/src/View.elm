module View exposing (..)

import Html exposing (Html, a, div, text, input, button, select, option, label, textarea)
import Html.Attributes exposing (href, type_, value, target, placeholder, step, for, selected)
import Html.Events exposing (onClick, onInput)
import State exposing (Msg(..))
import Stylesheets exposing (mapNamespace, CssIds(..), CssClasses(..))
import Types exposing (Model, UrlRoute(..), RatingsInterfaceState)


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
        , ratingsInterface model.menu <| List.length model.anchorOrder
        ]


ratingsInterface : RatingsInterfaceState -> Int -> Html Msg
ratingsInterface menu anchorCount =
    if not menu.drawingSegment then
        div [ id SaveRatingControl ]
            [ text "Click anywhere to start making a rating" ]
    else if anchorCount < 2 then
        div [ id SaveRatingControl ]
            [ text "Place one or more points to make a rating" ]
    else
        div [ id SaveRatingControl, class [ DrawingSegment ] ]
            [ div [] [ text "Make a rating" ]
            , label [ for "mapNameInput" ] [ text "Name" ]
            , input
                [ type_ "text"
                , value menu.name
                , onInput ChangeName
                , placeholder "Name me!"
                , id NameInput
                , class [ MenuInput ]
                ]
                []
            , label [ for "mapDescriptionInput" ] [ text "Description" ]
            , textarea
                [ value menu.description
                , onInput ChangeDescription
                , placeholder "Give some deets"
                , id DescriptionInput
                , class [ MenuInput ]
                ]
                []
            , label [ for "mapSurfaceInput" ] [ text "Surface" ]
            , div
                [ id SurfaceInput
                , class [ MenuInput, DropInput ]
                ]
                [ select
                    [ onInput ChangeSurfaceRating
                    , id SurfaceInput
                    , class [ MenuInput ]
                    ]
                    [ option
                        [ value "1"
                        , selected <| menu.surfaceRating == 1
                        ]
                        [ text "1" ]
                    , option
                        [ value "2"
                        , selected <| menu.surfaceRating == 2
                        ]
                        [ text "2" ]
                    , option
                        [ value "3"
                        , selected <| menu.surfaceRating == 3
                        ]
                        [ text "3" ]
                    , option
                        [ value "4"
                        , selected <| menu.surfaceRating == 4
                        ]
                        [ text "4" ]
                    , option
                        [ value "5"
                        , selected <| menu.surfaceRating == 5
                        ]
                        [ text "5" ]
                    ]
                ]
            , label [ for "mapTrafficInput" ] [ text "Traffic" ]
            , div
                [ id TrafficInput
                , class [ MenuInput, DropInput ]
                ]
                [ select
                    [ onInput ChangeTrafficRating
                    , id TrafficInput
                    , class [ MenuInput ]
                    ]
                    [ option
                        [ value "1"
                        , selected <| menu.trafficRating == 1
                        ]
                        [ text "1" ]
                    , option
                        [ value "2"
                        , selected <| menu.trafficRating == 2
                        ]
                        [ text "2" ]
                    , option
                        [ value "3"
                        , selected <| menu.trafficRating == 3
                        ]
                        [ text "3" ]
                    , option
                        [ value "4"
                        , selected <| menu.trafficRating == 4
                        ]
                        [ text "4" ]
                    , option
                        [ value "5"
                        , selected <| menu.trafficRating == 5
                        ]
                        [ text "5" ]
                    ]
                ]
            , label [ for "mapSurfaceTypeInput" ] [ text "Surface Type" ]
            , div
                [ id SurfaceTypeInput
                , class [ MenuInput, DropInput ]
                ]
                [ select
                    [ onInput ChangeSurfaceType ]
                    [ option [ value "Asphalt" ] [ text "Asphalt" ]
                    , option [ value "Dirt" ] [ text "Dirt" ]
                    , option [ value "Gravel" ] [ text "Gravel" ]
                    ]
                ]
            , label [ for "mapPathTypeInput" ] [ text "Path Type" ]
            , div
                [ id PathTypeInput
                , class [ MenuInput, DropInput ]
                ]
                [ select
                    [ onInput ChangePathType ]
                    [ option [ value "Shared" ] [ text "Shared" ]
                    , option [ value "DedicatedLane" ] [ text "Bike Lane" ]
                    , option [ value "BikePath" ] [ text "Bike Path" ]
                    ]
                ]
            , button [ onClick SaveSegment ] [ text "Save Segment" ]
            , button [ onClick ClearAnchors ] [ text "Clear" ]
            ]
