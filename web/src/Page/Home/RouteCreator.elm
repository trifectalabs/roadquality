module Page.Home.RouteCreator exposing (Model, initModel, subscriptions, Msg(..), ExternalMsg(..), update)

import OrderedDict as OrdDict exposing (OrderedDict)
import Data.Map exposing (Point, CycleRoute)
import Fifo exposing (Fifo)
import Ports
import Data.AuthToken exposing (AuthToken)
import Data.Session as Session exposing (Session)
import Http
import Random exposing (Seed)
import Util exposing ((=>), generateNewKey)
import Request.Map exposing (snap, makeRoute)
import Json.Encode as Encode
import Dict exposing (Dict)
import Alert exposing (Msg(..))
import List.Extra exposing (elemIndex)
import Polyline


-- MODEL --


type alias Model =
    { anchors : OrderedDict String Point
    , cycleRoutes : OrderedDict String CycleRoute
    , mapRouteKeys : Dict String String
    , unusedAnchors : Fifo String
    , unusedRoutes : Fifo String
    , startAnchorUnused : Bool
    , keySeed : Seed
    }


initModel : Int -> Model
initModel seed =
    { anchors = OrdDict.empty
    , cycleRoutes = OrdDict.empty
    , mapRouteKeys = Dict.empty
    , unusedAnchors = Fifo.empty
    , unusedRoutes = Fifo.empty
    , startAnchorUnused = False
    , keySeed = Random.initialSeed seed
    }



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.removedAnchor RemoveAnchorPoint
        , Ports.setAnchor DropAnchorPoint
        , Ports.movedAnchor MoveAnchorPoint
        ]



-- UPDATE --


type Msg
    = HideCurrentRoute
    | DropAnchorPoint ( Float, Float )
    | MoveAnchorPoint ( String, Float, Float )
    | NewAnchorPoint String (Result Http.Error Point)
    | ChangeAnchorPoint String (Result Http.Error Point)
    | RemoveAnchorPoint String
    | ReceiveRoute String String Int (Result Http.Error CycleRoute)


type ExternalMsg
    = NoOp
    | AddAlert Alert.Alert
    | AnchorCount Int


update : Session -> Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update session msg model =
    let
        maybeAuthToken =
            session.user
                |> Maybe.map .token

        apiUrl =
            session.apiUrl

        authedAddRoute =
            addRoute apiUrl maybeAuthToken model.cycleRoutes
    in
        case msg of
            HideCurrentRoute ->
                let
                    ( nextStartAnchor, filteredAnchors ) =
                        if List.member "startMarker" model.anchors.order then
                            True => List.filter (\key -> key /= "startMarker") model.anchors.order
                        else
                            False => model.anchors.order

                    newUnusedAnchors =
                        Fifo.toList model.unusedAnchors
                            |> List.append filteredAnchors
                            |> Fifo.fromList

                    newUnusedRoutes =
                        Fifo.toList model.unusedRoutes
                            |> List.append model.cycleRoutes.order
                            |> Fifo.fromList

                    sourcesToClear =
                        model.cycleRoutes.order
                            |> List.filterMap (\key -> Dict.get key model.mapRouteKeys)
                            |> List.append model.anchors.order
                in
                    { model
                        | anchors = OrdDict.empty
                        , cycleRoutes = OrdDict.empty
                        , startAnchorUnused = nextStartAnchor
                        , unusedAnchors = newUnusedAnchors
                        , unusedRoutes = newUnusedRoutes
                    }
                        => Ports.hideSources sourcesToClear
                        => AnchorCount 0

            DropAnchorPoint ( lng, lat ) ->
                let
                    point =
                        { lng = lng
                        , lat = lat
                        }

                    ( ( ( pointId, nextSeed ), newUnusedAnchors ), nextStartAnchor ) =
                        if model.startAnchorUnused == True then
                            "startMarker" => model.keySeed => model.unusedAnchors => False
                        else if (List.length <| Fifo.toList model.unusedAnchors) > 0 then
                            Fifo.remove model.unusedAnchors
                                |> (\( maybeKey, nextUnused ) ->
                                        case maybeKey of
                                            Nothing ->
                                                generateNewKey model.keySeed
                                                    => nextUnused
                                                    => model.startAnchorUnused

                                            Just key ->
                                                key
                                                    => model.keySeed
                                                    => nextUnused
                                                    => model.startAnchorUnused
                                   )
                        else if List.length model.anchors.order == 0 then
                            "startMarker"
                                => model.keySeed
                                => model.unusedAnchors
                                => model.startAnchorUnused
                        else
                            generateNewKey model.keySeed
                                => model.unusedAnchors
                                => model.startAnchorUnused

                    newAnchors =
                        OrdDict.insert pointId point model.anchors

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

                    externalMsg =
                        AnchorCount <| List.length newAnchors.order

                    cmd =
                        Cmd.batch
                            [ Http.send (NewAnchorPoint pointId) req
                            , Ports.addSource
                                ( pointId
                                , Just "circle"
                                , [ ( lng, lat ) ]
                                , Just paint
                                , Nothing
                                )
                            ]

                    currentAnchor =
                        Dict.get pointId model.anchors.dict
                            -- Impossible Values
                            |> Maybe.withDefault { lat = 1000.0, lng = 1000.0 }
                in
                    if
                        ((abs <| currentAnchor.lat - lat) < 0.0001)
                            && ((abs <| currentAnchor.lng - lng) < 0.0001)
                    then
                        model => Cmd.none => externalMsg
                    else
                        { model
                            | anchors = newAnchors
                            , startAnchorUnused = nextStartAnchor
                            , unusedAnchors = newUnusedAnchors
                            , keySeed = nextSeed
                        }
                            => cmd
                            => externalMsg

            MoveAnchorPoint ( pointId, lng, lat ) ->
                let
                    req =
                        snap apiUrl maybeAuthToken ( lat, lng )

                    cmd =
                        Http.send (ChangeAnchorPoint pointId) req

                    currentAnchor =
                        Dict.get pointId model.anchors.dict
                            -- Impossible Values
                            |> Maybe.withDefault { lat = 1000.0, lng = 1000.0 }

                    externalMsg =
                        AnchorCount <| List.length model.anchors.order
                in
                    if
                        ((abs <| currentAnchor.lat - lat) < 0.0001)
                            && ((abs <| currentAnchor.lng - lng) < 0.0001)
                    then
                        model => Cmd.none => externalMsg
                    else
                        model => cmd => externalMsg

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

                    alertMsg =
                        if responseCode == 401 then
                            { type_ = Alert.Error
                            , message = "You must login to place a point. Sorry!"
                            , untilRemove = 5000
                            , icon = True
                            }
                        else if responseCode == 204 then
                            { type_ = Alert.Error
                            , message = "You're trying to place a point outside the currently supported area. Whoops!"
                            , untilRemove = 5000
                            , icon = True
                            }
                        else
                            { type_ = Alert.Error
                            , message = "There was a server error trying to place your point. Sorry!"
                            , untilRemove = 5000
                            , icon = True
                            }
                in
                    model
                        => Ports.hideSources [ pointId ]
                        => AddAlert alertMsg

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
                        OrdDict.insert pointId point model.anchors

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
                                , [ ( point.lng, point.lat ) ]
                                , Nothing
                                , Nothing
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

                    alertMsg =
                        if responseCode == 401 then
                            { type_ = Alert.Error
                            , message = "You must login to move a point. Sorry!"
                            , untilRemove = 5000
                            , icon = True
                            }
                        else if responseCode == 204 then
                            { type_ = Alert.Error
                            , message = "You're trying to move a point outside the currently supported area. Whoops!"
                            , untilRemove = 5000
                            , icon = True
                            }
                        else
                            { type_ = Alert.Error
                            , message = "There was a server error trying to move your point. Sorry!"
                            , untilRemove = 5000
                            , icon = True
                            }
                in
                    model
                        => Ports.hideSources [ pointId ]
                        => AddAlert alertMsg

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
                        OrdDict.insert pointId point model.anchors

                    anchorIndex =
                        elemIndex pointId model.anchors.order
                            |> Maybe.withDefault -1

                    anchorCount =
                        List.length model.anchors.order

                    start =
                        model.anchors.order
                            |> List.drop (anchorIndex - 1)
                            |> List.head

                    end =
                        model.anchors.order
                            |> List.drop (anchorIndex + 1)
                            |> List.head

                    deleteBeforeCmd =
                        Maybe.map (\s -> removeRouteFromMap model.mapRouteKeys s pointId) start
                            |> Maybe.withDefault Cmd.none

                    addBeforeCmd =
                        Maybe.map
                            (\s -> authedAddRoute newAnchors s pointId)
                            start
                            |> Maybe.withDefault Cmd.none

                    deleteAfterCmd =
                        Maybe.map (\e -> removeRouteFromMap model.mapRouteKeys pointId e) end
                            |> Maybe.withDefault Cmd.none

                    addAfterCmd =
                        Maybe.map
                            (\e -> authedAddRoute newAnchors pointId e)
                            end
                            |> Maybe.withDefault Cmd.none

                    ( removedRoutes, removedRoutesMap, deleteAddCmd ) =
                        -- Moving first anchor with no routes, do nothing
                        if anchorIndex == 0 && anchorCount == 1 then
                            ( Just model.cycleRoutes
                            , Just ( model.unusedRoutes, model.mapRouteKeys )
                            , Cmd.none
                            )
                            -- Delete route before, Delete/Add route before cmd
                        else if anchorIndex == (anchorCount - 1) then
                            ( Maybe.map
                                (\s -> removeRoute s pointId model.cycleRoutes)
                                start
                            , Maybe.map
                                (\s ->
                                    removeRouteMap
                                        s
                                        pointId
                                        ( model.unusedRoutes, model.mapRouteKeys )
                                )
                                start
                            , Cmd.batch [ deleteBeforeCmd, addBeforeCmd ]
                            )
                            -- Delete route after, Delete/Add route after cmd
                        else if anchorIndex == 0 then
                            ( Maybe.map
                                (\e -> removeRoute pointId e model.cycleRoutes)
                                end
                            , Maybe.map
                                (\e ->
                                    removeRouteMap
                                        pointId
                                        e
                                        ( model.unusedRoutes, model.mapRouteKeys )
                                )
                                end
                            , Cmd.batch [ deleteAfterCmd, addAfterCmd ]
                            )
                            -- Delete route before/after,
                            -- Delete/Add route before/after cmd
                        else
                            ( Maybe.map2
                                (\s e ->
                                    model.cycleRoutes
                                        |> removeRoute s pointId
                                        |> removeRoute pointId e
                                )
                                start
                                end
                            , Maybe.map2
                                (\s e ->
                                    ( model.unusedRoutes, model.mapRouteKeys )
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
                                , [ ( point.lng, point.lat ) ]
                                , Nothing
                                , Nothing
                                )
                            , deleteAddCmd
                            ]

                    newCycleRoutes =
                        Maybe.withDefault model.cycleRoutes removedRoutes

                    ( newUnusedRoutes, newMapRouteKeys ) =
                        Maybe.withDefault
                            ( model.unusedRoutes, model.mapRouteKeys )
                            removedRoutesMap
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
                        elemIndex pointId model.anchors.order
                            |> Maybe.withDefault -1

                    anchorCount =
                        List.length model.anchors.order

                    start =
                        model.anchors.order
                            |> List.drop (anchorIndex - 1)
                            |> List.head

                    end =
                        model.anchors.order
                            |> List.drop (anchorIndex + 1)
                            |> List.head

                    routeIndex =
                        start
                            |> Maybe.map (\s -> cycleRouteKey s pointId)
                            |> Maybe.map (\r -> elemIndex r model.cycleRoutes.order)

                    -- Delete route before
                    beforeRemoved =
                        Maybe.map
                            (\s -> removeRoute s pointId model.cycleRoutes)
                            start

                    beforeRemovedMap =
                        Maybe.map
                            (\s ->
                                removeRouteMap
                                    s
                                    pointId
                                    ( model.unusedRoutes, model.mapRouteKeys )
                            )
                            start

                    -- Delete route before cmd
                    removeFirstCmd =
                        Maybe.map
                            (\s -> removeRouteFromMap model.mapRouteKeys s pointId)
                            start
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
                                (\e -> removeRouteFromMap model.mapRouteKeys pointId e)
                                end
                                |> Maybe.withDefault Cmd.none
                            , Maybe.map2
                                (\s e -> authedAddRoute model.anchors s e)
                                start
                                end
                                |> Maybe.withDefault Cmd.none
                            )

                    newCycleRoutes =
                        Maybe.withDefault model.cycleRoutes afterRemoved

                    ( newUnusedRoutes, newMapRouteKeys ) =
                        Maybe.withDefault
                            ( model.unusedRoutes, model.mapRouteKeys )
                            afterRemovedMap

                    newAnchors =
                        OrdDict.remove pointId model.anchors

                    ( nextStartAnchor, newUnusedAnchors ) =
                        if (pointId == "startMarker") then
                            True => model.unusedAnchors
                        else
                            model.startAnchorUnused
                                => Fifo.insert pointId model.unusedAnchors

                    externalMsg =
                        AnchorCount <| List.length newAnchors.order

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
                    }
                        => cmd
                        => externalMsg

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

                    alertMsg =
                        if responseCode == 401 then
                            { type_ = Alert.Error
                            , message = "You must login to creating your route. Sorry!"
                            , untilRemove = 5000
                            , icon = True
                            }
                        else if responseCode == 204 then
                            { type_ = Alert.Error
                            , message = "We weren't able to find a path between those points. Sorry!"
                            , untilRemove = 5000
                            , icon = True
                            }
                        else
                            { type_ = Alert.Error
                            , message = "There was a server error creating your route. Sorry!"
                            , untilRemove = 5000
                            , icon = True
                            }
                in
                    model
                        => Ports.hideSources [ endPointId ]
                        => NoOp

            ReceiveRoute startPointId endPointId index (Ok route) ->
                let
                    routeKey =
                        cycleRouteKey startPointId endPointId

                    line =
                        Polyline.decode route.polyline

                    newCycleRoutes =
                        OrdDict.insertAt index routeKey route model.cycleRoutes

                    ( ( mapKey, nextSeed ), newUnusedRoutes ) =
                        if (List.length <| Fifo.toList model.unusedRoutes) > 0 then
                            Fifo.remove model.unusedRoutes
                                |> (\( maybeKey, nextUnused ) ->
                                        case maybeKey of
                                            Nothing ->
                                                generateNewKey model.keySeed
                                                    => nextUnused

                                            Just key ->
                                                key
                                                    => model.keySeed
                                                    => nextUnused
                                   )
                        else
                            generateNewKey model.keySeed => model.unusedRoutes

                    newMapRouteKeys =
                        Dict.insert routeKey mapKey model.mapRouteKeys

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
                            ( mapKey, Just "line", line, Just paint, Nothing )
                        => NoOp


cycleRouteKey : String -> String -> String
cycleRouteKey first second =
    first ++ "_" ++ second


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
