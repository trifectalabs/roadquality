port module Stylesheets exposing (..)

import Css exposing (..)
import Css.Elements exposing (..)
import Css.File exposing (CssFileStructure, CssCompilerProgram)
import Css.Namespace exposing (namespace)
import Html.CssHelpers exposing (withNamespace, Namespace)


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "../../stylesheets/main.css"
          , Css.File.compile
                [ generalCss
                , frameCss
                , loginCss
                , errorCss
                , mapCss
                , accountCss
                ]
          )
        ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure


mapNamespace : Namespace String class id msg
mapNamespace =
    withNamespace "map"


loginNamespace : Namespace String class id msg
loginNamespace =
    withNamespace "login"


frameNamespace : Namespace String class id msg
frameNamespace =
    withNamespace "frame"


errorNamespace : Namespace String class id msg
errorNamespace =
    withNamespace "error"


accountNamespace : Namespace String class id msg
accountNamespace =
    withNamespace "account"


type CssIds
    = MainView
    | TrifectaAffiliate
    | SaveRatingControl
    | NameInput
    | DescriptionInput
    | SurfaceInput
    | TrafficInput
    | SurfaceTypeInput
    | PathTypeInput
    | Content


type
    CssClasses
    -- Map Menu Classes
    = DrawingSegment
    | MenuInput
    | DropInput
      -- Page Frame Classes
    | PageFrame
    | NavBar
    | Brand
    | Nav
    | NavItem
    | NavLink
    | Active
    | LogoFont
    | Attribution
      -- Auth Form Classes
    | ErrorMessages
    | FormGroup
    | FormControl
      -- Content Classes
    | NotFound
    | ServerError
    | Login
    | Account
      -- Account
    | GoToAccount


generalCss : Stylesheet
generalCss =
    stylesheet
        [ body
            [ margin zero
            , fontFamilies [ "Lato", "Arial", "Sans-serif" ]
            ]
        ]


frameCss : Stylesheet
frameCss =
    (stylesheet << namespace frameNamespace.name)
        [ id Content
            [ property "min-height" "calc(100vh - 120px)"
            , padding (px 40)
            , boxSizing borderBox
            ]
        , class LogoFont
            [ fontFamilies [ "Lato" ]
            , fontSize (px 24)
            , fontWeight (int 900)
            , textDecoration none
            , color (rgb 80 80 80)
            , textTransform lowercase
            ]
        , class NavBar
            [ borderBottom3 (px 1) solid (rgb 225 225 225)
            , descendants
                [ class Brand
                    [ display inlineBlock
                    , padding4 (px 15) (px 15) (px 15) (px 40)
                    , margin zero
                    ]
                , ul
                    [ withClass Nav
                        [ listStyle none
                        , float right
                        , padding4 zero (px 25) zero zero
                        , margin zero
                        , children
                            [ class NavItem
                                [ display inlineBlock
                                , padding2 (px 20) (px 15)
                                , fontSize (px 16)
                                , withClass Active
                                    [ children
                                        [ class NavLink
                                            [ textDecoration none
                                            , color (rgb 22 146 72)
                                            ]
                                        ]
                                    ]
                                , children
                                    [ class NavLink
                                        [ textDecoration none
                                        , color (rgb 80 80 80)
                                        , hover
                                            [ color (rgb 22 146 72) ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        , footer
            [ borderTop3 (px 1) solid (rgb 225 225 225)
            , descendants
                [ class LogoFont
                    [ display inlineBlock
                    , padding4 (px 15) (px 15) (px 15) (px 40)
                    ]
                , class Attribution
                    [ children
                        [ a
                            [ textDecoration none
                            , color (rgb 22 146 72)
                            , hover
                                [ color (rgb 127 217 55) ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


loginCss : Stylesheet
loginCss =
    (stylesheet << namespace loginNamespace.name)
        [ class Login
            [ children
                [ a
                    [ display block
                    , margin2 (px 30) zero
                    , textAlign center
                    , focus
                        [ outline none ]
                    , active
                        [ outline none ]
                    , children
                        [ img
                            [ width (px 200) ]
                        ]
                    ]
                ]
            ]
        ]


errorCss : Stylesheet
errorCss =
    (stylesheet << namespace errorNamespace.name)
        [ class NotFound
            [ descendants
                [ h1
                    [ textAlign center
                    , children
                        [ a
                            [ textDecoration none
                            , color (rgb 22 146 72)
                            , hover
                                [ color (rgb 127 217 55) ]
                            ]
                        ]
                    ]
                , img
                    [ width (pct 100) ]
                ]
            ]
        , class ServerError
            [ descendants
                [ h1
                    [ textAlign center ]
                ]
            ]
        ]


accountCss : Stylesheet
accountCss =
    (stylesheet << namespace accountNamespace.name)
        [ class Account
            [ padding4 (px 40) zero zero (px 50)
            , descendants
                [ img
                    [ width (px 50) ]
                , div
                    [ marginTop (px 10) ]
                , span
                    [ fontWeight (int 700)
                    , marginRight (px 5)
                    ]
                ]
            ]
        ]


mapCss : Stylesheet
mapCss =
    (stylesheet << namespace mapNamespace.name)
        [ id MainView
            [ height (vh 100)
            , width (vw 100)
            , zIndex (int 0)
            ]
        , id TrifectaAffiliate
            [ position fixed
            , bottom (px -5)
            , property "left" "calc(50% - 75px)"
            , width (px 150)
            , textAlign center
            , children
                [ a
                    [ textDecoration none
                    , children
                        [ img
                            [ height (px 35)
                            ]
                        , span
                            [ height (px 24)
                            , fontWeight (int 700)
                            , verticalAlign top
                            , lineHeight (px 35)
                            , marginLeft (px 5)
                            , color (rgb 0 0 0)
                            ]
                        ]
                    ]
                ]
            ]
        , id SaveRatingControl
            [ position absolute
            , top (px 10)
            , left (px 10)
            , width (px 375)
            , height (px 50)
            , backgroundColor (rgb 255 255 255)
            , zIndex (int 1)
            , borderRadius (px 2)
            , boxShadow4 zero (px 2) (px 4) (rgba 0 0 0 0.2)
            , boxSizing borderBox
            , textAlign center
            , property "transition" "height 1s"
            , withClass DrawingSegment
                [ height (px 275)
                , overflow hidden
                ]
            , children
                [ div
                    [ height (px 20)
                    , borderBottom3 (px 1) solid (rgb 200 200 200)
                    , padding (px 15)
                    , backgroundColor (rgb 255 255 255)
                    ]
                , button
                    [ marginTop (px 10)
                    , borderRadius (px 2)
                    , padding2 (px 5) (px 10)
                    , marginRight (px 10)
                    , fontSize (px 16)
                    , border3 (px 1) solid (rgb 200 200 200)
                    , backgroundColor (rgb 255 255 255)
                    , focus [ outline none ]
                    , hover [ backgroundColor (rgb 235 235 235) ]
                    , active [ backgroundColor (rgb 215 215 215) ]
                    ]
                , label
                    [ display inlineBlock
                    , width (px 91)
                    , textAlign right
                    , padding4 (px 15) (px 10) zero zero
                    , verticalAlign top
                    ]
                , textarea
                    [ resize none
                    , withClass MenuInput
                        [ padding (px 5)
                        , height (px 75)
                        ]
                    ]
                , class MenuInput
                    [ height (px 30)
                    , fontSize (px 16)
                    , width (px 200)
                    , display inlineBlock
                    , marginTop (px 10)
                    , padding2 zero (px 5)
                    , borderRadius (px 2)
                    , border3 (px 1) solid (rgb 200 200 200)
                    , focus [ outline none ]
                    ]
                , class DropInput
                    [ backgroundColor (hex "fafafa")
                    , backgroundImage (url "/assets/img/down.png")
                    , backgroundRepeat noRepeat
                    , backgroundPosition2 (pct 90) (pct 50)
                    , children
                        [ select
                            [ width (pct 100)
                            , border zero
                            , boxShadow none
                            , backgroundColor transparent
                            , backgroundImage <| url ""
                            , property "-webkit-appearance" "none"
                            , padding2 (px 5) (px 8)
                            , fontSize (px 16)
                            , focus [ outline none ]
                            ]
                        ]
                    ]
                ]
            ]
        , class GoToAccount
            [ position absolute
            , top (px 15)
            , right (px 15)
            ]
        , div
            [ withClass GoToAccount
                [ padding2 (px 5) (px 10)
                , top (px 20)
                , border3 (px 1) solid (rgb 80 80 80)
                , borderRadius (px 2)
                , color (rgb 80 80 80)
                , hover
                    [ color (rgb 22 146 72)
                    , borderColor (rgb 22 146 72)
                    ]
                ]
            ]
        , img
            [ withClass GoToAccount
                [ width (px 40)
                , height (px 40)
                , borderRadius (pct 50)
                ]
            ]
        ]
