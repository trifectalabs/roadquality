module Page.Home.Segments exposing (Model, initModel, Msg(..), ExternalMsg(..), subscriptions, update)

import OrderedDict as OrdDict exposing (OrderedDict)
import Dict exposing (Dict)
import Set exposing (Set)
import Data.Map exposing (CycleRoute, Point, Segment, MapLayer, SurfaceType(..), PathType(..))
import Http
import Util exposing ((=>))
import Alert exposing (Msg(..))
import Data.Session as Session exposing (Session)
import Ports
import Polyline
import Json.Encode as Encode
import Request.Map exposing (getBoundedSegments, saveSegment, saveRating)


-- MODEL --


type alias Model =
    { segments : Dict String Segment
    , visibleSegments : Set String
    }


initModel : Model
initModel =
    { segments = Dict.empty
    , visibleSegments = Set.empty
    }



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.loadSegments LoadSegments



-- UPDATE --


type Msg
    = ReceiveSegment Int (Result Http.Error Segment)
    | LoadSegments ()
    | ReceiveSegments Bool (Result Http.Error (List Segment))
    | MapBoundsUpdate ( Bool, Bool )
    | HideVisibleSegments
    | CreateSegment Int Float (OrderedDict String CycleRoute) Int Int (Maybe String) (Maybe String) Bool
    | SaveRating Int Float Int Int String


type ExternalMsg
    = AddAlert Alert.Alert
    | HideAlert Int
    | VisibleSegments (Set String)


update : Session -> Maybe ( Point, Point ) -> MapLayer -> Msg -> Model -> ( ( Model, Cmd Msg ), List ExternalMsg )
update session mapBounds mapLayer msg model =
    let
        maybeAuthToken =
            session.user
                |> Maybe.map .token

        apiUrl =
            session.apiUrl
    in
        case msg of
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

                    alertMsg =
                        if responseCode == 401 then
                            { type_ = Alert.Error
                            , message = "You must login to save a segment. Sorry!"
                            , untilRemove = 5000
                            , icon = True
                            }
                        else
                            { type_ = Alert.Error
                            , message = "There was a server error saving your segment. Sorry!"
                            , untilRemove = 5000
                            , icon = True
                            }
                in
                    model
                        => Cmd.none
                        => [ HideAlert loadingMsgKey, AddAlert alertMsg ]

            ReceiveSegment loadingMsgKey (Ok segment) ->
                let
                    segments =
                        Dict.insert segment.id segment model.segments

                    layer =
                        toString mapLayer
                in
                    { model | segments = segments }
                        => Ports.refreshLayer layer
                        => [ HideAlert loadingMsgKey ]

            LoadSegments () ->
                let
                    req =
                        mapBounds
                            |> Maybe.map
                                (\( southWest, northEast ) ->
                                    getBoundedSegments
                                        apiUrl
                                        maybeAuthToken
                                        southWest
                                        northEast
                                )
                            |> Maybe.map (Http.send <| ReceiveSegments False)
                            |> Maybe.withDefault Cmd.none
                in
                    case maybeAuthToken of
                        Nothing ->
                            model => Cmd.none => []

                        Just _ ->
                            model => req => []

            ReceiveSegments _ (Err error) ->
                let
                    alertMsg =
                        { type_ = Alert.Error
                        , message = "There was a server error loading segments. Sorry!"
                        , untilRemove = 5000
                        , icon = True
                        }
                in
                    model => Cmd.none => [ AddAlert alertMsg ]

            ReceiveSegments alterMode (Ok someSegments) ->
                let
                    newSegments =
                        List.foldl
                            (\seg acc -> Dict.insert seg.id seg acc)
                            model.segments
                            someSegments

                    addSegments =
                        segmentsToDisplay mapBounds newSegments model.visibleSegments
                            |> displaySegments

                    newVisibleSegments =
                        List.foldl
                            (\seg acc -> Set.insert seg.id acc)
                            model.visibleSegments
                            someSegments

                    externalMsgs =
                        if alterMode && Set.size newVisibleSegments == 0 then
                            let
                                alertMsg =
                                    { type_ = Alert.Info
                                    , message = "Looks like there's no segments in this area. Try making your own!"
                                    , untilRemove = 5000
                                    , icon = True
                                    }
                            in
                                [ VisibleSegments newVisibleSegments
                                , AddAlert alertMsg
                                ]
                        else
                            [ VisibleSegments newVisibleSegments ]
                in
                    { model
                        | segments = newSegments
                        , visibleSegments = newVisibleSegments
                    }
                        => addSegments
                        => externalMsgs

            MapBoundsUpdate ( viewOnly, segmentMode ) ->
                let
                    display =
                        segmentsToDisplay mapBounds model.segments model.visibleSegments

                    displayIds =
                        Set.fromList <| List.map .id display

                    hide =
                        segmentsToHide mapBounds model.segments model.visibleSegments

                    hideIds =
                        Set.fromList <| List.map .id hide

                    newVisibleSegments =
                        Set.diff model.visibleSegments hideIds
                            |> Set.union displayIds
                in
                    if viewOnly || not segmentMode then
                        model => Cmd.none => []
                    else
                        { model | visibleSegments = newVisibleSegments }
                            => Cmd.batch
                                [ hideSegments hide
                                , displaySegments display
                                ]
                            => []

            HideVisibleSegments ->
                { model | visibleSegments = Set.empty }
                    => Ports.hideSources (Set.toList model.visibleSegments)
                    => [ VisibleSegments Set.empty ]

            CreateSegment nextAlertsKey zoom cycleRoutes sRating tRating name desc quick ->
                let
                    polylines =
                        cycleRoutes
                            |> OrdDict.orderedValues
                            |> List.map .polyline

                    createSegmentForm =
                        { name = name
                        , description = desc
                        , polylines = polylines
                        , surfaceRating = sRating
                        , trafficRating = tRating
                        , surfaceType = UnknownSurface
                        , pathType = UnknownPath
                        }

                    req =
                        saveSegment
                            apiUrl
                            maybeAuthToken
                            createSegmentForm
                            zoom
                            quick
                in
                    model => Http.send (ReceiveSegment nextAlertsKey) req => []

            SaveRating nextAlertsKey zoom sRating tRating segmentId ->
                let
                    polylines =
                        Dict.get segmentId model.segments
                            |> Maybe.map (\s -> [ s.polyline ])
                            |> Maybe.withDefault []

                    createSegmentForm =
                        { name = Nothing
                        , description = Nothing
                        , polylines = polylines
                        , surfaceRating = sRating
                        , trafficRating = tRating
                        , surfaceType = UnknownSurface
                        , pathType = UnknownPath
                        }

                    req =
                        saveRating
                            apiUrl
                            maybeAuthToken
                            createSegmentForm
                            segmentId
                            zoom
                in
                    model => Http.send (ReceiveSegment nextAlertsKey) req => []


withinMapBounds : Maybe ( Point, Point ) -> Segment -> Bool
withinMapBounds mapBounds segment =
    case mapBounds of
        Nothing ->
            True

        Just ( southWest, northEast ) ->
            Polyline.decode segment.polyline
                |> List.foldl
                    (\( lat, lng ) within ->
                        ((lat <= northEast.lat)
                            && (lng <= northEast.lng)
                            && (lat >= southWest.lat)
                            && (lng >= southWest.lng)
                        )
                            || within
                    )
                    False


segmentsToDisplay : Maybe ( Point, Point ) -> Dict String Segment -> Set String -> List Segment
segmentsToDisplay mapBounds segments visibleSegments =
    Dict.values segments
        |> List.filter (\seg -> not <| Set.member seg.id visibleSegments)
        |> List.filter (withinMapBounds mapBounds)


segmentsToHide : Maybe ( Point, Point ) -> Dict String Segment -> Set String -> List Segment
segmentsToHide mapBounds segments visibleSegments =
    Dict.values segments
        |> List.filter (\seg -> Set.member seg.id visibleSegments)
        |> List.filter (\seg -> not <| withinMapBounds mapBounds seg)


displaySegments : List Segment -> Cmd Msg
displaySegments segments =
    let
        paint =
            Encode.object
                [ "line-width" => Encode.int 4
                , "line-color" => Encode.string "rgb(176, 215, 51)"
                ]

        hoverPaint =
            Encode.object
                [ "line-width" => Encode.int 4
                , "line-color" => Encode.string "rgb(100, 175, 60)"
                ]

        activePaint =
            Encode.object
                [ "line-width" => Encode.int 4
                , "line-color" => Encode.string "rgb(2, 126, 51)"
                ]

        selectedPaint =
            Encode.object
                [ "line-width" => Encode.int 4
                , "line-color" => Encode.string "rgb(22, 146, 71)"
                ]
    in
        segments
            |> List.map
                (\seg ->
                    Ports.addSource
                        ( seg.id
                        , Just "line"
                        , Polyline.decode seg.polyline
                        , Just paint
                        , Just ( hoverPaint, activePaint, selectedPaint )
                        )
                )
            |> Cmd.batch


hideSegments : List Segment -> Cmd Msg
hideSegments segments =
    segments
        |> List.map .id
        |> Ports.hideSources
