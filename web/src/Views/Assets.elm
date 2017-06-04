module Views.Assets exposing (error, stravaLogin, src)

{-| Assets, such as images, videos, and audio. (We only have images for now.)
We should never expose asset URLs directly; this module should be in charge of
all of them. One source of truth!
-}

import Html exposing (Html, Attribute)
import Html.Attributes as Attr


type Image
    = Image String



-- IMAGES --


error : Image
error =
    Image "/assets/img/error.jpg"


stravaLogin : Image
stravaLogin =
    Image "/assets/img/strava_login.svg"



-- USING IMAGES --


src : Image -> Attribute msg
src (Image url) =
    Attr.src url
