module Page.Home exposing (view, subscriptions, update, Model, Msg, ExternalMsg(..), init)

import Data.Map exposing (MapLayer(..), Point)
import Data.Session as Session exposing (Session)
import Data.UserPhoto as UserPhoto
import Request.User exposing (emailListSignUp)
import Ports
import Http
import Task exposing (Task)
import Views.Page as Page
import Page.Errored as Errored exposing (PageLoadError, pageLoadError)
import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (type_, value, href)
import Stylesheets exposing (globalNamespace, mapNamespace, CssIds(..), CssClasses(..))
import Html.CssHelpers exposing (Namespace)
import Util exposing ((=>), generateNewKey)
import Route
import Views.Assets as Assets
import Page.Home.RatingsMenu as Menu
import Animation exposing (px)
import Time exposing (Time)
import Alert exposing (Msg(..))
import Views.StravaLogin as StravaLogin
import Page.Home.RouteCreator as RouteCreator
import Page.Home.Segments as Segments


-- MODEL --


type alias Model =
    { alerts : Alert.Model
    , listEmail : String
    , menu : Menu.Model
    , mapLayer : MapLayer
    , zoom : Float
    , mapBounds : Maybe ( Point, Point )
    , switchStyle : Animation.State
    , alertsStyle : Animation.State
    , routeCreator : RouteCreator.Model
    , segments : Segments.Model
    }


type alias Styles =
    { switchOpen : List Animation.Property
    , closed : List Animation.Property
    , msgOpen : List Animation.Property
    }


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
    { alerts = Alert.initModel True
    , listEmail = ""
    , menu = Menu.initModel
    , mapLayer = SurfaceQuality
    , zoom = zoom
    , mapBounds = Nothing
    , switchStyle = Animation.style styles.closed
    , alertsStyle = Animation.style styles.closed
    , routeCreator = RouteCreator.initModel <| round now
    , segments = Segments.initModel
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
            , div
                (List.concat
                    [ Animation.render model.alertsStyle
                    , [ id RQAlertContainer ]
                    ]
                )
                [ Alert.view model.alerts |> Html.map AlertMsg ]
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
            , Menu.view model.menu model.segments.segments |> Html.map MenuMsg
            , accountView session
            , signUpBanner model.listEmail (session.user == Nothing)
            ]


accountView : Session -> Html Msg
accountView session =
    case session.user of
        Nothing ->
            div [ class [ GoToAccount ] ] [ StravaLogin.view ]

        -- a
        --     [ Route.href Route.Login ]
        --     [ div
        --         [ class [ GoToAccount ]
        --         , g.class [ SecondaryButton ]
        --         ]
        --         [ text "Sign In" ]
        --     ]
        Just user ->
            a
                [ Route.href Route.Account ]
                [ img [ UserPhoto.src user.photo, class [ GoToAccount ] ] [] ]


signUpBanner : String -> Bool -> Html Msg
signUpBanner email showBanner =
    if showBanner == True then
        div [ id EmailListBanner ]
            [ div []
                [ span []
                    [ text "Want access to Road Quality? Add your email here and we will let you know when we're adding more users! "
                    , a [ href "#/about" ] [ text "Click here to learn more." ]
                    ]
                , input [ type_ "text", onInput ChangeEmailList, value email ] []
                , div [ g.class [ SecondaryButton ], onClick EmailListSignup ] [ text "Let me know!" ]
                ]
            ]
    else
        span [] []



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.zoomLevel ZoomLevel
        , Ports.mapBounds MapBounds
        , Menu.subscriptions model.menu |> Sub.map MenuMsg
        , RouteCreator.subscriptions model.routeCreator |> Sub.map RouteCreatorMsg
        , Segments.subscriptions model.segments |> Sub.map SegmentsMsg
        , Animation.subscription AnimateSwitcher [ model.switchStyle ]
        , Animation.subscription AnimateAlerts [ model.alertsStyle ]
        , Alert.subscriptions model.alerts |> Sub.map AlertMsg
        ]



-- UPDATE --


type Msg
    = AlertMsg Alert.Msg
    | SetLayer MapLayer
    | ZoomLevel Float
    | MapBounds ( ( Point, Point ), Bool, Bool )
    | ShowLogin
    | ChangeEmailList String
    | EmailListSignup
    | EmailListSignupResult (Result Http.Error String)
    | AnimateSwitcher Animation.Msg
    | AnimateAlerts Animation.Msg
    | RouteCreatorMsg RouteCreator.Msg
    | SegmentsMsg Segments.Msg
    | MenuMsg Menu.Msg


type ExternalMsg
    = NoOp
    | Unauthorized


update : Session -> Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update session msg model =
    let
        maybeAuthToken =
            session.user
                |> Maybe.map .token

        apiUrl =
            session.apiUrl
    in
        case msg of
            AlertMsg subMsg ->
                let
                    ( newAlerts, alertsCmd ) =
                        Alert.update subMsg model.alerts
                in
                    { model | alerts = newAlerts }
                        => Cmd.map AlertMsg alertsCmd
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

            MapBounds ( bounds, viewOnly, segmentMode ) ->
                let
                    newBounds =
                        Just bounds

                    subMsg =
                        Segments.MapBoundsUpdate ( viewOnly, segmentMode )

                    boundsModel =
                        { model | mapBounds = newBounds }

                    ( newModel, cmd ) =
                        updateSegments session subMsg boundsModel
                in
                    if viewOnly || not segmentMode then
                        boundsModel => Cmd.none => NoOp
                    else
                        newModel => cmd => NoOp

            ShowLogin ->
                model => Cmd.none => Unauthorized

            ChangeEmailList email ->
                { model | listEmail = email } => Cmd.none => NoOp

            EmailListSignup ->
                model
                    => Http.send
                        EmailListSignupResult
                        (emailListSignUp session.webUrl model.listEmail)
                    => NoOp

            EmailListSignupResult (Err error) ->
                let
                    ( code, message ) =
                        case error of
                            Http.BadPayload _ response ->
                                ( response.status.code, response.body )

                            Http.BadStatus response ->
                                ( response.status.code, response.body )

                            _ ->
                                ( 0, "" )

                    alert =
                        case ( code, message ) of
                            ( 400, "\"Member Exists\"" ) ->
                                { message = "You already signed up!"
                                , type_ = Alert.Info
                                , untilRemove = 5000
                                , icon = True
                                }

                            _ ->
                                { message = "Email list sign up failed"
                                , type_ = Alert.Error
                                , untilRemove = 5000
                                , icon = True
                                }
                in
                    addAlert alert model => NoOp

            EmailListSignupResult (Ok response) ->
                let
                    alert =
                        { message = "We'll let you know when you can sign up!"
                        , type_ = Alert.Info
                        , untilRemove = 5000
                        , icon = True
                        }
                in
                    addAlert alert model => NoOp

            AnimateSwitcher animMsg ->
                { model
                    | switchStyle = Animation.update animMsg model.switchStyle
                }
                    => Cmd.none
                    => NoOp

            AnimateAlerts animMsg ->
                { model
                    | alertsStyle = Animation.update animMsg model.alertsStyle
                }
                    => Cmd.none
                    => NoOp

            RouteCreatorMsg subMsg ->
                updateRouteCreator session subMsg model => NoOp

            SegmentsMsg subMsg ->
                updateSegments session subMsg model => NoOp

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
                                    alert =
                                        { type_ = Alert.Error
                                        , message = error
                                        , untilRemove = 5000
                                        , icon = True
                                        }
                                in
                                    addAlert alert model

                            Menu.OpenMenu ->
                                updateSegments
                                    session
                                    (Segments.LoadSegments ())
                                    { model
                                        | switchStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.switchOpen ]
                                                model.switchStyle
                                        , alertsStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.msgOpen ]
                                                model.alertsStyle
                                    }

                            Menu.CloseMenu ->
                                let
                                    ( creatorModel, creatorCmd ) =
                                        updateRouteCreator
                                            session
                                            RouteCreator.HideCurrentRoute
                                            model

                                    ( segmentsModel, segmentsCmd ) =
                                        updateSegments
                                            session
                                            Segments.HideVisibleSegments
                                            creatorModel
                                in
                                    segmentsModel
                                        => Cmd.batch [ creatorCmd, segmentsCmd ]

                            Menu.ShowSegments show ->
                                if show == True then
                                    updateSegments
                                        session
                                        (Segments.LoadSegments ())
                                        model
                                else
                                    updateSegments
                                        session
                                        Segments.HideVisibleSegments
                                        model

                            Menu.SaveRating sRating tRating segmentId ->
                                let
                                    alert =
                                        { type_ = Alert.Loading
                                        , message = "We're processing your rating"
                                        , untilRemove = -1
                                        , icon = True
                                        }

                                    ( alertsModel, alertCmd ) =
                                        addAlert alert model

                                    ( hideModel, hideCmd ) =
                                        updateSegments
                                            session
                                            Segments.HideVisibleSegments
                                            alertsModel

                                    ( segmentModel, segmentCmd ) =
                                        updateSegments
                                            session
                                            (Segments.SaveRating
                                                model.alerts.nextKey
                                                model.zoom
                                                sRating
                                                tRating
                                                segmentId
                                            )
                                            hideModel
                                in
                                    { segmentModel
                                        | switchStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.closed ]
                                                model.switchStyle
                                        , alertsStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.closed ]
                                                model.alertsStyle
                                    }
                                        => Cmd.batch
                                            [ alertCmd
                                            , hideCmd
                                            , segmentCmd
                                            ]

                            Menu.CreateSegment sRating tRating name desc quick ->
                                let
                                    alert =
                                        { type_ = Alert.Loading
                                        , message = "We're processing your rating"
                                        , untilRemove = -1
                                        , icon = True
                                        }

                                    ( alertsModel, alertCmd ) =
                                        addAlert alert model

                                    ( hideModel, hideCmd ) =
                                        updateRouteCreator
                                            session
                                            RouteCreator.HideCurrentRoute
                                            alertsModel

                                    ( createModel, createCmd ) =
                                        updateSegments
                                            session
                                            (Segments.CreateSegment
                                                model.alerts.nextKey
                                                model.zoom
                                                model.routeCreator.cycleRoutes
                                                sRating
                                                tRating
                                                name
                                                desc
                                                quick
                                            )
                                            hideModel
                                in
                                    { createModel
                                        | switchStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.closed ]
                                                model.switchStyle
                                        , alertsStyle =
                                            Animation.interrupt
                                                [ Animation.to styles.closed ]
                                                model.alertsStyle
                                    }
                                        => Cmd.batch
                                            [ alertCmd
                                            , hideCmd
                                            , createCmd
                                            ]

                    cmd =
                        Cmd.batch
                            [ mainCmd
                            , Cmd.map MenuMsg menuCmd
                            ]
                in
                    { newModel | menu = menuModel } => cmd => NoOp


addAlert : Alert.Alert -> Model -> ( Model, Cmd Msg )
addAlert alert model =
    let
        ( newAlerts, alertCmd ) =
            Alert.update (AddAlert alert) model.alerts
    in
        { model | alerts = newAlerts } => Cmd.map AlertMsg alertCmd


hideAlert : Int -> Model -> ( Model, Cmd Msg )
hideAlert key model =
    let
        ( newAlerts, alertCmd ) =
            Alert.update (RemoveAlert key) model.alerts
    in
        { model | alerts = newAlerts } => Cmd.map AlertMsg alertCmd


updateRouteCreator : Session -> RouteCreator.Msg -> Model -> ( Model, Cmd Msg )
updateRouteCreator session subMsg model =
    let
        ( ( routeModel, routeCmd ), msgFromCreator ) =
            RouteCreator.update session subMsg model.routeCreator

        ( newModel, mainCmd ) =
            case msgFromCreator of
                RouteCreator.NoOp ->
                    model => Cmd.none

                RouteCreator.AddAlert alert ->
                    addAlert alert model

                RouteCreator.AnchorCount count ->
                    { model
                        | menu =
                            Menu.anchorCountUpdate count model.menu
                    }
                        => Cmd.none

        cmd =
            Cmd.batch
                [ mainCmd, Cmd.map RouteCreatorMsg routeCmd ]
    in
        { newModel | routeCreator = routeModel } => cmd


updateSegments : Session -> Segments.Msg -> Model -> ( Model, Cmd Msg )
updateSegments session subMsg model =
    let
        ( ( segmentsModel, segmentsCmd ), msgsFromSegments ) =
            Segments.update
                session
                model.mapBounds
                model.mapLayer
                subMsg
                model.segments

        ( newModel, mainCmd ) =
            List.foldl
                (\extMsg ( prevModel, prevCmd ) ->
                    let
                        ( nextModel, cmd ) =
                            processSegemntsExternalMsg extMsg model

                        nextCmd =
                            Cmd.batch [ prevCmd, cmd ]
                    in
                        ( nextModel, nextCmd )
                )
                ( model, Cmd.none )
                msgsFromSegments

        cmd =
            Cmd.batch
                [ mainCmd, Cmd.map SegmentsMsg segmentsCmd ]
    in
        { newModel | segments = segmentsModel } => cmd


processSegemntsExternalMsg : Segments.ExternalMsg -> Model -> ( Model, Cmd Msg )
processSegemntsExternalMsg msgFromSegments model =
    case msgFromSegments of
        Segments.AddAlert alert ->
            addAlert alert model

        Segments.HideAlert key ->
            hideAlert key model

        Segments.VisibleSegments visibleSegments ->
            let
                ( newMenu, menuCmd ) =
                    Menu.visibleSegmentsUpdate visibleSegments model.menu
            in
                { model | menu = newMenu } => Cmd.map MenuMsg menuCmd
