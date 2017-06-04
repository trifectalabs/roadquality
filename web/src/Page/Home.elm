module Page.Home exposing (view, subscriptions, update, Model, Msg, ExternalMsg(..), init)

import Dict exposing (Dict)
import Data.Map exposing (CycleRoute, Point, Segment, SurfaceType(..), PathType(..), encodePoint, decodeCycleRoute, decodeSegment, encodeCreateSegmentForm)
import Data.Session as Session exposing (Session)
import Data.UserPhoto as UserPhoto
import Request.Map exposing (snap, makeRoute, saveSegment)
import Ports
import Http
import Task exposing (Task)
import Views.Page as Page
import Page.Errored as Errored exposing (PageLoadError, pageLoadError)
import Polyline
import Html exposing (..)
import Html.Attributes exposing (href, type_, value, target, placeholder, step, for, selected, src)
import Html.Events exposing (onClick, onInput)
import Stylesheets exposing (mapNamespace, CssIds(..), CssClasses(..))
import Util exposing ((=>))
import Route


-- MODEL --


type alias Model =
    { errors : List String
    , menu : Menu
    , anchors : Dict Int Point
    , anchorOrder : List Int
    , cycleRoute : Maybe CycleRoute
    , segments : List Segment
    }


type alias Menu =
    { drawingSegment : Bool
    , name : String
    , description : String
    , surfaceRating : Int
    , trafficRating : Int
    , surface : SurfaceType
    , pathType : PathType
    }


init : Session -> Task PageLoadError Model
init session =
    let
        maybeAuthToken =
            session.user
                |> Maybe.map .token

        loadSegments =
            Request.Map.getSegments session.apiUrl maybeAuthToken
                |> Http.toTask

        handleLoadError _ =
            pageLoadError Page.Home "Homepage is currently unavailable."
    in
        Task.map initModel loadSegments
            |> Task.mapError handleLoadError


initModel : List Segment -> Model
initModel segments =
    { errors = []
    , menu = initMenu
    , anchors = Dict.empty
    , anchorOrder = []
    , cycleRoute = Nothing
    , segments = segments
    }


initMenu : Menu
initMenu =
    { drawingSegment = False
    , name = ""
    , description = ""
    , surfaceRating = 5
    , trafficRating = 5
    , surface = Asphalt
    , pathType = Shared
    }



-- VIEW --


{ id, class, classList } =
    mapNamespace


view : Session -> Model -> Html Msg
view session model =
    div []
        [ div [ id MainView ] []
        , ratingsInterface session model.menu <| List.length model.anchorOrder
        , accountView session
        , div [ id TrifectaAffiliate ]
            [ a [ href "https://trifectalabs.com" ]
                [ img [ src "/assets/img/trifecta_mountains.png" ] []
                , span [] [ text "Trifecta Labs" ]
                ]
            ]
        ]


accountView : Session -> Html Msg
accountView session =
    case session.user of
        Nothing ->
            a
                [ Route.href Route.Login ]
                [ div [ class [ GoToAccount ] ] [ text "Sign In" ] ]

        Just user ->
            a
                [ Route.href Route.Account ]
                [ img [ UserPhoto.src user.photo, class [ GoToAccount ] ] [] ]


ratingsInterface : Session -> Menu -> Int -> Html Msg
ratingsInterface session menu anchorCount =
    if session.user == Nothing then
        div [ id SaveRatingControl ]
            [ div [] [ text "Login to make a rating" ] ]
    else if not menu.drawingSegment then
        div [ id SaveRatingControl ]
            [ div [] [ text "Click the map to make a rating" ] ]
    else if anchorCount < 2 then
        div [ id SaveRatingControl ]
            [ div [] [ text "Place another anchor to make a rating" ] ]
    else
        div [ id SaveRatingControl, class [ DrawingSegment ] ]
            [ div [] [ text "Make a Rating" ]
              -- TODO: add segments
              -- , label [ for "mapNameInput" ] [ text "Name" ]
              -- , input
              --     [ type_ "text"
              --     , value menu.name
              --     , onInput ChangeName
              --     , placeholder "Name me!"
              --     , id NameInput
              --     , class [ MenuInput ]
              --     ]
              --     []
              -- , label [ for "mapDescriptionInput" ] [ text "Description" ]
              -- , textarea
              --     [ value menu.description
              --     , onInput ChangeDescription
              --     , placeholder "Give some deets"
              --     , id DescriptionInput
              --     , class [ MenuInput ]
              --     ]
              --     []
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



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.setAnchor PlaceAnchorPoint



-- UPDATE --


type Msg
    = PlaceAnchorPoint ( Int, Float, Float )
    | SetAnchorPoint Int (Result Http.Error Point)
    | ReceiveRoute (Result Http.Error CycleRoute)
    | ClearAnchors
    | ChangeName String
    | ChangeDescription String
    | ChangeSurfaceRating String
    | ChangeTrafficRating String
    | ChangePathType String
    | ChangeSurfaceType String
    | SaveSegment
    | ReceiveSegment (Result Http.Error Segment)


type ExternalMsg
    = NoOp
    | Unauthorized


update : Session -> Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update session msg model =
    let
        anchors =
            model.anchors

        anchorOrder =
            model.anchorOrder

        cycleRoute =
            model.cycleRoute

        menu =
            model.menu

        token =
            session.user
                |> Maybe.map .token

        apiUrl =
            session.apiUrl
    in
        case msg of
            PlaceAnchorPoint ( pointId, lat, lng ) ->
                let
                    newMenu =
                        { menu | drawingSegment = True }

                    req =
                        snap apiUrl token ( lat, lng )

                    cmd =
                        Http.send (SetAnchorPoint pointId) req
                in
                    { model | menu = newMenu } => cmd => NoOp

            SetAnchorPoint _ (Err error) ->
                let
                    externalMsg =
                        case error of
                            Http.BadStatus response ->
                                if response.status.code == 401 then
                                    Unauthorized
                                else
                                    NoOp

                            _ ->
                                NoOp
                in
                    [ "There was a server error trying to place your point. Sorry!" ]
                        |> Util.appendErrors model
                        => Cmd.none
                        => NoOp

            SetAnchorPoint pointId (Ok point) ->
                let
                    newAnchors =
                        Dict.insert pointId point anchors

                    newAnchorOrder =
                        List.append anchorOrder [ pointId ]

                    points =
                        List.filterMap
                            (\id -> Dict.get id newAnchors)
                            newAnchorOrder

                    req =
                        makeRoute apiUrl token points

                    cmd =
                        Cmd.batch
                            [ Ports.snapAnchor ( pointId, point )
                            , Http.send ReceiveRoute req
                            ]
                in
                    { model
                        | anchors = newAnchors
                        , anchorOrder = newAnchorOrder
                    }
                        => cmd
                        => NoOp

            ReceiveRoute (Err error) ->
                [ "There was a server error creating your route. Sorry!" ]
                    |> Util.appendErrors model
                    => Cmd.none
                    => NoOp

            ReceiveRoute (Ok route) ->
                let
                    line =
                        Polyline.decode route.polyline
                in
                    { model | cycleRoute = Just route }
                        => Ports.displayRoute line
                        => NoOp

            ClearAnchors ->
                { model
                    | anchors = Dict.empty
                    , anchorOrder = []
                    , cycleRoute = Nothing
                    , menu = initMenu
                }
                    => Ports.clearRoute ()
                    => NoOp

            ChangeName name ->
                let
                    newMenu =
                        { menu | name = name }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

            ChangeDescription description ->
                let
                    newMenu =
                        { menu | description = description }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

            ChangeSurfaceRating rating ->
                let
                    r =
                        String.toInt rating
                            |> Result.withDefault menu.surfaceRating

                    newMenu =
                        { menu | surfaceRating = r }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

            ChangeTrafficRating rating ->
                let
                    r =
                        String.toInt rating
                            |> Result.withDefault menu.trafficRating

                    newMenu =
                        { menu | trafficRating = r }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

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
                                menu.pathType

                    newMenu =
                        { menu | pathType = parsed }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

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
                                menu.surface

                    newMenu =
                        { menu | surface = parsed }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

            SaveSegment ->
                let
                    polyline =
                        model.cycleRoute
                            |> Maybe.map .polyline
                            |> Maybe.withDefault ""

                    createSegmentForm =
                        { name = menu.name
                        , description = menu.description
                        , polyline = polyline
                        , surfaceRating = menu.surfaceRating
                        , trafficRating = menu.trafficRating
                        , surface = menu.surface
                        , pathType = menu.pathType
                        }

                    req =
                        saveSegment apiUrl token createSegmentForm

                    cmd =
                        Cmd.batch
                            [ Http.send ReceiveSegment req
                            , Ports.clearRoute ()
                            ]
                in
                    { model | menu = initMenu } => cmd => NoOp

            ReceiveSegment (Err error) ->
                [ "There was a server error saving your segment. Sorry!" ]
                    |> Util.appendErrors model
                    => Cmd.none
                    => NoOp

            ReceiveSegment (Ok segment) ->
                let
                    segments =
                        segment :: model.segments
                in
                    { model | segments = segments } => Cmd.none => NoOp
