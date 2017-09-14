module Page.About exposing (view, update, Model, Msg, initModel)

import Html exposing (..)
import Stylesheets exposing (aboutNamespace, CssIds(..), CssClasses(..))


-- MODEL --


type alias Model =
    { errors : List String }


initModel : Model
initModel =
    { errors = []
    }



-- VIEW --


{ id, class, classList } =
    aboutNamespace


view : Model -> Html Msg
view model =
    div
        [ id Content, class [ CenterContent ] ]
        [ h2 [] [ text "About" ]
        , div []
            [ p [] [ text "The Road Quality Project is a platform that allows cyclists to crowd-source quality and safety information about cycling paths throughout their city." ]
            , p [] [ text "Once signed up, you are able to select and rate your favourite and most dreaded roadways to help fellow cyclists navigate your city!" ]
            ]
        ]



-- UPDATE --


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )
