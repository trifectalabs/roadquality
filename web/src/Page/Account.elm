module Page.Account exposing (view, update, Model, Msg, initModel)

import Html exposing (..)
import Data.Session as Session exposing (Session)
import Date.Format exposing (format)
import Data.User exposing (userIdToHtml)
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
                birthday =
                    user.birthdate
                        |> Maybe.map (format "%B %e, %Y")
                        |> Maybe.withDefault "Unknown"

                sex =
                    user.sex
                        |> Maybe.withDefault "Unknown"

                city =
                    user.city
                        |> Maybe.withDefault "Unknown"

                province =
                    user.province
                        |> Maybe.withDefault "Unknown"

                country =
                    user.country
                        |> Maybe.withDefault "Unknown"
            in
                div
                    [ id Content, class [ Account ] ]
                    [ img [ UserPhoto.src user.photo ] []
                    , div [] [ span [] [ text "Id" ], userIdToHtml user.id ]
                    , div [] [ span [] [ text "First Name" ], text user.firstName ]
                    , div [] [ span [] [ text "Last Name" ], text user.lastName ]
                    , div [] [ span [] [ text "Email" ], text user.email ]
                    , div [] [ span [] [ text "City" ], text city ]
                    , div [] [ span [] [ text "Province" ], text province ]
                    , div [] [ span [] [ text "Country" ], text country ]
                    , div [] [ span [] [ text "Birthday" ], text birthday ]
                    , div [] [ span [] [ text "Sex" ], text sex ]
                    , div [] [ span [] [ text "Role" ], text user.role ]
                    ]



-- UPDATE --


type Msg
    = NoOp


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    ( model, Cmd.none )
