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
                , globalCss
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


globalNamespace : Namespace String class id msg
globalNamespace =
    withNamespace "global"


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
    | AddRatingButton
    | SaveRatingControl
    | NameInput
    | DescriptionInput
    | SurfaceInput
    | TrafficInput
    | SurfaceTypeInput
    | PathTypeInput
    | Content


type CssClasses
    = PrimaryButton
    | SecondaryButton
    | Active
    | Disabled
      -- Map Menu Classes
    | ProgressBar
    | NeedAnchorsControl
    | AddRatingsControl
    | AddTagsControl
    | AddNameControl
    | SurfaceRatingMenu
    | TrafficRatingMenu
    | SurfaceTypeMenu
    | PathTypeMenu
    | SegmentNameInput
    | SegmentDescriptionInput
      -- Page Frame Classes
    | PageFrame
    | NavBar
    | Brand
    | Nav
    | NavItem
    | NavLink
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


rgbElectricBlue : Color
rgbElectricBlue =
    rgb 2 75 141


rgbPacificBlue : Color
rgbPacificBlue =
    rgb 33 157 198


rgbLightBlue : Color
rgbLightBlue =
    rgb 152 210 235


rgbBlack : Color
rgbBlack =
    rgb 34 34 34


rgbDarkGray : Color
rgbDarkGray =
    rgb 102 102 102


rgbGray : Color
rgbGray =
    rgb 170 170 170


rgbLightGray : Color
rgbLightGray =
    rgb 204 204 204


rgbWhite : Color
rgbWhite =
    rgb 255 255 255


rgbOne : Color
rgbOne =
    rgb 110 32 32


rgbTwo : Color
rgbTwo =
    rgb 227 59 59


rgbThree : Color
rgbThree =
    rgb 255 166 0


rgbFour : Color
rgbFour =
    rgb 255 250 94


rgbFive : Color
rgbFive =
    rgb 48 219 60


lighter : Color -> Color
lighter { red, green, blue } =
    rgb
        (min 255 <| red + 20)
        (min 255 <| green + 20)
        (min 255 <| blue + 20)


darker : Color -> Color
darker { red, green, blue } =
    rgb
        (max 0 <| red - 20)
        (max 0 <| green - 20)
        (max 0 <| blue - 20)


addAlpha : Float -> Color -> Color
addAlpha alpha { red, green, blue } =
    rgba red green blue alpha


generalCss : Stylesheet
generalCss =
    stylesheet
        [ body
            [ margin zero
            , fontFamilies [ "Lato", "Arial", "Sans-serif" ]
            ]
        , class "fa"
            [ withClass "fa-times"
                [ fontSize (px 24)
                , position absolute
                , top (px 15)
                , left (px 15)
                , width (px 23)
                , lineHeight (px 21)
                , padding4 (px 5) (px 5) (px 7) (px 5)
                , textAlign center
                , cursor pointer
                , hover
                    [ borderRadius (pct 50)
                    , backgroundColor <| addAlpha 0.5 rgbWhite
                    , color rgbDarkGray
                    ]
                ]
            , withClass "fa-arrow-right"
                [ position absolute
                , top (px 15)
                , right (px 15)
                , borderRadius (pct 50)
                , fontSize (px 20)
                , lineHeight (px 21)
                , width (px 33)
                , padding4 (px 5) (px 5) (px 7) (px 7)
                , textAlign center
                , boxSizing borderBox
                ]
            , withClass "fa-check"
                [ position absolute
                , top (px 15)
                , right (px 15)
                , borderRadius (pct 50)
                , fontSize (px 20)
                , lineHeight (px 23)
                , width (px 23)
                , padding (px 5)
                , textAlign center
                ]
            , withClass "fa-arrow-left"
                [ position absolute
                , top (px 15)
                , left (px 15)
                , borderRadius (pct 50)
                , fontSize (px 20)
                , lineHeight (px 21)
                , width (px 33)
                , padding4 (px 5) (px 7) (px 7) (px 5)
                , textAlign center
                , boxSizing borderBox
                , cursor pointer
                , hover
                    [ borderRadius (pct 50)
                    , backgroundColor <| addAlpha 0.5 rgbWhite
                    , color rgbDarkGray
                    ]
                ]
            ]
        ]


globalCss : Stylesheet
globalCss =
    (stylesheet << namespace globalNamespace.name)
        [ class PrimaryButton
            [ padding2 (px 10) (px 20)
            , border zero
            , borderRadius (px 3)
            , backgroundColor rgbElectricBlue
            , color rgbWhite
            , boxShadow4 zero (px 1) (px 2) rgbDarkGray
            , cursor pointer
            , hover
                [ backgroundColor <| lighter rgbElectricBlue ]
            ]
        , class SecondaryButton
            [ padding2 (px 10) (px 20)
            , border3 (px 1) solid rgbGray
            , borderRadius (px 3)
            , backgroundColor rgbWhite
            , color rgbGray
            , cursor pointer
            , hover
                [ borderColor <| darker rgbGray
                , color <| darker rgbGray
                ]
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
        , id AddRatingButton
            [ position absolute
            , top (px 10)
            , left (px 10)
            ]
        , id SaveRatingControl
            [ position absolute
            , top zero
            , width (px 400)
            , height (pct 100)
            , backgroundColor (rgb 255 255 255)
            , boxShadow4 (px 1) zero (px 5) rgbDarkGray
            , overflow hidden
            , children
                [ div
                    [ backgroundColor rgbLightBlue ]
                ]
            , descendants
                [ h2
                    [ width (pct 100)
                    , textAlign center
                    , marginBottom zero
                    , fontSize (px 18)
                    , fontWeight (int 400)
                    ]
                , class ProgressBar
                    [ border3 (px 1) solid rgbBlack
                    , height (px 25)
                    , width (px 200)
                    , position absolute
                    , top (px 18)
                    , property "left" "calc(50% - 100px)"
                    , children
                        [ div
                            [ height (pct 100)
                            , width (px 33.3)
                            , backgroundColor rgbElectricBlue
                            ]
                        ]
                    ]
                , class Disabled
                    [ backgroundColor rgbLightGray
                    , color rgbGray
                    , cursor pointer
                    ]
                , class NeedAnchorsControl
                    [ padding3 (px 45) (px 15) (px 15)
                    , boxSizing borderBox
                    , children
                        [ h3
                            [ width (pct 100)
                            , textAlign center
                            , fontWeight (int 400)
                            ]
                        ]
                    ]
                , class AddRatingsControl
                    [ padding3 (px 45) (px 15) (px 15)
                    , boxSizing borderBox
                    ]

                -- , class AddTagsControl
                --     [ height (px 375) ]
                , class AddNameControl
                    [ padding3 (px 45) (px 25) (px 25) ]
                , class SurfaceRatingMenu
                    [ width (px 300)
                    , margin4 (px 40) auto (px 20) auto
                    , children
                        [ div
                            [ property "display" "inline-flex"
                            , width (px 46)
                            , height (px 46)
                            , borderRadius (px 3)
                            , alignItems center
                            , justifyContent center
                            , margin2 (px 10) (px 5)
                            , cursor pointer
                            , border3 (px 2) solid transparent
                            , withClass Active [ border3 (px 2) solid rgbWhite ]
                            , nthChild "2"
                                [ backgroundColor rgbOne
                                , hover [ backgroundColor <| darker rgbOne ]
                                ]
                            , nthChild "3"
                                [ backgroundColor rgbTwo
                                , hover [ backgroundColor <| darker rgbTwo ]
                                ]
                            , nthChild "4"
                                [ backgroundColor rgbThree
                                , hover [ backgroundColor <| darker rgbThree ]
                                ]
                            , nthChild "5"
                                [ backgroundColor rgbFour
                                , hover [ backgroundColor <| darker rgbFour ]
                                ]
                            , nthChild "6"
                                [ backgroundColor rgbFive
                                , hover [ backgroundColor <| darker rgbFive ]
                                ]
                            ]
                        ]
                    ]
                , class TrafficRatingMenu
                    [ width (px 300)
                    , margin2 zero auto
                    , children
                        [ div
                            [ property "display" "inline-flex"
                            , width (px 46)
                            , height (px 46)
                            , borderRadius (px 3)
                            , alignItems center
                            , justifyContent center
                            , margin2 (px 10) (px 5)
                            , cursor pointer
                            , border3 (px 2) solid transparent
                            , withClass Active [ border3 (px 2) solid rgbWhite ]
                            , nthChild "2"
                                [ backgroundColor rgbOne
                                , hover [ backgroundColor <| darker rgbOne ]
                                ]
                            , nthChild "3"
                                [ backgroundColor rgbTwo
                                , hover [ backgroundColor <| darker rgbTwo ]
                                ]
                            , nthChild "4"
                                [ backgroundColor rgbThree
                                , hover [ backgroundColor <| darker rgbThree ]
                                ]
                            , nthChild "5"
                                [ backgroundColor rgbFour
                                , hover [ backgroundColor <| darker rgbFour ]
                                ]
                            , nthChild "6"
                                [ backgroundColor rgbFive
                                , hover [ backgroundColor <| darker rgbFive ]
                                ]
                            ]
                        ]
                    ]

                -- , class SurfaceTypeMenu
                --     [ width (px 300)
                --     , margin3 (px 50) auto zero
                --     , children
                --         [ div
                --             [ property "display" "inline-flex"
                --             , width (px 126)
                --             , height (px 35)
                --             , borderRadius (px 3)
                --             , alignItems center
                --             , justifyContent center
                --             , margin (px 10)
                --             , cursor pointer
                --             , border3 (px 2) solid transparent
                --             , backgroundColor rgbElectricBlue
                --             , withClass Active [ border3 (px 2) solid rgbWhite ]
                --             , hover
                --                 [ backgroundColor <| lighter rgbElectricBlue ]
                --             ]
                --         ]
                --     ]
                -- , class PathTypeMenu
                --     [ width (px 300)
                --     , margin2 zero auto
                --     , children
                --         [ h4
                --             [ textAlign center
                --             , fontSize (px 16)
                --             , fontWeight (int 400)
                --             , margin4 (px 10) zero zero zero
                --             ]
                --         , div
                --             [ property "display" "inline-flex"
                --             , width (px 126)
                --             , height (px 40)
                --             , borderRadius (px 3)
                --             , alignItems center
                --             , justifyContent center
                --             , margin (px 10)
                --             , cursor pointer
                --             , border3 (px 2) solid transparent
                --             , backgroundColor rgbElectricBlue
                --             , withClass Active [ border3 (px 2) solid rgbWhite ]
                --             , hover
                --                 [ backgroundColor <| lighter rgbElectricBlue ]
                --             ]
                --         ]
                --     ]
                , class SegmentNameInput
                    [ margin3 (px 25) zero (px 10)
                    , children
                        [ span
                            [ display inlineBlock
                            , marginRight (px 10)
                            , verticalAlign middle
                            ]
                        , input
                            [ padding (px 5)
                            , borderRadius (px 3)
                            , border3 (px 1) solid rgbGray
                            , focus [ borderColor rgbDarkGray ]
                            , width (px 286)
                            ]
                        ]
                    ]
                , class SegmentDescriptionInput
                    [ children
                        [ span
                            [ display inlineBlock
                            , marginBottom (px 2)
                            ]
                        , textarea
                            [ width (pct 100)
                            , height (px 100)
                            , boxSizing borderBox
                            , resize none
                            , padding (px 5)
                            , borderRadius (px 3)
                            , border3 (px 1) solid rgbGray
                            , focus [ borderColor rgbDarkGray ]
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
