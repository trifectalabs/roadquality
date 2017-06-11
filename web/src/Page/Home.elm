module Page.Home exposing (view, subscriptions, update, Model, Msg, ExternalMsg(..), init)

import Dict exposing (Dict)
import OrderedDict as OrdDict exposing (OrderedDict)
import List.Extra exposing (elemIndex)
import Data.Map exposing (CycleRoute, Point, Segment, SurfaceType(..), PathType(..), encodePoint, decodeCycleRoute, decodeSegment, encodeCreateSegmentForm)
import Data.AuthToken exposing (AuthToken)
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
import Html.Attributes as Attr exposing (href, type_, value, target, placeholder, step, for, selected, src)
import Html.Events exposing (onClick, onInput)
import Stylesheets exposing (globalNamespace, mapNamespace, CssIds(..), CssClasses(..))
import Html.CssHelpers exposing (Namespace)
import Animation exposing (px)
import Util exposing ((=>), pair)
import Route


-- MODEL --


type alias Model =
    { errors : List String
    , menu : Menu
    , anchors : OrderedDict Int Point
    , cycleRoutes : OrderedDict String CycleRoute
    , segments : List Segment
    }


cycleRouteKey : Int -> Int -> String
cycleRouteKey first second =
    (toString first) ++ "_" ++ (toString second)


type MenuStep
    = NotStarted
    | NoAnchorsPlaced
    | OneAnchorPlaced
    | AddSurfaceRating
    | AddTrafficRating
    | AddTags
    | AddName


type alias Menu =
    { step : MenuStep
    , style : Animation.State
    , name : String
    , description : String
    , surfaceRating : Maybe Int
    , trafficRating : Maybe Int
    , surface : Maybe SurfaceType
    , pathType : Maybe PathType
    }


type alias Styles =
    { open : List Animation.Property
    , closed : List Animation.Property
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
    , anchors = OrdDict.empty
    , cycleRoutes = OrdDict.empty
    , segments = segments
    }


initMenu : Menu
initMenu =
    { step = NotStarted
    , style = Animation.style styles.closed
    , name = ""
    , description = ""
    , surfaceRating = Nothing
    , trafficRating = Nothing
    , surface = Just Asphalt
    , pathType = Just Shared
    }


styles : Styles
styles =
    { open =
        [ Animation.left (px 0.0) ]
    , closed =
        [ Animation.left (px -400.0) ]
    }



-- VIEW --


{ id, class, classList } =
    mapNamespace


g : Namespace String class id msg
g =
    globalNamespace


view : Session -> Model -> Html Msg
view session model =
    div []
        [ div [ id MainView ] []
        , div
            [ id AddRatingButton
            , g.class [ PrimaryButton ]
            , onClick ShowMenu
            ]
            [ text "Add Rating" ]
        , ratingsInterface session model.menu <| List.length model.anchors.order
        , accountView session
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
    div (Animation.render menu.style ++ [ id SaveRatingControl ]) <|
        case menu.step of
            NotStarted ->
                []

            NoAnchorsPlaced ->
                [ div []
                    [ span [ Attr.class "fa fa-times", onClick ClearAnchors ] []
                    , h3 [] [ text "Start by placing points on the map" ]
                    ]
                ]

            OneAnchorPlaced ->
                [ div []
                    [ span [ Attr.class "fa fa-times", onClick ClearAnchors ] []
                    , h3 [] [ text "Place more points to select a road" ]
                    ]
                ]

            AddSurfaceRating ->
                [ div []
                    [ span [ Attr.class "fa fa-times", onClick ClearAnchors ] []
                    , span
                        [ g.class [ PrimaryButton ]
                        , Attr.class "fa fa-arrow-right"
                        , case menu.surfaceRating of
                            Nothing ->
                                class [ Disabled ]

                            Just _ ->
                                onClick <| SetMenuStep AddTrafficRating
                        ]
                        []
                    , h2 [] [ text "Surface Rating" ]
                    , div
                        [ class [ SurfaceRatingMenu ] ]
                        [ div
                            [ onClick <| ChangeSurfaceRating <| Just 1
                            , classList
                                [ ( Active, menu.surfaceRating == Just 1 ) ]
                            ]
                            [ text "1" ]
                        , div
                            [ onClick <| ChangeSurfaceRating <| Just 2
                            , classList
                                [ ( Active, menu.surfaceRating == Just 2 ) ]
                            ]
                            [ text "2" ]
                        , div
                            [ onClick <| ChangeSurfaceRating <| Just 3
                            , classList
                                [ ( Active, menu.surfaceRating == Just 3 ) ]
                            ]
                            [ text "3" ]
                        , div
                            [ onClick <| ChangeSurfaceRating <| Just 4
                            , classList
                                [ ( Active, menu.surfaceRating == Just 4 ) ]
                            ]
                            [ text "4" ]
                        , div
                            [ onClick <| ChangeSurfaceRating <| Just 5
                            , classList
                                [ ( Active, menu.surfaceRating == Just 5 ) ]
                            ]
                            [ text "5" ]
                        ]
                    ]

                -- TODO: Add info about surface ratings
                ]

            AddTrafficRating ->
                [ div []
                    [ span [ Attr.class "fa fa-times", onClick ClearAnchors ] []
                    , div
                        [ Attr.class "fa fa-arrow-left"
                        , onClick <| SetMenuStep AddSurfaceRating
                        ]
                        []
                    , span
                        [ g.class [ PrimaryButton ]
                        , Attr.class "fa fa-arrow-right"
                        , case menu.trafficRating of
                            Nothing ->
                                class [ Disabled ]

                            Just _ ->
                                onClick <| SetMenuStep AddTags
                        ]
                        []
                    , h2 [] [ text "Traffic Rating" ]
                    , div
                        [ class [ TrafficRatingMenu ] ]
                        [ div
                            [ onClick <| ChangeTrafficRating <| Just 1
                            , classList
                                [ ( Active, menu.trafficRating == Just 1 ) ]
                            ]
                            [ text "1" ]
                        , div
                            [ onClick <| ChangeTrafficRating <| Just 2
                            , classList
                                [ ( Active, menu.trafficRating == Just 2 ) ]
                            ]
                            [ text "2" ]
                        , div
                            [ onClick <| ChangeTrafficRating <| Just 3
                            , classList
                                [ ( Active, menu.trafficRating == Just 3 ) ]
                            ]
                            [ text "3" ]
                        , div
                            [ onClick <| ChangeTrafficRating <| Just 4
                            , classList
                                [ ( Active, menu.trafficRating == Just 4 ) ]
                            ]
                            [ text "4" ]
                        , div
                            [ onClick <| ChangeTrafficRating <| Just 5
                            , classList
                                [ ( Active, menu.trafficRating == Just 5 ) ]
                            ]
                            [ text "5" ]
                        ]
                    ]

                -- TODO: Add info about traffic ratings
                ]

            AddTags ->
                [ div []
                    [ span [ Attr.class "fa fa-times", onClick ClearAnchors ] []
                    , div
                        [ Attr.class "fa fa-arrow-left"
                        , onClick <| SetMenuStep AddTrafficRating
                        ]
                        []
                    , span
                        [ g.class [ PrimaryButton ]
                        , Attr.class "fa fa-arrow-right"
                        , onClick <| SetMenuStep AddName
                        ]
                        []
                    , h2 [] [ text "Road Info" ]
                    , div
                        [ class [ SurfaceTypeMenu ] ]
                        [ h4 [] [ text "Surface Type" ]
                        , div
                            [ onClick <| ChangeSurfaceType <| Just Asphalt
                            , classList
                                [ ( Active, menu.surface == Just Asphalt ) ]
                            ]
                            [ text "Asphalt" ]
                        , div
                            [ onClick <| ChangeSurfaceType <| Just Gravel
                            , classList
                                [ ( Active, menu.surface == Just Gravel ) ]
                            ]
                            [ text "Gravel" ]
                        , div
                            [ onClick <| ChangeSurfaceType <| Just Dirt
                            , classList
                                [ ( Active, menu.surface == Just Dirt ) ]
                            ]
                            [ text "Dirt" ]
                        , div
                            [ onClick <| ChangeSurfaceType Nothing
                            , classList
                                [ ( Active, menu.surface == Nothing ) ]
                            ]
                            [ text "Unknown" ]
                        ]
                    , div
                        [ class [ PathTypeMenu ] ]
                        [ h4 [] [ text "Path Type" ]
                        , div
                            [ onClick <| ChangePathType <| Just Shared
                            , classList
                                [ ( Active, menu.pathType == Just Shared ) ]
                            ]
                            [ text "Shared Road" ]
                        , div
                            [ onClick <| ChangePathType <| Just DedicatedLane
                            , classList
                                [ ( Active, menu.pathType == Just DedicatedLane ) ]
                            ]
                            [ text "Bike Lane" ]
                        , div
                            [ onClick <| ChangePathType <| Just BikePath
                            , classList
                                [ ( Active, menu.pathType == Just BikePath ) ]
                            ]
                            [ text "Bike Path" ]
                        , div
                            [ onClick <| ChangePathType Nothing
                            , classList
                                [ ( Active, menu.pathType == Nothing ) ]
                            ]
                            [ text "Unknown" ]
                        ]
                    ]
                ]

            AddName ->
                [ div []
                    [ span [ Attr.class "fa fa-times", onClick ClearAnchors ] []
                    , div
                        [ Attr.class "fa fa-arrow-left"
                        , onClick <| SetMenuStep AddTags
                        ]
                        []
                    , span
                        [ g.class [ PrimaryButton ]
                        , Attr.class "fa fa-check"
                        , onClick SaveSegment
                        ]
                        []
                    , h2 [] [ text "Make Segment (Optional)" ]
                    , div
                        [ class [ SegmentNameInput ] ]
                        [ span [] [ text "Name" ]
                        , input
                            [ type_ "text", onInput ChangeName, value menu.name ]
                            []
                        ]
                    , div
                        [ class [ SegmentDescriptionInput ] ]
                        [ span [] [ text "Description" ]
                        , textarea
                            [ onInput ChangeDescription
                            , value menu.description
                            ]
                            []
                        ]
                    ]
                ]



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.removeAnchor RemoveAnchorPoint
        , Ports.setAnchor (DropAnchorPoint True)
        , Ports.moveAnchor (DropAnchorPoint False)
        , Animation.subscription AnimateMenu [ model.menu.style ]
        ]



-- UPDATE --


type Msg
    = DropAnchorPoint Bool ( Int, Float, Float )
    | NewAnchorPoint Int (Result Http.Error Point)
    | ChangeAnchorPoint Int (Result Http.Error Point)
    | RemoveAnchorPoint Int
    | ReceiveRoute String Int (Result Http.Error CycleRoute)
    | ClearAnchors
    | SetMenuStep MenuStep
    | ShowMenu
    | AnimateMenu Animation.Msg
    | ChangeName String
    | ChangeDescription String
    | ChangeSurfaceRating (Maybe Int)
    | ChangeTrafficRating (Maybe Int)
    | ChangePathType (Maybe PathType)
    | ChangeSurfaceType (Maybe SurfaceType)
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

        cycleRoutes =
            model.cycleRoutes

        menu =
            model.menu

        maybeAuthToken =
            session.user
                |> Maybe.map .token

        apiUrl =
            session.apiUrl

        authedAddRoute =
            addRoute apiUrl maybeAuthToken cycleRoutes
    in
        case msg of
            DropAnchorPoint new ( pointId, lat, lng ) ->
                let
                    anchorCount =
                        List.length anchors.order

                    newMenu =
                        if anchorCount == 0 then
                            { menu | step = OneAnchorPlaced }
                        else if anchorCount == 1 then
                            { menu | step = AddSurfaceRating }
                        else
                            menu

                    req =
                        snap apiUrl maybeAuthToken ( lat, lng )

                    handler =
                        if new == True then
                            NewAnchorPoint pointId
                        else
                            ChangeAnchorPoint pointId

                    cmd =
                        Http.send handler req
                in
                    { model | menu = newMenu } => cmd => NoOp

            NewAnchorPoint _ (Err error) ->
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
                        => externalMsg

            -- Scenario One
            ---------------
            -- Route between point and before
            ---------------------
            -- TODO: Scenario Two
            ---------------------
            -- Delete route added on
            -- Route between point and before
            -- Route between point and after
            NewAnchorPoint pointId (Ok point) ->
                let
                    newAnchors =
                        OrdDict.insert pointId point anchors

                    anchorCount =
                        List.length newAnchors.order

                    start =
                        newAnchors.order
                            |> List.drop (anchorCount - 2)
                            |> List.head

                    end =
                        newAnchors.order
                            |> List.drop (anchorCount - 1)
                            |> List.head

                    -- Route between point and before
                    addCmd =
                        Maybe.map2
                            (\s e ->
                                if s /= e then
                                    authedAddRoute newAnchors s e
                                else
                                    Cmd.none
                            )
                            start
                            end
                            |> Maybe.withDefault Cmd.none

                    cmd =
                        Cmd.batch
                            [ Ports.snapAnchor ( pointId, point )
                            , addCmd
                            ]
                in
                    { model | anchors = newAnchors } => cmd => NoOp

            ChangeAnchorPoint _ (Err error) ->
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
                    [ "There was a server error trying to move your point. Sorry!" ]
                        |> Util.appendErrors model
                        => Cmd.none
                        => externalMsg

            -- Scenario One
            ---------------
            -- Delete route before
            -- Route between point and before
            ---------------
            -- Scenario Two
            ---------------
            -- Delete route after
            -- Route between point and after
            -----------------
            -- Scenario Three
            -----------------
            -- Delete route before
            -- Delete route after
            -- Route between point and before
            -- Route between point and after
            ChangeAnchorPoint pointId (Ok point) ->
                let
                    newAnchors =
                        OrdDict.insert pointId point anchors

                    anchorIndex =
                        elemIndex pointId anchors.order
                            |> Maybe.withDefault -1

                    anchorCount =
                        List.length anchors.order

                    start =
                        anchors.order
                            |> List.drop (anchorIndex - 1)
                            |> List.head

                    end =
                        anchors.order
                            |> List.drop (anchorIndex + 1)
                            |> List.head

                    deleteBeforeCmd =
                        Maybe.map (\s -> removeRouteFromMap s pointId) start
                            |> Maybe.withDefault Cmd.none

                    addBeforeCmd =
                        Maybe.map
                            (\s -> authedAddRoute newAnchors s pointId)
                            start
                            |> Maybe.withDefault Cmd.none

                    deleteAfterCmd =
                        Maybe.map (\e -> removeRouteFromMap pointId e) end
                            |> Maybe.withDefault Cmd.none

                    addAfterCmd =
                        Maybe.map
                            (\e -> authedAddRoute newAnchors pointId e)
                            end
                            |> Maybe.withDefault Cmd.none

                    ( removedRoutes, deleteAddCmd ) =
                        -- Delete route before, Delete/Add route before cmd
                        if anchorIndex == (anchorCount - 1) then
                            ( Maybe.map
                                (\s -> removeRoute s pointId cycleRoutes)
                                start
                            , Cmd.batch [ deleteBeforeCmd, addBeforeCmd ]
                            )
                            -- Delete route after, Delete/Add route after cmd
                        else if anchorIndex == 0 then
                            ( Maybe.map
                                (\e -> removeRoute pointId e cycleRoutes)
                                end
                            , Cmd.batch [ deleteAfterCmd, addAfterCmd ]
                            )
                            -- Delete route before/after,
                            -- Delete/Add route before/after cmd
                        else
                            ( Maybe.map2
                                (\s e ->
                                    cycleRoutes
                                        |> removeRoute s pointId
                                        |> removeRoute e pointId
                                )
                                start
                                end
                            , Cmd.batch
                                [ deleteBeforeCmd
                                , deleteAfterCmd
                                , addBeforeCmd
                                , addAfterCmd
                                ]
                            )

                    cmd =
                        Cmd.batch
                            [ Ports.snapAnchor ( pointId, point )
                            , deleteAddCmd
                            ]

                    newCycleRoutes =
                        Maybe.withDefault cycleRoutes removedRoutes
                in
                    { model
                        | anchors = newAnchors
                        , cycleRoutes = newCycleRoutes
                    }
                        => cmd
                        => NoOp

            -- Scenario One
            ---------------
            -- Delete route before
            -- Delete route after
            -- Route between before and after
            ---------------
            -- Scenario Two
            ---------------
            -- Delete route before
            -----------------
            -- Scenario Three
            -----------------
            -- Cannot delete starting anchor
            RemoveAnchorPoint pointId ->
                let
                    anchorIndex =
                        elemIndex pointId anchors.order
                            |> Maybe.withDefault -1

                    anchorCount =
                        List.length anchors.order

                    start =
                        anchors.order
                            |> List.drop (anchorIndex - 1)
                            |> List.head

                    end =
                        anchors.order
                            |> List.drop (anchorIndex + 1)
                            |> List.head

                    routeIndex =
                        start
                            |> Maybe.map (\s -> cycleRouteKey s pointId)
                            |> Maybe.map (\r -> elemIndex r cycleRoutes.order)

                    -- Delete route before
                    beforeRemoved =
                        Maybe.map
                            (\s -> removeRoute s pointId cycleRoutes)
                            start

                    -- Delete route before cmd
                    removeFirstCmd =
                        Maybe.map (\s -> removeRouteFromMap s pointId) start
                            |> Maybe.withDefault Cmd.none

                    -- Delete route after,
                    -- Delete route after cmd,
                    -- Route between before and after cmd
                    ( afterRemoved, removeSecondCmd, addCmd ) =
                        if anchorIndex == (anchorCount - 1) then
                            ( beforeRemoved, Cmd.none, Cmd.none )
                        else
                            ( Maybe.map2
                                (\e routes -> removeRoute pointId e routes)
                                end
                                beforeRemoved
                            , Maybe.map
                                (\e -> removeRouteFromMap pointId e)
                                end
                                |> Maybe.withDefault Cmd.none
                            , Maybe.map2
                                (\s e -> authedAddRoute anchors s e)
                                start
                                end
                                |> Maybe.withDefault Cmd.none
                            )

                    newCycleRoutes =
                        Maybe.withDefault cycleRoutes afterRemoved

                    newAnchors =
                        OrdDict.remove pointId anchors

                    newMenu =
                        if anchorCount - 1 == 0 then
                            { menu | step = NoAnchorsPlaced }
                        else if anchorCount - 1 == 1 then
                            { menu | step = OneAnchorPlaced }
                        else
                            menu

                    cmd =
                        Cmd.batch
                            [ removeFirstCmd
                            , removeSecondCmd
                            , addCmd
                            ]
                in
                    { model
                        | anchors = newAnchors
                        , cycleRoutes = newCycleRoutes
                        , menu = newMenu
                    }
                        => cmd
                        => NoOp

            ReceiveRoute _ _ (Err error) ->
                let
                    default =
                        [ "There was a server error creating your route. Sorry!" ]

                    textErrors =
                        case error of
                            Http.BadStatus response ->
                                -- TODO: Display to user
                                -- Routing Failure
                                if response.status.code == 204 then
                                    default
                                else
                                    default

                            _ ->
                                default
                in
                    Util.appendErrors model textErrors => Cmd.none => NoOp

            ReceiveRoute key index (Ok route) ->
                let
                    line =
                        Polyline.decode route.polyline

                    newCycleRoutes =
                        OrdDict.insertAt index key route cycleRoutes
                in
                    { model | cycleRoutes = newCycleRoutes }
                        => Ports.displayRoute ( key, line )
                        => NoOp

            ClearAnchors ->
                { model
                    | anchors = OrdDict.empty
                    , cycleRoutes = OrdDict.empty
                    , menu =
                        { initMenu
                            | style =
                                Animation.interrupt
                                    [ Animation.to styles.closed ]
                                    menu.style
                        }
                }
                    => Ports.clearRoute ()
                    => NoOp

            SetMenuStep step ->
                let
                    newMenu =
                        { menu | step = step }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

            ShowMenu ->
                let
                    newMenu =
                        { menu
                            | style =
                                Animation.interrupt
                                    [ Animation.to styles.open ]
                                    menu.style
                            , step = NoAnchorsPlaced
                        }
                in
                    { model | menu = newMenu } => Ports.routeCreate () => NoOp

            AnimateMenu animMsg ->
                let
                    newMenu =
                        { menu | style = Animation.update animMsg menu.style }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

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
                    newMenu =
                        { menu | surfaceRating = rating }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

            ChangeTrafficRating rating ->
                let
                    newMenu =
                        { menu | trafficRating = rating }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

            ChangePathType pathType ->
                let
                    newMenu =
                        { menu | pathType = pathType }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

            ChangeSurfaceType surfaceType ->
                let
                    newMenu =
                        { menu | surface = surfaceType }
                in
                    { model | menu = newMenu } => Cmd.none => NoOp

            SaveSegment ->
                case
                    ( menu.surfaceRating
                    , menu.trafficRating
                    , menu.surface
                    , menu.pathType
                    )
                of
                    ( Just sRating, Just tRating, Just sType, Just pType ) ->
                        let
                            polylines =
                                model.cycleRoutes
                                    |> OrdDict.orderedValues
                                    |> List.map .polyline

                            createSegmentForm =
                                { name = menu.name
                                , description = menu.description
                                , polylines = polylines
                                , surfaceRating = sRating
                                , trafficRating = tRating
                                , surface = sType
                                , pathType = pType
                                }

                            req =
                                saveSegment
                                    apiUrl
                                    maybeAuthToken
                                    createSegmentForm

                            cmd =
                                Cmd.batch
                                    [ Http.send ReceiveSegment req
                                    , Ports.clearRoute ()
                                    ]
                        in
                            { model
                                | anchors = OrdDict.empty
                                , cycleRoutes = OrdDict.empty
                                , menu = initMenu
                            }
                                => cmd
                                => NoOp

                    _ ->
                        [ "There was a client error saving your segment. Sorry!" ]
                            |> Util.appendErrors model
                            => Cmd.none
                            => NoOp

            ReceiveSegment (Err error) ->
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
                    [ "There was a server error saving your segment. Sorry!" ]
                        |> Util.appendErrors model
                        => Cmd.none
                        => externalMsg

            ReceiveSegment (Ok segment) ->
                let
                    segments =
                        segment :: model.segments
                in
                    { model | segments = segments } => Cmd.none => NoOp


removeRoute : Int -> Int -> OrderedDict String CycleRoute -> OrderedDict String CycleRoute
removeRoute startPointId endPointId cycleRoutes =
    OrdDict.remove (cycleRouteKey startPointId endPointId) cycleRoutes


removeRouteFromMap : Int -> Int -> Cmd Msg
removeRouteFromMap startPointId endPointId =
    Ports.removeRoute <| cycleRouteKey startPointId endPointId


addRoute : String -> Maybe AuthToken -> OrderedDict String CycleRoute -> OrderedDict Int Point -> Int -> Int -> Cmd Msg
addRoute apiUrl maybeAuthToken cycleRoutes anchors startPointId endPointId =
    let
        routeKey =
            cycleRouteKey startPointId endPointId

        routeIndex =
            elemIndex routeKey cycleRoutes.order
                |> Maybe.withDefault (List.length cycleRoutes.order)

        points =
            [ startPointId, endPointId ]
                |> List.filterMap (\id -> Dict.get id anchors.dict)
    in
        Http.send
            (ReceiveRoute routeKey routeIndex)
            (makeRoute apiUrl maybeAuthToken points)
