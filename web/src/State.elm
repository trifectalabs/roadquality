port module State exposing (..)

import Dict
import Http
import Json.Encode as Encode
import Navigation
import Polyline
import Rest exposing (decodePoint, encodePoint, decodeRoute, decodeSegment)
import Types exposing (Model, Point, Route, Segment, UrlRoute(..))
import UrlParser exposing (Parser, s)


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        host =
            if location.host == "localhost:9000" then
                "http://localhost:9001"
            else
                "https://api.roadquality.org"
    in
        ( { anchors = Dict.empty
          , anchorOrder = []
          , route = Nothing
          , rating = 5
          , page = MainPage
          , host = host
          }
        , up True
        )


type Msg
    = UrlChange Navigation.Location
    | PlaceAnchorPoint ( Int, Float, Float )
    | SetAnchorPoint Int (Result Http.Error Point)
    | ReceiveRoute (Result Http.Error Route)
    | ClearAnchors
    | ChangeRating String
    | SaveSegment
    | ReceiveSegment (Result Http.Error Segment)


route : Parser (UrlRoute -> a) a
route =
    UrlParser.oneOf
        [ UrlParser.map MainPage UrlParser.top
        , UrlParser.map AccountPage (s "account")
        , UrlParser.map LoginPage (s "login")
        ]


parseUrl : Model -> Navigation.Location -> Model
parseUrl model location =
    model


toUrl : UrlRoute -> String
toUrl route =
    case route of
        LoginPage ->
            "#/login"

        MainPage ->
            "#/"

        AccountPage ->
            "#/account"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            let
                newModel =
                    parseUrl model location
            in
                ( newModel, Cmd.none )

        PlaceAnchorPoint ( pointId, lat, lng ) ->
            let
                req =
                    Http.request
                        { method = "GET"
                        , headers = []
                        , url =
                            String.concat
                                [ model.host
                                , "/mapRoutes/snap?lat="
                                , toString lat
                                , "&lng="
                                , toString lng
                                ]
                        , body = Http.emptyBody
                        , expect = Http.expectJson decodePoint
                        , timeout = Nothing
                        , withCredentials = False
                        }
            in
                ( model, Http.send (SetAnchorPoint pointId) req )

        SetAnchorPoint _ (Err error) ->
            ( model, Cmd.none )

        SetAnchorPoint pointId (Ok point) ->
            let
                anchors =
                    Dict.insert pointId point model.anchors

                anchorOrder =
                    List.append model.anchorOrder [ pointId ]

                points =
                    anchorOrder
                        |> List.filterMap (\id -> Dict.get id anchors)
                        |> List.map encodePoint
                        |> Encode.list

                req =
                    Http.request
                        { method = "POST"
                        , headers = []
                        , url = String.concat [ model.host, "/mapRoutes" ]
                        , body = Http.jsonBody points
                        , expect = Http.expectJson decodeRoute
                        , timeout = Nothing
                        , withCredentials = False
                        }

                cmd =
                    Cmd.batch
                        [ snapAnchor ( pointId, point )
                        , Http.send ReceiveRoute req
                        ]
            in
                ( { model | anchors = anchors, anchorOrder = anchorOrder }
                , cmd
                )

        ReceiveRoute (Err error) ->
            ( model, Cmd.none )

        ReceiveRoute (Ok route) ->
            let
                line =
                    Polyline.decode route.polyline
            in
                ( { model | route = Just route }, displayRoute line )

        ClearAnchors ->
            ( { model
                | anchors = Dict.empty
                , anchorOrder = []
                , route = Nothing
              }
            , clearRoute ()
            )

        ChangeRating rating ->
            let
                r =
                    String.toInt rating
                        |> Result.withDefault model.rating
            in
                ( { model | rating = r }, Cmd.none )

        SaveSegment ->
            let
                points =
                    model.anchorOrder
                        |> List.filterMap (\id -> Dict.get id model.anchors)
                        |> List.map encodePoint

                body =
                    Encode.object
                        [ ( "points", Encode.list points )
                        , ( "rating", Encode.int model.rating )
                        ]

                req =
                    Http.request
                        { method = "POST"
                        , headers = []
                        , url = String.concat [ model.host, "/segments" ]
                        , body = Http.jsonBody body
                        , expect = Http.expectJson decodeSegment
                        , timeout = Nothing
                        , withCredentials = False
                        }

                cmd =
                    Http.send ReceiveSegment req
            in
                ( model, cmd )

        ReceiveSegment (Err error) ->
            ( model, Cmd.none )

        ReceiveSegment (Ok segment) ->
            ( model, Cmd.none )


port up : Bool -> Cmd msg


port setAnchor : (( Int, Float, Float ) -> msg) -> Sub msg


port snapAnchor : ( Int, Point ) -> Cmd msg


port displayRoute : List ( Float, Float ) -> Cmd msg


port clearRoute : () -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ setAnchor PlaceAnchorPoint
        ]
