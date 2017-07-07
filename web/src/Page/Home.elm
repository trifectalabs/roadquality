module Page.Home exposing (view, subscriptions, update, Model, Msg, ExternalMsg(..), init)

import Dict exposing (Dict)
import OrderedDict as OrdDict exposing (OrderedDict)
import List.Extra exposing (elemIndex)
import Data.Map exposing (MapLayer(..), CycleRoute, Point, Segment, SurfaceType(..), PathType(..), encodePoint, decodeCycleRoute, decodeSegment, encodeCreateSegmentForm)
import Data.AuthToken exposing (AuthToken)
import Data.Session as Session exposing (Session)
import Data.UserPhoto as UserPhoto
import Request.Map exposing (snap, makeRoute, saveSegment)
import Request.User exposing (emailListSignUp)
import Ports
import Http
import Task exposing (Task)
import Views.Page as Page
import Page.Errored as Errored exposing (PageLoadError, pageLoadError)
import Polyline
import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (type_, value)
import Stylesheets exposing (globalNamespace, mapNamespace, CssIds(..), CssClasses(..))
import Html.CssHelpers exposing (Namespace)
import Util exposing ((=>), pair)
import Route
import Views.Assets as Assets
import Page.Home.RatingsMenu as Menu
import Animation exposing (px)
import Views.Messages as Messages exposing (Msg(..))
import Fifo exposing (Fifo)
import Random exposing (Seed)
import Random.String exposing (string)
import Random.Char exposing (english)
import Time exposing (Time)
import Json.Encode as Encode


-- MODEL --


type alias Model =
    { errors : Messages.Model
    , listEmail : String
    , menu : Menu.Model
    , mapLayer : MapLayer
    , zoom : Float
    , switchStyle : Animation.State
    , errorsStyle : Animation.State
    , anchors : OrderedDict String Point
    , cycleRoutes : OrderedDict String CycleRoute
    , mapRouteKeys : Dict String String
    , segments : List Segment
    , startAnchorUnused : Bool
    , unusedAnchors : Fifo String
    , unusedRoutes : Fifo String
    , keySeed : Seed
    }


type alias Styles =
    { switchOpen : List Animation.Property
    , closed : List Animation.Property
    , msgOpen : List Animation.Property
    }


cycleRouteKey : String -> String -> String
cycleRouteKey first second =
    first ++ "_" ++ second


init : Session -> Task PageLoadError Model
init session =
    let
        maybeAuthToken =
            session.user
                |> Maybe.map .token

        zoomLevel =
            case session.user of
                Nothing ->
                    4.0

                Just _ ->
                    11.0

        handleLoadError _ =
            pageLoadError Page.Home "Homepage is currently unavailable."
    in
        Task.map (initModel zoomLevel) Time.now
            |> Task.mapError handleLoadError


initModel : Float -> Time -> Model
initModel zoom now =
    { errors = Messages.initModel
    , listEmail = ""
    , menu = Menu.initModel
    , mapLayer = SurfaceQuality
    , zoom = zoom
    , switchStyle = Animation.style styles.closed
    , errorsStyle = Animation.style styles.closed
    , anchors = OrdDict.empty
    , cycleRoutes = OrdDict.empty
    , mapRouteKeys = Dict.empty
    , segments = []
    , startAnchorUnused = False
    , unusedAnchors = Fifo.empty
    , unusedRoutes = Fifo.empty
    , keySeed = Random.initialSeed <| round now
    }


styles : Styles
styles =
    { switchOpen =
        [ Animation.paddingLeft (px 400.0) ]
    , closed =
        [ Animation.paddingLeft (px 0.0) ]
    , msgOpen =
        [ Animation.paddingLeft (px 200.0) ]
    }



-- VIEW --


{ id, class, classList } =
    mapNamespace


g : Namespace String class id msg
g =
    globalNamespace


view : Session -> Model -> Html Msg
view session model =
    let
        addRatingCmd =
            case session.user of
                Nothing ->
                    ShowLogin

                Just _ ->
                    MenuMsg Menu.ShowMenu

        legend =
            case model.mapLayer of
                SurfaceQuality ->
                    img [ id MapLegend, Assets.src Assets.surfaceQuality ] []

                TrafficSafety ->
                    img [ id MapLegend, Assets.src Assets.trafficSafety ] []

                _ ->
                    img [] []
    in
        div []
            [ div [ id MainView ] []
            , div
                [ g.class [ PrimaryButton ]
                , id AddRatingButton
                , onClick addRatingCmd
                ]
                [ text "Add Rating" ]
            , Messages.view (Animation.render model.errorsStyle) model.errors
                |> Html.map ErrorMsg
            , legend
            , div
                (Animation.render model.switchStyle ++ [ id MapSwitcher ])
                [ div []
                    [ div
                        [ g.classList
                            [ ( PrimaryButton, model.mapLayer == SurfaceQuality )
                            , ( SecondaryButton, model.mapLayer /= SurfaceQuality )
                            ]
                        , onClick <| SetLayer SurfaceQuality
                        ]
                        [ text "Surface Quality" ]
                    , div
                        [ g.classList
                            [ ( PrimaryButton, model.mapLayer == TrafficSafety )
                            , ( SecondaryButton, model.mapLayer /= TrafficSafety )
                            ]
                        , onClick <| SetLayer TrafficSafety
                        ]
                        [ text "Traffic Safety" ]
                    ]
                ]
            , Menu.view model.menu |> Html.map MenuMsg
            , accountView session
            , signUpBanner model.listEmail (session.user == Nothing)
            ]


accountView : Session -> Html Msg
accountView session =
    case session.user of
        Nothing ->
            a
                [ Route.href Route.Login ]
                [ div
                    [ class [ GoToAccount ]
                    , g.class [ SecondaryButton ]
                    ]
                    [ text "Sign In" ]
                ]

        Just user ->
            a
                [ Route.href Route.Account ]
                [ img [ UserPhoto.src user.photo, class [ GoToAccount ] ] [] ]


signUpBanner : String -> Bool -> Html Msg
signUpBanner email showBanner =
    if showBanner == True then
        div [ id EmailListBanner ]
            [ div []
                [ span [] [ text "Want access to Road Quality? Add your email here and we will let you know when we're adding more users!" ]
                , input [ type_ "text", onInput ChangeEmailList, value email ] []
                , div [ g.class [ SecondaryButton ], onClick EmailListSignup ] [ text "Let me know!" ]
                ]
            ]
    else
        span [] []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.removedAnchor RemoveAnchorPoint
        , Ports.setAnchor DropAnchorPoint
        , Ports.movedAnchor MoveAnchorPoint
        , Ports.zoomLevel ZoomLevel
        , Ports.loadSegments LoadSegments
        , Menu.subscriptions model.menu |> Sub.map MenuMsg
        , Animation.subscription AnimateSwitcher [ model.switchStyle ]
        , Animation.subscription AnimateErrors [ model.errorsStyle ]
        , Messages.subscriptions model.errors |> Sub.map ErrorMsg
        ]



-- UPDATE --


type Msg
    = ErrorMsg Messages.Msg
    | SetLayer MapLayer
    | ZoomLevel Float
    | ShowLogin
    | ChangeEmailList String
    | EmailListSignup
    | EmailListSignupResult (Result Http.Error String)
    | AnimateSwitcher Animation.Msg
    | AnimateErrors Animation.Msg
    | DropAnchorPoint ( Float, Float )
    | MoveAnchorPoint ( String, Float, Float )
    | NewAnchorPoint String (Result Http.Error Point)
    | ChangeAnchorPoint String (Result Http.Error Point)
    | RemoveAnchorPoint String
    | ReceiveRoute String String Int (Result Http.Error CycleRoute)
    | MenuMsg Menu.Msg
    | ReceiveSegment Int (Result Http.Error Segment)
    | LoadSegments ( Point, Point )
    | ReceiveSegments (Result Http.Error (List Segment))


type ExternalMsg
    = NoOp
    | Unauthorized


update : Session -> Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update session msg model =
    let
        errors =
            model.errors

        anchors =
            model.anchors

        cycleRoutes =
            model.cycleRoutes

        mapRouteKeys =
            model.mapRouteKeys

        startAnchorUnused =
            model.startAnchorUnused

        unusedAnchors =
            model.unusedAnchors

        unusedRoutes =
            model.unusedRoutes

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
            ErrorMsg subMsg ->
                let
                    ( newErrors, errorCmd ) =
                        Messages.update subMsg errors
                in
                    { model | errors = newErrors }
                        => Cmd.map ErrorMsg errorCmd
                        => NoOp

            SetLayer layer ->
                let
                    stringLayer =
                        case layer of
                            PlainMap ->
                                "PlainMap"

                            SurfaceQuality ->
                                "SurfaceQuality"

                            TrafficSafety ->
                                "TrafficSafety"

                            SegmentsView ->
                                "SegmentsView"
                in
                    { model | mapLayer = layer }
                        => Ports.setLayer stringLayer
                        => NoOp

            ZoomLevel zoom ->
                { model | zoom = zoom } => Cmd.none => NoOp

            ShowLogin ->
                model => Cmd.none => Unauthorized

            ChangeEmailList email ->
                { model | listEmail = email } => Cmd.none => NoOp

            EmailListSignup ->
                model
                    => Http.send
                        EmailListSignupResult
                        (emailListSignUp "https://roadquality.org" model.listEmail)
                    => NoOp

            EmailListSignupResult (Err error) ->
                let
                    errorMsg =
                        { message = "Email list sign up failed"
                        , type_ = Messages.Error
                        }

                    ( newErrors, errorCmd ) =
                        Messages.update (AddMessage errorMsg) errors
                in
                    { model | errors = newErrors }
                        => Cmd.map ErrorMsg errorCmd
                        => NoOp

            EmailListSignupResult (Ok response) ->
                let
                    errorMsg =
                        { message = "We'll let you know when you can sign up!"
                        , type_ = Messages.Info
                        }

                    ( newErrors, errorCmd ) =
                        Messages.update (AddMessage errorMsg) errors
                in
                    { model | errors = newErrors }
                        => Cmd.map ErrorMsg errorCmd
                        => NoOp

            AnimateSwitcher animMsg ->
                { model
                    | switchStyle = Animation.update animMsg model.switchStyle
                }
                    => Cmd.none
                    => NoOp

            AnimateErrors animMsg ->
                { model
                    | errorsStyle = Animation.update animMsg model.errorsStyle
                }
                    => Cmd.none
                    => NoOp

            DropAnchorPoint ( lng, lat ) ->
                let
                    newMenu =
                        Menu.anchorCountUpdate (List.length anchors.order + 1) menu

                    ( ( ( pointId, nextSeed ), newUnusedAnchors ), nextStartAnchor ) =
                        if (startAnchorUnused == True) then
                            "startMarker" => model.keySeed => unusedAnchors => False
                        else if (List.length <| Fifo.toList unusedAnchors) > 0 then
                            Fifo.remove unusedAnchors
                                |> (\( maybeKey, nextUnused ) ->
                                        case maybeKey of
                                            Nothing ->
                                                generateNewKey model.keySeed => nextUnused => startAnchorUnused

                                            Just key ->
                                                key => model.keySeed => nextUnused => startAnchorUnused
                                   )
                        else if List.length anchors.order == 0 then
                            "startMarker" => model.keySeed => unusedAnchors => startAnchorUnused
                        else
                            generateNewKey model.keySeed => unusedAnchors => startAnchorUnused

                    req =
                        snap apiUrl maybeAuthToken ( lat, lng )

                    paint =
                        if pointId == "startMarker" then
                            Encode.object
                                [ "circle-radius" => Encode.int 7
                                , "circle-color" => Encode.string "#40B34F"
                                , "circle-stroke-color" => Encode.string "#FFFFFF"
                                , "circle-stroke-width" => Encode.int 2
                                ]
                        else
                            Encode.object
                                [ "circle-radius" => Encode.int 4
                                , "circle-color" => Encode.string "#FFFFFF"
                                , "circle-stroke-width" => Encode.int 2
                                ]

                    cmd =
                        Cmd.batch
                            [ Http.send (NewAnchorPoint pointId) req
                            , Ports.addSource
                                ( pointId
                                , Just "circle"
                                , Just paint
                                , [ ( lng, lat ) ]
                                )
                            ]

                    currentAnchor =
                        Dict.get pointId anchors.dict
                            -- Impossible Values
                            |> Maybe.withDefault { lat = 1000.0, lng = 1000.0 }
                in
                    if
                        ((abs <| currentAnchor.lat - lat) < 0.0001)
                            && ((abs <| currentAnchor.lng - lng) < 0.0001)
                    then
                        model => Cmd.none => NoOp
                    else
                        { model
                            | startAnchorUnused = nextStartAnchor
                            , unusedAnchors = newUnusedAnchors
                            , keySeed = nextSeed
                            , menu = newMenu
                        }
                            => cmd
                            => NoOp

            MoveAnchorPoint ( pointId, lng, lat ) ->
                let
                    newMenu =
                        Menu.anchorCountUpdate (List.length anchors.order) menu

                    req =
                        snap apiUrl maybeAuthToken ( lat, lng )

                    cmd =
                        Http.send (ChangeAnchorPoint pointId) req

                    currentAnchor =
                        Dict.get pointId anchors.dict
                            -- Impossible Values
                            |> Maybe.withDefault { lat = 1000.0, lng = 1000.0 }
                in
                    if
                        ((abs <| currentAnchor.lat - lat) < 0.0001)
                            && ((abs <| currentAnchor.lng - lng) < 0.0001)
                    then
                        model => Cmd.none => NoOp
                    else
                        { model | menu = newMenu } => cmd => NoOp

            NewAnchorPoint pointId (Err error) ->
                let
                    responseCode =
                        case error of
                            Http.BadPayload _ response ->
                                response.status.code

                            Http.BadStatus response ->
                                response.status.code

                            _ ->
                                0

                    ( externalMsg, errorMsg ) =
                        if responseCode == 401 then
                            Unauthorized
                                => { type_ = Messages.Error
                                   , message = "You must login to place a point. Sorry!"
                                   }
                        else if responseCode == 204 then
                            NoOp
                                => { type_ = Messages.Error
                                   , message = "You're trying to place a point outside the currently supported area. Whoops!"
                                   }
                        else
                            NoOp
                                => { type_ = Messages.Error
                                   , message = "There was a server error trying to place your point. Sorry!"
                                   }

                    ( newErrors, errorCmd ) =
                        Messages.update (AddMessage errorMsg) errors

                    cmd =
                        Cmd.batch
                            [ Ports.hideSources [ pointId ]
                            , Cmd.map ErrorMsg errorCmd
                            ]
                in
                    { model | errors = newErrors }
                        => cmd
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
                            [ Ports.addSource
                                ( pointId
                                , Nothing
                                , Nothing
                                , [ ( point.lng, point.lat ) ]
                                )
                            , addCmd
                            ]
                in
                    { model | anchors = newAnchors } => cmd => NoOp

            ChangeAnchorPoint pointId (Err error) ->
                let
                    responseCode =
                        case error of
                            Http.BadPayload _ response ->
                                response.status.code

                            Http.BadStatus response ->
                                response.status.code

                            _ ->
                                0

                    ( externalMsg, errorMsg ) =
                        if responseCode == 401 then
                            Unauthorized
                                => { type_ = Messages.Error
                                   , message = "You must login to move a point. Sorry!"
                                   }
                        else if responseCode == 204 then
                            NoOp
                                => { type_ = Messages.Error
                                   , message = "You're trying to move a point outside the currently supported area. Whoops!"
                                   }
                        else
                            NoOp
                                => { type_ = Messages.Error
                                   , message = "There was a server error trying to move your point. Sorry!"
                                   }

                    ( newErrors, errorCmd ) =
                        Messages.update (AddMessage errorMsg) errors

                    cmd =
                        Cmd.batch
                            [ Ports.hideSources [ pointId ]
                            , Cmd.map ErrorMsg errorCmd
                            ]
                in
                    { model | errors = newErrors }
                        => cmd
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
                        Maybe.map (\s -> removeRouteFromMap mapRouteKeys s pointId) start
                            |> Maybe.withDefault Cmd.none

                    addBeforeCmd =
                        Maybe.map
                            (\s -> authedAddRoute newAnchors s pointId)
                            start
                            |> Maybe.withDefault Cmd.none

                    deleteAfterCmd =
                        Maybe.map (\e -> removeRouteFromMap mapRouteKeys pointId e) end
                            |> Maybe.withDefault Cmd.none

                    addAfterCmd =
                        Maybe.map
                            (\e -> authedAddRoute newAnchors pointId e)
                            end
                            |> Maybe.withDefault Cmd.none

                    ( removedRoutes, removedRoutesMap, deleteAddCmd ) =
                        -- Moving first anchor with no routes, do nothing
                        if anchorIndex == 0 && anchorCount == 1 then
                            ( Just cycleRoutes, Just ( unusedRoutes, mapRouteKeys ), Cmd.none )
                            -- Delete route before, Delete/Add route before cmd
                        else if anchorIndex == (anchorCount - 1) then
                            ( Maybe.map
                                (\s -> removeRoute s pointId cycleRoutes)
                                start
                            , Maybe.map
                                (\s -> removeRouteMap s pointId ( unusedRoutes, mapRouteKeys ))
                                start
                            , Cmd.batch [ deleteBeforeCmd, addBeforeCmd ]
                            )
                            -- Delete route after, Delete/Add route after cmd
                        else if anchorIndex == 0 then
                            ( Maybe.map
                                (\e -> removeRoute pointId e cycleRoutes)
                                end
                            , Maybe.map
                                (\e -> removeRouteMap pointId e ( unusedRoutes, mapRouteKeys ))
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
                                        |> removeRoute pointId e
                                )
                                start
                                end
                            , Maybe.map2
                                (\s e ->
                                    ( unusedRoutes, mapRouteKeys )
                                        |> removeRouteMap s pointId
                                        |> removeRouteMap pointId e
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
                            [ Ports.addSource
                                ( pointId
                                , Nothing
                                , Nothing
                                , [ ( point.lng, point.lat ) ]
                                )
                            , deleteAddCmd
                            ]

                    newCycleRoutes =
                        Maybe.withDefault cycleRoutes removedRoutes

                    ( newUnusedRoutes, newMapRouteKeys ) =
                        Maybe.withDefault ( unusedRoutes, mapRouteKeys ) removedRoutesMap
                in
                    { model
                        | anchors = newAnchors
                        , cycleRoutes = newCycleRoutes
                        , mapRouteKeys = newMapRouteKeys
                        , unusedRoutes = newUnusedRoutes
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

                    beforeRemovedMap =
                        Maybe.map
                            (\s -> removeRouteMap s pointId ( unusedRoutes, mapRouteKeys ))
                            start

                    -- Delete route before cmd
                    removeFirstCmd =
                        Maybe.map (\s -> removeRouteFromMap mapRouteKeys s pointId) start
                            |> Maybe.withDefault Cmd.none

                    -- Delete route after,
                    -- Delete route after cmd,
                    -- Route between before and after cmd
                    ( afterRemoved, afterRemovedMap, removeSecondCmd, addCmd ) =
                        if anchorIndex == (anchorCount - 1) then
                            ( beforeRemoved, beforeRemovedMap, Cmd.none, Cmd.none )
                        else
                            ( Maybe.map2
                                (\e routes -> removeRoute pointId e routes)
                                end
                                beforeRemoved
                            , Maybe.map2
                                (\e routes -> removeRouteMap pointId e routes)
                                end
                                beforeRemovedMap
                            , Maybe.map
                                (\e -> removeRouteFromMap mapRouteKeys pointId e)
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

                    ( newUnusedRoutes, newMapRouteKeys ) =
                        Maybe.withDefault ( unusedRoutes, mapRouteKeys ) afterRemovedMap

                    newAnchors =
                        OrdDict.remove pointId anchors

                    ( nextStartAnchor, newUnusedAnchors ) =
                        if (pointId == "startMarker") then
                            True => unusedAnchors
                        else
                            startAnchorUnused => Fifo.insert pointId unusedAnchors

                    newMenu =
                        Menu.anchorCountUpdate (anchorCount - 1) menu

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
                        , mapRouteKeys = newMapRouteKeys
                        , startAnchorUnused = nextStartAnchor
                        , unusedAnchors = newUnusedAnchors
                        , unusedRoutes = newUnusedRoutes
                        , menu = newMenu
                    }
                        => cmd
                        => NoOp

            ReceiveRoute _ endPointId _ (Err error) ->
                let
                    responseCode =
                        case error of
                            Http.BadPayload _ response ->
                                response.status.code

                            Http.BadStatus response ->
                                response.status.code

                            _ ->
                                0

                    ( externalMsg, errorMsg ) =
                        if responseCode == 401 then
                            Unauthorized
                                => { type_ = Messages.Error
                                   , message = "You must login to creating your route. Sorry!"
                                   }
                        else if responseCode == 204 then
                            NoOp
                                => { type_ = Messages.Error
                                   , message = "We weren't able to find a path between those points. Sorry!"
                                   }
                        else
                            NoOp
                                => { type_ = Messages.Error
                                   , message = "There was a server error creating your route. Sorry!"
                                   }

                    ( newErrors, errorCmd ) =
                        Messages.update (AddMessage errorMsg) errors

                    cmd =
                        Cmd.batch
                            [ Ports.hideSources [ endPointId ]
                            , Cmd.map ErrorMsg errorCmd
                            ]
                in
                    { model | errors = newErrors }
                        => cmd
                        => NoOp

            ReceiveRoute startPointId endPointId index (Ok route) ->
                let
                    routeKey =
                        cycleRouteKey startPointId endPointId

                    line =
                        Polyline.decode route.polyline

                    newCycleRoutes =
                        OrdDict.insertAt index routeKey route cycleRoutes

                    ( ( mapKey, nextSeed ), newUnusedRoutes ) =
                        if (List.length <| Fifo.toList unusedRoutes) > 0 then
                            Fifo.remove unusedRoutes
                                |> (\( maybeKey, nextUnused ) ->
                                        case maybeKey of
                                            Nothing ->
                                                generateNewKey model.keySeed => nextUnused

                                            Just key ->
                                                key => model.keySeed => nextUnused
                                   )
                        else
                            generateNewKey model.keySeed => unusedRoutes

                    newMapRouteKeys =
                        Dict.insert routeKey mapKey mapRouteKeys

                    paint =
                        Encode.object
                            [ "line-opacity" => Encode.float 0.5
                            , "line-width" => Encode.int 5
                            ]
                in
                    { model
                        | cycleRoutes = newCycleRoutes
                        , mapRouteKeys = newMapRouteKeys
                        , unusedRoutes = newUnusedRoutes
                        , keySeed = nextSeed
                    }
                        => Ports.addSource
                            ( mapKey, Just "line", Just paint, line )
                        => NoOp

            MenuMsg subMsg ->
                let
                    ( ( menuModel, menuCmd ), msgFromMenu ) =
                        Menu.update subMsg model.menu

                    ( newModel, mainCmd ) =
                        case msgFromMenu of
                            Menu.NoOp ->
                                model => Cmd.none

                            Menu.Error error ->
                                let
                                    errorMsg =
                                        { type_ = Messages.Error
                                        , message = error
                                        }

                                    ( newErrors, errorCmd ) =
                                        Messages.update
                                            (AddMessage errorMsg)
                                            errors
                                in
                                    { model | errors = newErrors }
                                        => Cmd.map ErrorMsg errorCmd

                            Menu.OpenMenu ->
                                { model
                                    | switchStyle =
                                        Animation.interrupt
                                            [ Animation.to styles.switchOpen ]
                                            model.switchStyle
                                    , errorsStyle =
                                        Animation.interrupt
                                            [ Animation.to styles.msgOpen ]
                                            model.errorsStyle
                                }
                                    => Cmd.none

                            Menu.CloseMenu ->
                                let
                                    ( nextStartAnchor, filteredAnchors ) =
                                        if List.member "startMarker" anchors.order then
                                            True => List.filter (\key -> key /= "startMarker") anchors.order
                                        else
                                            False => anchors.order

                                    newUnusedAnchors =
                                        Fifo.toList unusedAnchors
                                            |> List.append filteredAnchors
                                            |> Fifo.fromList

                                    newUnusedRoutes =
                                        Fifo.toList unusedRoutes
                                            |> List.append cycleRoutes.order
                                            |> Fifo.fromList

                                    sourcesToClear =
                                        cycleRoutes.order
                                            |> List.filterMap (\key -> Dict.get key mapRouteKeys)
                                            |> List.append anchors.order
                                in
                                    { model
                                        | anchors = OrdDict.empty
                                        , cycleRoutes = OrdDict.empty
                                        , startAnchorUnused = nextStartAnchor
                                        , unusedAnchors = newUnusedAnchors
                                        , unusedRoutes = newUnusedRoutes
                                        , switchStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.closed ]
                                                model.switchStyle
                                        , errorsStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.closed ]
                                                model.errorsStyle
                                    }
                                        => Ports.hideSources sourcesToClear

                            Menu.Completed sRating tRating name desc ->
                                let
                                    ( nextStartAnchor, filteredAnchors ) =
                                        if List.member "startMarker" anchors.order then
                                            True => List.filter (\key -> key /= "startMarker") anchors.order
                                        else
                                            False => anchors.order

                                    newUnusedAnchors =
                                        Fifo.toList unusedAnchors
                                            |> List.append filteredAnchors
                                            |> Fifo.fromList

                                    newUnusedRoutes =
                                        Fifo.toList unusedRoutes
                                            |> List.append cycleRoutes.order
                                            |> Fifo.fromList

                                    sourcesToClear =
                                        cycleRoutes.order
                                            |> List.filterMap (\key -> Dict.get key mapRouteKeys)
                                            |> List.append anchors.order

                                    polylines =
                                        model.cycleRoutes
                                            |> OrdDict.orderedValues
                                            |> List.map .polyline

                                    createSegmentForm =
                                        { name = name
                                        , description = desc
                                        , polylines = polylines
                                        , surfaceRating = sRating
                                        , trafficRating = tRating
                                        , surface = UnknownSurface
                                        , pathType = UnknownPath
                                        }

                                    req =
                                        saveSegment
                                            apiUrl
                                            maybeAuthToken
                                            createSegmentForm
                                            model.zoom

                                    loadMsg =
                                        { type_ = Messages.Loading
                                        , message = "We're processing your rating"
                                        }

                                    msgKey =
                                        errors.nextKey

                                    ( newErrors, errorCmd ) =
                                        Messages.update (AddMessage loadMsg) errors
                                in
                                    { model
                                        | anchors = OrdDict.empty
                                        , cycleRoutes = OrdDict.empty
                                        , startAnchorUnused = nextStartAnchor
                                        , unusedAnchors = newUnusedAnchors
                                        , unusedRoutes = newUnusedRoutes
                                        , errors = newErrors
                                        , switchStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.closed ]
                                                model.switchStyle
                                        , errorsStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.closed ]
                                                model.errorsStyle
                                    }
                                        => Cmd.batch
                                            [ Http.send (ReceiveSegment msgKey) req
                                            , Cmd.map ErrorMsg errorCmd
                                            , Ports.hideSources sourcesToClear
                                            ]

                    cmd =
                        Cmd.batch
                            [ mainCmd
                            , Cmd.map MenuMsg menuCmd
                            ]
                in
                    { newModel | menu = menuModel } => cmd => NoOp

            ReceiveSegment loadingMsgKey (Err error) ->
                let
                    responseCode =
                        case error of
                            Http.BadPayload _ response ->
                                response.status.code

                            Http.BadStatus response ->
                                response.status.code

                            _ ->
                                0

                    ( externalMsg, errorMsg ) =
                        if responseCode == 401 then
                            Unauthorized
                                => { type_ = Messages.Error
                                   , message = "You must login to save a segment. Sorry!"
                                   }
                        else
                            NoOp
                                => { type_ = Messages.Error
                                   , message = "There was a server error saving your segment. Sorry!"
                                   }

                    ( newErrors, errorCmd ) =
                        [ RemoveMessage loadingMsgKey
                        , AddMessage errorMsg
                        ]
                            |> List.foldl
                                (\message ( prevErr, prevCmd ) ->
                                    let
                                        ( nextErr, nextCmd ) =
                                            Messages.update message prevErr
                                    in
                                        nextErr => Cmd.batch [ prevCmd, nextCmd ]
                                )
                                ( errors, Cmd.none )
                in
                    { model | errors = newErrors }
                        => Cmd.map ErrorMsg errorCmd
                        => externalMsg

            ReceiveSegment loadingMsgKey (Ok segment) ->
                let
                    segments =
                        segment :: model.segments

                    layer =
                        toString model.mapLayer

                    ( newErrors, errorCmd ) =
                        Messages.update (RemoveMessage loadingMsgKey) errors
                in
                    { model | segments = segments, errors = newErrors }
                        => Cmd.batch
                            [ Ports.refreshLayer layer
                            , Cmd.map ErrorMsg errorCmd
                            ]
                        => NoOp

            LoadSegments ( southWest, northEast ) ->
                let
                    req =
                        Request.Map.getBoundedSegments
                            apiUrl
                            maybeAuthToken
                            southWest
                            northEast
                in
                    case maybeAuthToken of
                        Nothing ->
                            model => Cmd.none => NoOp

                        Just _ ->
                            model => Http.send ReceiveSegments req => NoOp

            ReceiveSegments (Err error) ->
                let
                    errorMsg =
                        { type_ = Messages.Error
                        , message = "There was a server error loading segments. Sorry!"
                        }

                    ( newErrors, errorCmd ) =
                        Messages.update (AddMessage errorMsg) errors
                in
                    { model | errors = newErrors }
                        => Cmd.map ErrorMsg errorCmd
                        => NoOp

            ReceiveSegments (Ok segments) ->
                { model | segments = List.append segments model.segments }
                    => Cmd.none
                    => NoOp


generateNewKey : Seed -> ( String, Seed )
generateNewKey seed =
    Random.step (string 16 english) seed


removeRoute : String -> String -> OrderedDict String CycleRoute -> OrderedDict String CycleRoute
removeRoute startPointId endPointId cycleRoutes =
    OrdDict.remove (cycleRouteKey startPointId endPointId) cycleRoutes


removeRouteMap : String -> String -> ( Fifo String, Dict String String ) -> ( Fifo String, Dict String String )
removeRouteMap startPointId endPointId ( unusedRoutes, mapRouteKeys ) =
    let
        routeKey =
            cycleRouteKey startPointId endPointId

        newUnusedRoutes =
            Dict.get routeKey mapRouteKeys
                |> Maybe.map (\mapKey -> Fifo.insert mapKey unusedRoutes)
                |> Maybe.withDefault unusedRoutes
    in
        newUnusedRoutes => Dict.remove routeKey mapRouteKeys


removeRouteFromMap : Dict String String -> String -> String -> Cmd Msg
removeRouteFromMap mapRouteKeys startPointId endPointId =
    cycleRouteKey startPointId endPointId
        |> (\routeKey -> Dict.get routeKey mapRouteKeys)
        |> Maybe.map (\key -> Ports.hideSources [ key ])
        |> Maybe.withDefault Cmd.none


addRoute : String -> Maybe AuthToken -> OrderedDict String CycleRoute -> OrderedDict String Point -> String -> String -> Cmd Msg
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
            (ReceiveRoute startPointId endPointId routeIndex)
            (makeRoute apiUrl maybeAuthToken points)
