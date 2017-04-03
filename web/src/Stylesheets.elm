port module Stylesheets exposing (..)

import Css exposing (..)
import Css.File exposing (CssFileStructure, CssCompilerProgram)
import Css.Namespace exposing (namespace)
import Html.CssHelpers exposing (withNamespace, Namespace)


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "main.css", Css.File.compile [ css ] ) ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure


mapNamespace : Namespace String class id msg
mapNamespace =
    withNamespace "map"


type CssIds
    = MainView


css : Stylesheet
css =
    (stylesheet << namespace mapNamespace.name)
        [ id MainView [ height (px 400) ]
        ]
