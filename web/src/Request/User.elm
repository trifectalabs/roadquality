module Request.User exposing (login, register, edit, storeSession, emailListSignUp)

import Http
import Ports
import Data.User as User exposing (User)
import Data.AuthToken as AuthToken exposing (AuthToken, withAuthorization)
import Json.Encode as Encode
import Json.Encode.Extra as EncodeExtra
import Json.Decode as Decode
import Util exposing ((=>))
import HttpBuilder exposing (withExpect, withQueryParams, RequestBuilder)


storeSession : User -> Cmd msg
storeSession user =
    User.encode user
        |> Encode.encode 0
        |> Just
        |> Ports.storeSession


login : String -> { r | email : String, password : String } -> Http.Request User
login apiUrl { email, password } =
    let
        user =
            Encode.object
                [ "email" => Encode.string email
                , "password" => Encode.string password
                ]

        body =
            Encode.object [ "user" => user ]
                |> Http.jsonBody
    in
        Decode.field "user" User.decoder
            |> Http.post (apiUrl ++ "/users/login") body


register : String -> { r | username : String, email : String, password : String } -> Http.Request User
register apiUrl { username, email, password } =
    let
        user =
            Encode.object
                [ "username" => Encode.string username
                , "email" => Encode.string email
                , "password" => Encode.string password
                ]

        body =
            Encode.object [ "user" => user ]
                |> Http.jsonBody
    in
        Decode.field "user" User.decoder
            |> Http.post (apiUrl ++ "/users") body


edit :
    String
    ->
        { r
            | username : String
            , email : String
            , bio : String
            , password : Maybe String
            , image : Maybe String
        }
    -> Maybe AuthToken
    -> Http.Request User
edit apiUrl { username, email, bio, password, image } maybeToken =
    let
        updates =
            [ Just ("username" => Encode.string username)
            , Just ("email" => Encode.string email)
            , Just ("bio" => Encode.string bio)
            , Just ("image" => EncodeExtra.maybe Encode.string image)
            , Maybe.map (\pass -> "password" => Encode.string pass) password
            ]
                |> List.filterMap identity

        body =
            ("user" => Encode.object updates)
                |> List.singleton
                |> Encode.object
                |> Http.jsonBody

        expect =
            User.decoder
                |> Decode.field "user"
                |> Http.expectJson
    in
        (apiUrl ++ "/user")
            |> HttpBuilder.put
            |> HttpBuilder.withExpect expect
            |> HttpBuilder.withBody body
            |> withAuthorization maybeToken
            |> HttpBuilder.toRequest


emailListSignUp : String -> String -> Http.Request String
emailListSignUp url email =
    let
        body =
            Encode.object
                [ "email_address" => Encode.string email
                , "status" => Encode.string "subscribed"
                ]
                |> Http.jsonBody
    in
        (url ++ "/emailList")
            |> HttpBuilder.post
            |> HttpBuilder.withExpect Http.expectString
            |> HttpBuilder.withBody body
            |> HttpBuilder.toRequest
