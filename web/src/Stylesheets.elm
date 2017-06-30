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
                , messagesCss
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


messagesNamespace : Namespace String class id msg
messagesNamespace =
    withNamespace "msg"


type CssIds
    = MainView
    | MapLegend
    | MapSwitcher
    | AddRatingButton
    | SaveRatingControl
    | NameInput
    | DescriptionInput
    | SurfaceInput
    | TrafficInput
    | SurfaceTypeInput
    | PathTypeInput
    | Content
    | MessagesContainer
    | EmailListBanner


type CssClasses
    = PrimaryButton
    | SecondaryButton
    | SymbolButton
    | Active
    | Disabled
      -- Map Menu Classes
    | CloseMenu
    | BackMenu
    | NextMenu
    | ProgressDots
    | ProgressBar
    | RatingsMenu
    | RatingsControl
    | RatingInfo
    | RatingsSummary
    | SegmentNameInput
    | SegmentDescriptionInput
    | SaveButton
    | SegmentInfo
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
      -- Messages
    | InfoMessage
    | WarningMessage
    | ErrorMessage
    | LoadingMessage


rgbTrifectaBrightGreen : Color
rgbTrifectaBrightGreen =
    rgb 127 217 55


rgbTrifectaGreen : Color
rgbTrifectaGreen =
    rgb 22 146 71


rgbTrifectaLightGreen : Color
rgbTrifectaLightGreen =
    rgb 176 215 51


rgbBlack : Color
rgbBlack =
    rgb 44 44 44


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


rgbSurfaceOne : Color
rgbSurfaceOne =
    rgb 166 3 15


rgbSurfaceTwo : Color
rgbSurfaceTwo =
    rgb 198 97 22


rgbSurfaceThree : Color
rgbSurfaceThree =
    rgb 230 180 28


rgbSurfaceFour : Color
rgbSurfaceFour =
    rgb 100 180 28


rgbSurfaceFive : Color
rgbSurfaceFive =
    rgb 60 145 50


rgbTrafficOne : Color
rgbTrafficOne =
    rgb 252 0 0


rgbTrafficTwo : Color
rgbTrafficTwo =
    rgb 189 0 63


rgbTrafficThree : Color
rgbTrafficThree =
    rgb 126 0 126


rgbTrafficFour : Color
rgbTrafficFour =
    rgb 63 0 189


rgbTrafficFive : Color
rgbTrafficFive =
    rgb 0 0 252


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
        , class "default-cursor" [ cursor default |> important ]
        , class "move-cursor" [ cursor move |> important ]
        , class "grab-cursor"
            [ cursor grab |> important
            , property "cursor" "-webkit-grab" |> important
            , property "cursor" "-moz-grab" |> important
            ]
        , class "grabbing-cursor"
            [ cursor grabbing |> important
            , property "cursor" "-webkit-grabbing" |> important
            , property "cursor" "-moz-grabbing" |> important
            ]
        ]


globalCss : Stylesheet
globalCss =
    (stylesheet << namespace globalNamespace.name)
        [ class PrimaryButton
            [ padding2 (px 10) (px 20)
            , display inlineBlock
            , border zero
            , borderRadius (px 3)
            , backgroundColor rgbTrifectaGreen
            , color rgbWhite
            , boxShadow4 zero (px 1) (px 2) rgbDarkGray
            , cursor pointer
            , hover
                [ backgroundColor <| darker rgbTrifectaGreen ]
            , active
                [ position relative
                , top (px 2)
                , left (px 2)
                , boxShadow3 zero zero zero
                , backgroundColor <| darker rgbTrifectaGreen
                ]
            ]
        , class SecondaryButton
            [ padding2 (px 10) (px 20)
            , display inlineBlock
            , borderRadius (px 3)
            , backgroundColor rgbWhite
            , color rgbTrifectaGreen
            , boxShadow4 zero (px 1) (px 2) rgbDarkGray
            , cursor pointer
            , hover
                [ backgroundColor <| darker rgbWhite ]
            , active
                [ position relative
                , top (px 2)
                , left (px 2)
                , boxShadow3 zero zero zero
                , backgroundColor <| darker rgbWhite
                ]
            ]
        , class SymbolButton
            [ width (px 30)
            , height (px 30)
            , padding zero
            , borderRadius (pct 50)
            , property "display" "flex"
            , justifyContent center
            , alignItems center
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


messagesCss : Stylesheet
messagesCss =
    (stylesheet << namespace messagesNamespace.name)
        [ id MessagesContainer
            [ width (px 500)
            , position fixed
            , top (px 55)
            , property "left" "calc(50% - 250px)"
            , children
                [ div
                    [ width (px 450)
                    , marginTop (px 10)
                    , padding4 (px 15) (px 35) (px 15) (px 15)
                    , position relative
                    , borderRadius (px 2)
                    , withClass InfoMessage
                        [ backgroundColor (rgb 217 237 247)
                        , border3 (px 1) solid (rgb 202 234 244)
                        , color (rgb 49 114 150)
                        ]
                    , withClass WarningMessage
                        [ backgroundColor (rgb 252 248 227)
                        , border3 (px 1) solid (rgb 251 241 215)
                        , color (rgb 138 109 59)
                        ]
                    , withClass ErrorMessage
                        [ backgroundColor (rgb 242 222 222)
                        , border3 (px 1) solid (rgb 235 204 204)
                        , color (rgb 132 53 52)
                        ]
                    , withClass LoadingMessage
                        [ backgroundColor (rgb 217 237 247)
                        , border3 (px 1) solid (rgb 202 234 244)
                        , color (rgb 49 114 150)
                        , children
                            [ li
                                [ listStyle none
                                , position absolute
                                , right zero
                                , top (px -5)
                                ]
                            ]
                        ]
                    , children
                        [ div
                            []
                        , svg
                            [ position absolute
                            , top (px 15)
                            , right (px 15)
                            , cursor pointer
                            ]
                        ]
                    ]
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
        , id EmailListBanner
            [ position fixed
            , left zero
            , right zero
            , bottom zero
            , height (px 50)
            , padding4 (px 20) (px 15) (px 15) (px 15)
            , backgroundColor rgbBlack
            , color rgbWhite
            , children
                [ div
                    [ margin2 zero auto
                    , width (px 871)
                    , children
                        [ span
                            [ display inlineBlock
                            , maxWidth (px 500)
                            , marginRight (px 5)
                            ]
                        , input
                            [ padding (px 10)
                            , width (px 200)
                            , borderRadius (px 2)
                            , border3 (px 1) solid rgbLightGray
                            , verticalAlign textBottom
                            , marginRight (px 5)
                            , fontSize (px 14)
                            , focus
                                [ borderColor rgbDarkGray
                                , outline none
                                ]
                            ]
                        , div
                            [ verticalAlign textBottom ]
                        ]
                    ]
                ]
            ]
        , id AddRatingButton
            [ position absolute
            , top (px 10)
            , left (px 10)
            , zIndex (int 2)
            , active
                [ position absolute
                , top (px 12)
                , left (px 12)
                ]
            ]
        , id MapSwitcher
            [ position absolute
            , top zero
            , left zero
            , right zero
            , zIndex (int 1)
            , children
                [ div
                    [ margin3 (px 10) auto zero
                    , width (px 300)
                    , children
                        [ div
                            [ position relative
                            , width (px 150)
                            , boxSizing borderBox
                            , textAlign center
                            , firstChild
                                [ borderTopRightRadius zero
                                , borderBottomRightRadius zero
                                ]
                            , lastChild
                                [ borderTopLeftRadius zero
                                , borderBottomLeftRadius zero
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        , id MapLegend
            [ position absolute
            , top (px 75)
            , left (px 10)
            , width (px 36)
            , borderRadius (px 18)
            ]
        , id SaveRatingControl
            [ position absolute
            , top zero
            , width (px 400)
            , height (pct 100)
            , backgroundColor (rgb 255 255 255)
            , boxShadow4 (px 1) zero (px 5) rgbDarkGray
            , overflow hidden
            , zIndex (int 3)
            , descendants
                [ h2
                    [ width (px 250)
                    , fontSize (px 24)
                    , fontWeight (int 400)
                    , margin4 (px 10) zero (px 25) zero
                    , children
                        [ span [ fontWeight (int 700) ] ]
                    ]
                , class CloseMenu
                    [ position absolute
                    , top (px 15)
                    , right (px 15)
                    , cursor pointer
                    , zIndex (int 2)
                    , hover
                        [ backgroundColor <| addAlpha 0.5 rgbLightGray ]
                    ]
                , class BackMenu
                    [ position absolute
                    , left (px 15)
                    , bottom (px -9)
                    , active
                        [ position absolute
                        , top initial
                        , left (px 17)
                        , bottom (px -11)
                        ]
                    ]
                , class NextMenu
                    [ position absolute
                    , right (px 15)
                    , bottom (px -9)
                    , active
                        [ position absolute
                        , top initial
                        , left initial
                        , right (px 13)
                        , bottom (px -11)
                        ]
                    ]
                , class ProgressBar
                    [ position absolute
                    , bottom (px 30)
                    , width (pct 100)
                    ]
                , class ProgressDots
                    [ display block
                    , margin2 zero auto
                    , width (px 100)
                    , children
                        [ span
                            [ fontSize (px 8)
                            , color rgbLightGray
                            , display inlineBlock
                            , margin2 zero (px 5)
                            , withClass Active
                                [ color rgbTrifectaGreen ]
                            ]
                        ]
                    ]
                , class Disabled
                    [ display none ]
                , class RatingsMenu
                    [ marginTop (vh 30)
                    , marginLeft (px 50)
                    , children
                        [ div
                            [ firstChild
                                [ width (px 125)
                                , height (px 8)
                                , backgroundColor rgbTrifectaGreen
                                ]
                            ]
                        ]
                    ]
                , class RatingsControl
                    [ display block
                    , width (px 160)
                    , height (px 40)
                    , children
                        [ span
                            [ cursor pointer
                            , fontSize (px 32)
                            , color rgbLightGray
                            , active
                                [ position relative
                                , top (px 2)
                                , left (px 2)
                                ]
                            ]
                        ]
                    ]
                , class RatingInfo
                    [ marginTop (px 5)
                    , width (px 300)
                    , fontSize (px 16)
                    , fontWeight (int 300)
                    ]
                , class RatingsSummary
                    [ backgroundColor rgbTrifectaGreen
                    , color rgbWhite
                    , padding2 (px 50) (px 15)
                    , position relative
                    , children
                        [ div
                            [ display inlineBlock
                            , width (px 185)
                            , fontSize (px 22)
                            , fontWeight (int 300)
                            , verticalAlign middle
                            ]
                        , class SaveButton
                            [ position absolute
                            , bottom (px -20)
                            , right (px 25)
                            , active
                                [ position absolute
                                , bottom (px -22)
                                , right (px 23)
                                , top initial
                                , left initial
                                ]
                            ]
                        ]
                    ]
                , class SegmentNameInput
                    [ margin3 (px 80) (px 25) (px 15)
                    , padding (px 8)
                    , width (px 350)
                    , boxSizing borderBox
                    , border zero
                    , borderBottom3 (px 3) solid rgbTrifectaGreen
                    , fontSize (px 18)
                    , backgroundColor <| darker rgbWhite
                    ]
                , class SegmentDescriptionInput
                    [ margin3 zero (px 25) (px 15)
                    , padding (px 8)
                    , width (px 350)
                    , height (px 100)
                    , boxSizing borderBox
                    , resize none
                    , border zero
                    , borderBottom3 (px 3) solid rgbTrifectaGreen
                    , fontSize (px 18)
                    , backgroundColor <| darker rgbWhite
                    , fontFamilies [ "Lato", "Arial", "Sans-serif" ]
                    ]
                , class SaveButton
                    [ marginLeft (px 215) ]
                , class SegmentInfo
                    [ marginTop (px 50)
                    , children
                        [ h3
                            [ textAlign center
                            , fontSize (px 20)
                            , fontWeight (int 700)
                            ]
                        , h4
                            [ textAlign center
                            , margin2 (px 10) (px 25)
                            , fontSize (px 16)
                            , fontWeight (int 400)
                            ]
                        ]
                    ]
                ]
            ]
        , class GoToAccount
            [ position absolute
            , top (px 10)
            , right (px 10)
            , zIndex (int 2)
            ]
        , div
            [ withClass GoToAccount
                [ active
                    [ position absolute
                    , top (px 12)
                    , right (px 8)
                    , left initial
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
