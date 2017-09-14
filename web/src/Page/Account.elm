module Page.Account exposing (view, update, Model, Msg, initModel)

import Html exposing (..)
import Data.Session as Session exposing (Session)
import Date.Format exposing (format)
import Data.UserPhoto as UserPhoto
import Stylesheets exposing (accountNamespace, CssIds(..), CssClasses(..))


-- MODEL --


type alias Model =
    { errors : List String }


initModel : Model
initModel =
    { errors = []
    }



-- VIEW --


{ id, class, classList } =
    accountNamespace


view : Session -> Model -> Html Msg
view session model =
    case session.user of
        Nothing ->
            div [] []

        Just user ->
            let
                name =
                    String.join " " [ user.firstName, user.lastName ]

                location =
                    Maybe.map3
                        (\city province country ->
                            String.join ", " [ city, province, country ]
                        )
                        user.city
                        user.province
                        user.country
                        |> Maybe.withDefault "Not Specified"

                birthdate =
                    user.birthdate
                        |> Maybe.map (format "%B %e, %Y")
                        |> Maybe.withDefault "Not Specified"

                sex =
                    user.sex
                        |> Maybe.withDefault "Not Specified"
            in
                div
                    [ id Content, class [ CenterContent ] ]
                    [ h2 [] [ text "Account" ]
                    , div []
                        [ img [ UserPhoto.src user.photo ] []
                        , h3 [] [ text name ]
                        , div [] [ span [] [ text "Email" ], span [] [ text user.email ] ]
                        , div [] [ span [] [ text "Location" ], span [] [ text location ] ]
                        , div [] [ span [] [ text "Birthdate" ], span [] [ text birthdate ] ]
                        , div [] [ span [] [ text "Sex" ], span [] [ text sex ] ]
                        ]
                    ]



-- UPDATE --


type Msg
    = NoOp


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    ( model, Cmd.none )
