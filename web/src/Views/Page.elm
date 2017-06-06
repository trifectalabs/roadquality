module Views.Page exposing (frame, ActivePage(..))

{-| The frame around a typical page - that is, the header and footer.
-}

import Route exposing (Route)
import Route exposing (Route)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Route exposing (Route)
import Data.User as User exposing (User, UserId)
import Html
import Html.Lazy exposing (lazy2)
import Views.Spinner exposing (spinner)
import Util exposing ((=>))
import Stylesheets exposing (frameNamespace, CssIds(..), CssClasses(..))


{ id, class, classList } =
    frameNamespace


{-| Determines which navbar link (if any) will be rendered as active.
Note that we don't enumerate every page here, because the navbar doesn't
have links for every page. Anything that's not part of the navbar falls
under Other.
-}
type ActivePage
    = Other
    | Home
    | Login
    | Register
    | Account


{-| Take a page's Html and frame it with a header and footer.
The caller provides the current user, so we can display in either
"signed in" (rendering username) or "signed out" mode.
isLoading is for determining whether we should show a loading spinner
in the header. (This comes up during slow page transitions.)
-}
frame : Bool -> Maybe User -> ActivePage -> Html msg -> Html msg
frame isLoading user page content =
    div [ class [ PageFrame ] ]
        [ viewHeader page user isLoading
        , content
        , viewFooter
        ]


viewHeader : ActivePage -> Maybe User -> Bool -> Html msg
viewHeader page user isLoading =
    nav [ class [ NavBar ] ]
        [ div []
            [ a [ class [ Brand, LogoFont ], Route.href Route.Home ]
                [ text "Road Quality" ]
            , ul [ class [ Nav ] ] <|
                -- TODO: add loading spinner to main map ui
                lazy2 Util.viewIf isLoading spinner
                    :: (navbarLink (page == Home) Route.Home [ text "Home" ])
                    :: viewSignIn page user
            ]
        ]


viewSignIn : ActivePage -> Maybe User -> List (Html msg)
viewSignIn page user =
    case user of
        Nothing ->
            [ navbarLink (page == Login) Route.Login [ text "Sign in" ]
              -- , navbarLink (page == Register) Route.Register [ text "Sign up" ]
            ]

        Just user ->
            [ navbarLink (page == Account) Route.Account [ text "Account" ]
            , navbarLink False Route.Logout [ text "Sign out" ]
            ]


viewFooter : Html msg
viewFooter =
    footer []
        [ div []
            [ a
                [ class [ LogoFont ], Route.href Route.Home ]
                [ text "Road Quality" ]
            , span [ class [ Attribution ] ]
                [ text "© 2017 A project from "
                , a [ href "https://trifectalabs.com" ] [ text "Trifecta Labs" ]
                , text ". Code & design licensed under "
                , a [ href "https://github.com/trifectalabs/roadquality/blob/master/LICENSE" ] [ text "MIT" ]
                , text "."
                ]
            ]
        ]


navbarLink : Bool -> Route -> List (Html msg) -> Html msg
navbarLink isActive route linkContent =
    li [ classList [ ( NavItem, True ), ( Active, isActive ) ] ]
        [ a [ class [ NavLink ], Route.href route ] linkContent ]
