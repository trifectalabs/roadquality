module Data.User exposing (User, UserId, decoder, encode, userIdToString, userIdParser, userIdToHtml, userIdDecoder)

import Data.AuthToken as AuthToken exposing (AuthToken)
import Data.UserPhoto as UserPhoto exposing (UserPhoto, missingPhoto)
import Data.Date exposing (encodeDate, decodeDate)
import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required, optional)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import UrlParser
import Util exposing ((=>))
import Html exposing (Html)


type alias User =
    { id : UserId
    , token : AuthToken
    , firstName : String
    , lastName : String
    , email : String
    , photo : UserPhoto
    , birthdate : Maybe Date
    , sex : Maybe String
    , stravaToken : String
    , role : String
    , createdAt : Date
    , updatedAt : Date
    }



-- SERIALIZATION --


decoder : Decoder User
decoder =
    decode User
        |> required "id" userIdDecoder
        |> required "token" AuthToken.decoder
        |> required "firstName" Decode.string
        |> required "lastName" Decode.string
        |> required "email" Decode.string
        |> optional "photo" UserPhoto.decoder missingPhoto
        |> optional "birthdate" (Decode.nullable decodeDate) Nothing
        |> optional "sex" (Decode.nullable Decode.string) Nothing
        |> required "stravaToken" Decode.string
        |> required "role" Decode.string
        |> required "createdAt" decodeDate
        |> required "updatedAt" decodeDate


encode : User -> Value
encode user =
    Encode.object
        [ "id" => encodeUserId user.id
        , "token" => AuthToken.encode user.token
        , "firstName" => Encode.string user.firstName
        , "lastName" => Encode.string user.lastName
        , "email" => Encode.string user.email
        , "photo" => UserPhoto.encode user.photo
        , "birthdate" => EncodeExtra.maybe encodeDate user.birthdate
        , "sex" => EncodeExtra.maybe Encode.string user.sex
        , "stravaToken" => Encode.string user.stravaToken
        , "role" => Encode.string user.role
        , "createdAt" => encodeDate user.createdAt
        , "updatedAt" => encodeDate user.updatedAt
        ]



-- IDENTIFIERS --


type UserId
    = UserId String


userIdToString : UserId -> String
userIdToString (UserId userId) =
    userId


userIdParser : UrlParser.Parser (UserId -> a) a
userIdParser =
    UrlParser.custom "USERID" (Ok << UserId)


userIdDecoder : Decoder UserId
userIdDecoder =
    Decode.map UserId Decode.string


encodeUserId : UserId -> Value
encodeUserId (UserId userId) =
    Encode.string userId


userIdToHtml : UserId -> Html msg
userIdToHtml (UserId userId) =
    Html.text userId
