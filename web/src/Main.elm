module Main exposing (..)

import Page.Home as Home
import Page.Login as Login
import Page.Account as Account
import Page.About as About
import Page.Register as Register
import Page.Errored as Errored exposing (PageLoadError)
import Navigation exposing (Location, modifyUrl)
import Route exposing (Route)
import Ports
import Page.NotFound as NotFound
import Page.Errored as Errored exposing (PageLoadError)
import Views.Page as Page exposing (ActivePage)
import Data.User as User exposing (User)
import Json.Decode as Decode exposing (Value)
import Navigation exposing (load)
import Task
import Util exposing ((=>))
import Route exposing (Route)
import Data.User as User exposing (User, UserId)
import Data.Session as Session exposing (Session)
import Html exposing (..)
import Route exposing (Route)
import Html
import Regex exposing (HowMany(All), replace, regex)
import UrlParser as Url exposing ((<?>))


type Page
    = Blank
    | Frame
    | NotFound
    | Errored PageLoadError
    | Home Home.Model
    | Login Login.Model
    | Register Register.Model
    | Account Account.Model
    | About About.Model


type PageState
    = Loaded Page
    | TransitioningFrom Page



-- MODEL --


type alias Model =
    { session : Session
    , pageState : PageState
    }


init : Value -> Location -> ( Model, Cmd Msg )
init val location =
    let
        route =
            Route.fromLocation location

        apiUrl =
            if location.host == "localhost:9000" then
                "http://localhost:9001"
            else
                "https://api.roadquality.org"

        webUrl =
            if location.host == "localhost:9000" then
                "http://localhost:9000"
            else
                "https://roadquality.org"

        tokenInUrl =
            location
                |> Url.parsePath
                    (Url.s "app" <?> Url.stringParam "token")
                |> Maybe.withDefault Nothing

        newUrl =
            case tokenInUrl of
                Nothing ->
                    location.href

                Just _ ->
                    String.concat
                        [ location.origin
                        , location.pathname
                        , location.hash
                        ]

        ( model, routeCmd ) =
            setRoute route
                { pageState = Loaded <| initialPage route
                , session =
                    { user = decodeUserFromJson val
                    , apiUrl = apiUrl
                    , webUrl = webUrl
                    }
                }

        cmd =
            Cmd.batch [ modifyUrl newUrl, routeCmd ]
    in
        model => cmd


decodeUserFromJson : Value -> Maybe User
decodeUserFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.map (replace All (regex "&quot;") (\_ -> "\""))
        |> Maybe.andThen (Decode.decodeString User.decoder >> Result.toMaybe)


initialPage : Maybe Route -> Page
initialPage route =
    case route of
        Just Route.Home ->
            Blank

        _ ->
            Frame



-- VIEW --


view : Model -> Html Msg
view model =
    case model.pageState of
        Loaded page ->
            viewPage model.session False page

        TransitioningFrom page ->
            viewPage model.session True page


viewPage : Session -> Bool -> Page -> Html Msg
viewPage session isLoading page =
    let
        frame =
            Page.frame isLoading session.user
    in
        case page of
            NotFound ->
                NotFound.view session
                    |> frame Page.Other

            Blank ->
                Html.text ""

            Frame ->
                Html.text ""
                    |> frame Page.Other

            Errored subModel ->
                Errored.view session subModel
                    |> frame Page.Other

            Account subModel ->
                Account.view session subModel
                    |> frame Page.Account
                    |> Html.map AccountMsg

            About subModel ->
                About.view subModel
                    |> frame Page.About
                    |> Html.map AboutMsg

            Home subModel ->
                Home.view session subModel
                    |> Html.map HomeMsg

            Login subModel ->
                Login.view session subModel
                    |> frame Page.Login
                    |> Html.map LoginMsg

            Register subModel ->
                Register.view session subModel
                    |> frame Page.Register
                    |> Html.map RegisterMsg



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ pageSubscriptions (getPage model.pageState)
        , Sub.map SetUser sessionChange
        ]


sessionChange : Sub (Maybe User)
sessionChange =
    Ports.onSessionChange (Decode.decodeValue User.decoder >> Result.toMaybe)


getPage : PageState -> Page
getPage pageState =
    case pageState of
        Loaded page ->
            page

        TransitioningFrom page ->
            page


pageSubscriptions : Page -> Sub Msg
pageSubscriptions page =
    case page of
        Home model ->
            Home.subscriptions model
                |> Sub.map HomeMsg

        _ ->
            Sub.none



-- UPDATE --


type Msg
    = SetRoute (Maybe Route)
    | HomeLoaded (Result PageLoadError Home.Model)
    | HomeMsg Home.Msg
    | LoginMsg Login.Msg
    | RegisterMsg Register.Msg
    | AccountMsg Account.Msg
    | AboutMsg About.Msg
    | SetUser (Maybe User)


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    let
        transition toMsg task =
            { model | pageState = TransitioningFrom (getPage model.pageState) }
                => Task.attempt toMsg task

        errored =
            pageErrored model
    in
        case maybeRoute of
            Nothing ->
                { model | pageState = Loaded NotFound } => Ports.down ()

            Just Route.Login ->
                case model.session.user of
                    Just _ ->
                        let
                            ( newModel, transitionCmd ) =
                                transition HomeLoaded (Home.init model.session)

                            cmd =
                                Cmd.batch
                                    [ Route.modifyUrl Route.Home
                                    , transitionCmd
                                    ]
                        in
                            newModel => cmd

                    _ ->
                        { model | pageState = Loaded (Login Login.initModel) } => Ports.down ()

            Just Route.Logout ->
                let
                    session =
                        model.session
                in
                    { model | session = { session | user = Nothing } }
                        => Cmd.batch
                            [ Ports.storeSession Nothing
                            , Route.modifyUrl Route.Home
                            ]

            Just Route.Register ->
                case model.session.user of
                    Just _ ->
                        let
                            ( newModel, transitionCmd ) =
                                transition HomeLoaded (Home.init model.session)

                            cmd =
                                Cmd.batch
                                    [ Route.modifyUrl Route.Home
                                    , transitionCmd
                                    ]
                        in
                            newModel => cmd

                    _ ->
                        { model | pageState = Loaded (Register Register.initModel) } => Ports.down ()

            Just Route.Home ->
                transition HomeLoaded (Home.init model.session)

            Just Route.Account ->
                case model.session.user of
                    Just _ ->
                        { model | pageState = Loaded (Account Account.initModel) } => Ports.down ()

                    _ ->
                        { model | pageState = Loaded (Login Login.initModel) } => Ports.down ()

            Just Route.About ->
                { model | pageState = Loaded (About About.initModel) } => Ports.down ()


pageErrored : Model -> ActivePage -> String -> ( Model, Cmd msg )
pageErrored model activePage errorMessage =
    let
        error =
            Errored.pageLoadError activePage errorMessage
    in
        { model | pageState = Loaded (Errored error) } => Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updatePage (getPage model.pageState) msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    let
        session =
            model.session

        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                ( { model | pageState = Loaded (toModel newModel) }, Cmd.map toMsg newCmd )

        errored =
            pageErrored model
    in
        case ( msg, page ) of
            ( SetRoute route, _ ) ->
                setRoute route model

            ( HomeLoaded (Ok subModel), _ ) ->
                { model | pageState = Loaded (Home subModel) }
                    => Ports.up
                        (Maybe.map
                            (\u -> ( u.city, u.province, u.country ))
                            session.user
                        )

            ( HomeLoaded (Err error), _ ) ->
                { model | pageState = Loaded (Errored error) } => Cmd.none

            ( HomeMsg subMsg, Home subModel ) ->
                let
                    ( ( pageModel, homeCmd ), msgFromPage ) =
                        Home.update session subMsg subModel

                    ( newModel, mainCmd ) =
                        case msgFromPage of
                            Home.NoOp ->
                                model => Cmd.none

                            Home.Unauthorized ->
                                let
                                    session =
                                        model.session
                                in
                                    { model
                                        | session = { session | user = Nothing }
                                    }
                                        => Cmd.batch
                                            [ Ports.storeSession Nothing
                                            , Route.modifyUrl Route.Login
                                            ]

                    cmd =
                        Cmd.batch
                            [ mainCmd
                            , Cmd.map HomeMsg homeCmd
                            ]
                in
                    { newModel | pageState = Loaded (Home pageModel) } => cmd

            ( LoginMsg subMsg, Login subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        Login.update session.apiUrl subMsg subModel

                    newModel =
                        case msgFromPage of
                            Login.NoOp ->
                                model

                            Login.SetUser user ->
                                let
                                    session =
                                        model.session
                                in
                                    { model
                                        | session =
                                            { user = Just user
                                            , apiUrl = session.apiUrl
                                            , webUrl = session.webUrl
                                            }
                                        , pageState = Loaded (Login pageModel)
                                    }
                in
                    newModel => Cmd.map LoginMsg cmd

            ( RegisterMsg subMsg, Register subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        Register.update session.apiUrl subMsg subModel

                    newModel =
                        case msgFromPage of
                            Register.NoOp ->
                                model

                            Register.SetUser user ->
                                let
                                    session =
                                        model.session
                                in
                                    { model
                                        | session =
                                            { user = Just user
                                            , apiUrl = session.apiUrl
                                            , webUrl = session.webUrl
                                            }
                                        , pageState =
                                            Loaded (Register pageModel)
                                    }
                in
                    newModel => Cmd.map RegisterMsg cmd

            ( AccountMsg subMsg, Account subModel ) ->
                toPage Account AccountMsg (Account.update session) subMsg subModel

            ( AboutMsg subMsg, About subModel ) ->
                toPage About AboutMsg About.update subMsg subModel

            ( SetUser user, _ ) ->
                let
                    session =
                        model.session
                in
                    { model | session = { session | user = user } }
                        => Cmd.none

            ( _, NotFound ) ->
                -- Disregard incoming messages when we're on the
                -- NotFound page.
                model => Cmd.none

            ( _, _ ) ->
                -- Disregard incoming messages that arrived for the wrong page
                model => Cmd.none



-- MAIN --


main : Program Value Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
