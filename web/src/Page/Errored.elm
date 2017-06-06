module Page.Errored exposing (view, pageLoadError, PageLoadError)

import Html exposing (Html, main_, h1, div, img, text, p)
import Data.Session as Session exposing (Session)
import Views.Page as Page exposing (ActivePage)
import Stylesheets exposing (loginNamespace, CssIds(..), CssClasses(..))


-- MODEL --


type PageLoadError
    = PageLoadError Model


type alias Model =
    { activePage : ActivePage
    , errorMessage : String
    }


pageLoadError : ActivePage -> String -> PageLoadError
pageLoadError activePage errorMessage =
    PageLoadError { activePage = activePage, errorMessage = errorMessage }



-- VIEW --


{ id, class, classList } =
    loginNamespace


view : Session -> PageLoadError -> Html msg
view session (PageLoadError model) =
    div [ id Content, class [ ServerError ] ]
        [ h1 [] [ text "Whoops! Error Loading Page :(" ]
        , div []
            [ p [] [ text model.errorMessage ] ]
        ]
