module Util exposing ((=>), pair, viewIf, appendErrors, generateNewKey)

import Html exposing (Html)
import Random exposing (Seed)
import Random.String exposing (string)
import Random.Char exposing (english)


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


{-| infixl 0 means the (=>) operator has the same precedence as (<|) and (|>),
meaning you can use it at the end of a pipeline and have the precedence work out.
-}
infixl 0 =>


{-| Useful when building up a Cmd via a pipeline, and then pairing it with
a model at the end.
session.user
|> User.Request.foo
|> Task.attempt Foo
|> pair { model | something = blah }
-}
pair : a -> b -> ( a, b )
pair first second =
    first => second


viewIf : Bool -> Html msg -> Html msg
viewIf condition content =
    if condition then
        content
    else
        Html.text ""


{-| TODO: log errors
-}
appendErrors : { model | errors : List error } -> List error -> { model | errors : List error }
appendErrors model errors =
    { model | errors = model.errors ++ errors }


generateNewKey : Seed -> ( String, Seed )
generateNewKey seed =
    Random.step (string 16 english) seed
