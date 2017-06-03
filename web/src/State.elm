port module State exposing (..)

import Dict
import Http
import Json.Encode as Encode
import Navigation exposing (modifyUrl)
import Polyline
import Rest
    exposing
        ( decodePoint
        , encodePoint
        , decodeRoute
        , decodeSegment
        , encodeCreateSegmentForm
        , decodeUser
        )
import Types
    exposing
        ( Model
        , Point
        , Route
        , Segment
        , UrlRoute(..)
        , PathType(..)
        , SurfaceType(..)
        , User
        )
import UrlParser exposing (Parser, s, (<?>))


init : Navigation.Location -> ( Model, Cmd Msg )
init loc =
    let
        location =
            fixLocationQuery loc

        host =
            if location.host == "localhost:9000" then
                "http://localhost:9001"
            else
                "https://api.roadquality.org"

        initial =
            initModel host

        model =
            parseUrl initial location

        token =
            location
                |> UrlParser.parseHash
                    (s "dashboard" <?> UrlParser.stringParam "token")
                |> Maybe.withDefault Nothing

        cmd =
            case token of
                Nothing ->
                    getAuth ()

                Just token ->
                    let
                        req =
                            Http.request
                                { method = "GET"
                                , headers =
                                    [ Http.header "Authorization" <|
                                        String.concat [ "Bearer ", token ]
                                    ]
                                , url = String.concat [ model.host, "/users" ]
                                , body = Http.emptyBody
                                , expect = Http.expectJson decodeUser
                                , timeout = Nothing
                                , withCredentials = False
                                }

                        newUrl =
                            String.concat
                                [ location.origin
                                , location.pathname
                                , location.hash
                                ]
                    in
                        Cmd.batch
                            [ modifyUrl newUrl
                            , storeAuth token
                            , Http.send UserAuth req
                            ]
    in
        ( { model | token = token }, cmd )


initModel : String -> Model
initModel host =
    { anchors = Dict.empty
    , anchorOrder = []
    , route = Nothing
    , page = MainPage
    , host = host
    , menu = initMenu
    , user = Nothing
    , token = Nothing
    }


initMenu : Types.RatingsInterfaceState
initMenu =
    { drawingSegment = False
    , name = ""
    , description = ""
    , surfaceRating = 5
    , trafficRating = 5
    , surface = Asphalt
    , pathType = Shared
    }


type Msg
    = UrlChange Navigation.Location
    | CheckAuth (Maybe String)
    | UserAuth (Result Http.Error User)
    | PlaceAnchorPoint ( Int, Float, Float )
    | SetAnchorPoint Int (Result Http.Error Point)
    | ReceiveRoute (Result Http.Error Route)
    | ClearAnchors
    | ChangeName String
    | ChangeDescription String
    | ChangeSurfaceRating String
    | ChangeTrafficRating String
    | ChangePathType String
    | ChangeSurfaceType String
    | SaveSegment
    | ReceiveSegment (Result Http.Error Segment)


route : Parser (UrlRoute -> a) a
route =
    UrlParser.oneOf
        [ UrlParser.map MainPage UrlParser.top
        , UrlParser.map AccountPage (s "account")
        , UrlParser.map LoginPage (s "login")
        ]


{-| https://github.com/evancz/url-parser/issues/27
-}
fixLocationQuery : Navigation.Location -> Navigation.Location
fixLocationQuery location =
    let
        hash =
            String.split "?" location.hash
                |> List.head
                |> Maybe.withDefault ""

        search =
            String.split "?" location.hash
                |> List.drop 1
                |> String.join "?"
                |> String.append "?"
    in
        { location | hash = hash, search = search }


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
                    parseUrl model <| fixLocationQuery location
            in
                ( newModel, Cmd.none )

        CheckAuth token ->
            let
                headers =
                    token
                        |> Maybe.map
                            (\t ->
                                [ Http.header "Authorization" <|
                                    String.concat [ "Bearer ", t ]
                                ]
                            )
                        |> Maybe.withDefault []

                req =
                    Http.request
                        { method = "GET"
                        , headers = headers
                        , url = String.concat [ model.host, "/users" ]
                        , body = Http.emptyBody
                        , expect = Http.expectJson decodeUser
                        , timeout = Nothing
                        , withCredentials = False
                        }
            in
                ( { model | token = token }, Http.send UserAuth req )

        UserAuth (Err error) ->
            let
                newModel =
                    { model | page = LoginPage }
            in
                ( newModel, Cmd.none )

        UserAuth (Ok user) ->
            let
                newModel =
                    { model | page = MainPage, user = Just user }
            in
                ( newModel, up True )

        PlaceAnchorPoint ( pointId, lat, lng ) ->
            let
                oldMenu =
                    model.menu

                newMenu =
                    if oldMenu.drawingSegment then
                        oldMenu
                    else
                        { oldMenu | drawingSegment = True }

                headers =
                    model.token
                        |> Maybe.map
                            (\t ->
                                [ Http.header "Authorization" <|
                                    String.concat [ "Bearer ", t ]
                                ]
                            )
                        |> Maybe.withDefault []

                req =
                    Http.request
                        { method = "GET"
                        , headers = headers
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
                ( { model | menu = newMenu }
                , Http.send (SetAnchorPoint pointId) req
                )

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

                headers =
                    model.token
                        |> Maybe.map
                            (\t ->
                                [ Http.header "Authorization" <|
                                    String.concat [ "Bearer ", t ]
                                ]
                            )
                        |> Maybe.withDefault []

                req =
                    Http.request
                        { method = "POST"
                        , headers = headers
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
                , menu = initMenu
              }
            , clearRoute ()
            )

        ChangeName name ->
            let
                oldMenu =
                    model.menu

                newMenu =
                    { oldMenu | name = name }
            in
                ( { model | menu = newMenu }, Cmd.none )

        ChangeDescription description ->
            let
                oldMenu =
                    model.menu

                newMenu =
                    { oldMenu | description = description }
            in
                ( { model | menu = newMenu }, Cmd.none )

        ChangeSurfaceRating rating ->
            let
                r =
                    String.toInt rating
                        |> Result.withDefault model.menu.surfaceRating

                oldMenu =
                    model.menu

                newMenu =
                    { oldMenu | surfaceRating = r }
            in
                ( { model | menu = newMenu }, Cmd.none )

        ChangeTrafficRating rating ->
            let
                r =
                    String.toInt rating
                        |> Result.withDefault model.menu.trafficRating

                oldMenu =
                    model.menu

                newMenu =
                    { oldMenu | trafficRating = r }
            in
                ( { model | menu = newMenu }, Cmd.none )

        ChangePathType pathType ->
            let
                parsed =
                    case pathType of
                        "DedicatedLane" ->
                            DedicatedLane

                        "Shared" ->
                            Shared

                        "BikePath" ->
                            BikePath

                        _ ->
                            model.menu.pathType

                oldMenu =
                    model.menu

                newMenu =
                    { oldMenu | pathType = parsed }
            in
                ( { model | menu = newMenu }, Cmd.none )

        ChangeSurfaceType surfaceType ->
            let
                parsed =
                    case surfaceType of
                        "Asphalt" ->
                            Asphalt

                        "Dirt" ->
                            Dirt

                        "Gravel" ->
                            Gravel

                        _ ->
                            model.menu.surface

                oldMenu =
                    model.menu

                newMenu =
                    { oldMenu | surface = parsed }
            in
                ( { model | menu = newMenu }, Cmd.none )

        SaveSegment ->
            let
                points =
                    List.filterMap
                        (\id -> Dict.get id model.anchors)
                        model.anchorOrder

                body =
                    encodeCreateSegmentForm
                        { name = model.menu.name
                        , description = model.menu.description
                        , points = points
                        , surfaceRating = model.menu.surfaceRating
                        , trafficRating = model.menu.trafficRating
                        , surface = model.menu.surface
                        , pathType = model.menu.pathType
                        }

                headers =
                    model.token
                        |> Maybe.map
                            (\t ->
                                [ Http.header "Authorization" <|
                                    String.concat [ "Bearer ", t ]
                                ]
                            )
                        |> Maybe.withDefault []

                req =
                    Http.request
                        { method = "POST"
                        , headers = headers
                        , url = String.concat [ model.host, "/segments" ]
                        , body = Http.jsonBody body
                        , expect = Http.expectJson decodeSegment
                        , timeout = Nothing
                        , withCredentials = False
                        }

                cmd =
                    Cmd.batch
                        [ Http.send ReceiveSegment req
                        , clearRoute ()
                        ]
            in
                ( { model | menu = initMenu }, cmd )

        ReceiveSegment (Err error) ->
            ( model, Cmd.none )

        ReceiveSegment (Ok segment) ->
            ( model, Cmd.none )


port storeAuth : String -> Cmd msg


port getAuth : () -> Cmd msg


port checkAuth : (Maybe String -> msg) -> Sub msg


port up : Bool -> Cmd msg


port setAnchor : (( Int, Float, Float ) -> msg) -> Sub msg


port snapAnchor : ( Int, Point ) -> Cmd msg


port displayRoute : List ( Float, Float ) -> Cmd msg


port clearRoute : () -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ setAnchor PlaceAnchorPoint
        , checkAuth CheckAuth
        ]
