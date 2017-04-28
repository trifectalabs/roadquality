port module Stylesheets exposing (..)

import Css exposing (..)
import Css.Elements exposing (body, div, input, label, button, select, textarea)
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
                , mapCss
                ]
          )
        ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure


mapNamespace : Namespace String class id msg
mapNamespace =
    withNamespace "map"


type CssIds
    = MainView
    | SaveRatingControl
    | NameInput
    | DescriptionInput
    | SurfaceInput
    | TrafficInput
    | SurfaceTypeInput
    | PathTypeInput


type CssClasses
    = DrawingSegment
    | MenuInput
    | DropInput


generalCss : Stylesheet
generalCss =
    stylesheet
        [ body
            [ margin zero
            , fontFamilies [ "Lato", "Arial", "Sans-serif" ]
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
            , padding (px 15)
            , boxSizing borderBox
            , textAlign center
            , property "transition" "height 1s"
            , withClass DrawingSegment
                [ height (px 420)
                , overflow hidden
                ]
            , children
                [ div
                    [ height (px 35)
                    , borderBottom3 (px 1) solid (rgb 200 200 200)
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
        ]
