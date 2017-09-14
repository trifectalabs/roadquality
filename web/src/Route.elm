module Route exposing (Route(..), href, modifyUrl, fromLocation)

import UrlParser as Url exposing (parsePath, parseHash, s, oneOf, Parser)
import Navigation exposing (Location)
import Html exposing (Attribute)
import Html.Attributes as Attr


-- ROUTING --


type Route
    = Home
    | Login
    | Logout
    | Register
    | Account
    | About


route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map Home (s "")
        , Url.map Login (s "login")
        , Url.map Logout (s "logout")
        , Url.map Register (s "register")
        , Url.map Account (s "account")
        , Url.map About (s "about")
        ]


pathRoute : Parser a a
pathRoute =
    s "app"



-- INTERNAL --


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Home ->
                    []

                Login ->
                    [ "login" ]

                Logout ->
                    [ "logout" ]

                Register ->
                    [ "register" ]

                Account ->
                    [ "account" ]

                About ->
                    [ "about" ]
    in
        "#/" ++ (String.join "/" pieces)



-- PUBLIC HELPERS --


href : Route -> Attribute msg
href route =
    Attr.href (routeToString route)


modifyUrl : Route -> Cmd msg
modifyUrl =
    routeToString >> Navigation.modifyUrl


fromLocation : Location -> Maybe Route
fromLocation location =
    if parsePath pathRoute location /= Nothing then
        if String.isEmpty location.hash then
            Just Home
        else
            parseHash route location
    else
        Nothing
