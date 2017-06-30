module Views.Messages exposing (Message, MessageType(..), Model, initModel, view, subscriptions, Msg(..), update)

import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
import Dict exposing (Dict)
import Util exposing ((=>))
import Stylesheets exposing (messagesNamespace, CssIds(..), CssClasses(..))
import Svg exposing (svg, line)
import Svg.Attributes exposing (xmlSpace, width, height, viewBox, fill, stroke, strokeWidth, strokeLinecap, strokeLinejoin, x1, x2, y1, y2)
import Views.Spinner exposing (spinner)


-- MODEL --


type alias Message =
    { type_ : MessageType
    , message : String
    }


type MessageType
    = Info
    | Warning
    | Error
    | Loading


type alias Model =
    { messages : Dict Int Message
    , nextKey : Int
    }


initModel : Model
initModel =
    { messages = Dict.empty
    , nextKey = 0
    }



-- VIEW --


{ id, class, classList } =
    messagesNamespace


view : List (Html.Attribute Msg) -> Model -> Html Msg
view attr model =
    Dict.toList model.messages
        |> List.reverse
        |> List.map messageView
        |> div (attr ++ [ id MessagesContainer ])


messageView : ( Int, Message ) -> Html Msg
messageView ( key, { message, type_ } ) =
    let
        closeIcon strokeColor =
            svg
                [ xmlSpace "http://www.w3.org/2000/svg"
                , width "20"
                , height "20"
                , viewBox "0 0 24 24"
                , fill "none"
                , stroke strokeColor
                , strokeWidth "2"
                , strokeLinecap "round"
                , strokeLinejoin "round"
                , onClick <| RemoveMessage key
                ]
                [ line [ x1 "18", y1 "6", x2 "6", y2 "18" ] []
                , line [ x1 "6", y1 "6", x2 "18", y2 "18" ] []
                ]

        ( msgClass, icon ) =
            case type_ of
                Info ->
                    InfoMessage => closeIcon "rgb(49, 114, 150)"

                Loading ->
                    LoadingMessage => spinner

                Warning ->
                    WarningMessage => closeIcon "rgb(138, 109, 59)"

                Error ->
                    ErrorMessage => closeIcon "rgb(132, 53, 52)"
    in
        div
            [ class [ msgClass ] ]
            [ div [] [ text message ]
            , icon
            ]



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE --


type Msg
    = AddMessage Message
    | RemoveMessage Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddMessage message ->
            { model
                | messages = Dict.insert model.nextKey message model.messages
                , nextKey = model.nextKey + 1
            }
                => Cmd.none

        RemoveMessage key ->
            { model | messages = Dict.remove key model.messages } => Cmd.none
