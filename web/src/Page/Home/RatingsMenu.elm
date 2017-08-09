module Page.Home.RatingsMenu exposing (view, subscriptions, update, anchorCountUpdate, Model, Msg(..), ExternalMsg(..), initModel)

import Html exposing (..)
import Html.Attributes as Attr exposing (type_, value, for, title, name, checked, placeholder)
import Html.Events exposing (onClick, onInput, onMouseEnter, onMouseLeave)
import Svg exposing (svg, polygon, line, polyline)
import Svg.Attributes exposing (xmlSpace, width, height, viewBox, fill, stroke, strokeWidth, strokeLinecap, strokeLinejoin, points, x1, x2, y1, y2)
import Stylesheets exposing (globalNamespace, mapNamespace, CssIds(..), CssClasses(..))
import Html.CssHelpers exposing (Namespace)
import Animation exposing (px, percent)
import Util exposing ((=>))
import Ports


-- MODEL --


type MenuStep
    = NeedAnchorsPlaced
    | AddSurfaceRating
    | AddTrafficRating
    | AddName


type alias Model =
    { step : MenuStep
    , style : Animation.State
    , ratingHover : Maybe Int
    , surfaceRating : Maybe Int
    , trafficRating : Maybe Int
    , name : String
    , description : String
    }


type alias Styles =
    { open : List Animation.Property
    , closed : List Animation.Property
    }


initModel : Model
initModel =
    { step = NeedAnchorsPlaced
    , style = Animation.style styles.closed
    , ratingHover = Nothing
    , surfaceRating = Nothing
    , trafficRating = Nothing
    , name = ""
    , description = ""
    }


styles : Styles
styles =
    { open =
        [ Animation.left (px 0.0) ]
    , closed =
        [ Animation.left (px -405.0) ]
    }



-- VIEW --


{ id, class, classList } =
    mapNamespace


g : Namespace String class id msg
g =
    globalNamespace


view : Model -> Html Msg
view model =
    div
        (Animation.render model.style ++ [ id SaveRatingControl ])
        [ menuClose model.step
        , ratingsControl model
        , menuProgress model
        ]


menuClose : MenuStep -> Html Msg
menuClose step =
    let
        strokeColor =
            case step of
                AddName ->
                    whiteString

                _ ->
                    blackString
    in
        span
            [ class [ CloseMenu ]
            , g.class [ SymbolButton ]
            , onClick ClearAnchors
            ]
            [ svg
                [ xmlSpace "http://www.w3.org/2000/svg"
                , width "24"
                , height "24"
                , viewBox "0 0 24 24"
                , fill "none"
                , stroke strokeColor
                , strokeWidth "2"
                , strokeLinecap "round"
                , strokeLinejoin "round"
                ]
                [ line [ x1 "18", y1 "6", x2 "6", y2 "18" ] []
                , line [ x1 "6", y1 "6", x2 "18", y2 "18" ] []
                ]
            ]


menuProgress : Model -> Html Msg
menuProgress model =
    let
        back step =
            span
                [ class [ BackMenu ]
                , g.class [ SecondaryButton, SymbolButton ]
                , onClick <| SetMenuStep step
                ]
                [ svg
                    [ xmlSpace "http://www.w3.org/2000/svg"
                    , width "24"
                    , height "24"
                    , viewBox "0 0 24 24"
                    , fill "none"
                    , stroke greyString
                    , strokeWidth "2"
                    , strokeLinecap "round"
                    , strokeLinejoin "round"
                    ]
                    [ line [ x1 "20", y1 "12", x2 "4", y2 "12" ] []
                    , polyline [ points "10 18 4 12 10 6" ] []
                    ]
                ]

        next click =
            span
                [ class [ NextMenu ]
                , g.class [ PrimaryButton, SymbolButton ]
                , click
                ]
                [ svg
                    [ xmlSpace "http://www.w3.org/2000/svg"
                    , width "24"
                    , height "24"
                    , viewBox "0 0 24 24"
                    , fill "none"
                    , stroke whiteString
                    , strokeWidth "2"
                    , strokeLinecap "round"
                    , strokeLinejoin "round"
                    ]
                    [ line [ x1 "4", y1 "12", x2 "20", y2 "12" ] []
                    , polyline [ points "14 6 20 12 14 18" ] []
                    ]
                ]

        nothing =
            span [] []

        ( leftAction, rightAction ) =
            case model.step of
                NeedAnchorsPlaced ->
                    ( nothing, nothing )

                AddSurfaceRating ->
                    case model.surfaceRating of
                        Nothing ->
                            ( nothing, next <| class [ Disabled ] )

                        Just _ ->
                            ( nothing
                            , next <| onClick <| SetMenuStep AddTrafficRating
                            )

                AddTrafficRating ->
                    case model.trafficRating of
                        Nothing ->
                            ( back AddSurfaceRating
                            , next <| class [ Disabled ]
                            )

                        Just _ ->
                            ( back AddSurfaceRating
                            , next <| onClick <| SetMenuStep AddName
                            )

                AddName ->
                    ( back AddTrafficRating, nothing )
    in
        div [ class [ ProgressBar ] ]
            [ leftAction
            , progressDots model.step
            , rightAction
            ]


progressDots : MenuStep -> Html Msg
progressDots step =
    div [ class [ ProgressDots ] ]
        [ span
            [ classList [ ( Active, step == NeedAnchorsPlaced ) ] ]
            [ text "⬤" ]
        , span
            [ classList [ ( Active, step == AddSurfaceRating ) ] ]
            [ text "⬤" ]
        , span
            [ classList [ ( Active, step == AddTrafficRating ) ] ]
            [ text "⬤" ]
        , span [ classList [ ( Active, step == AddName ) ] ] [ text "⬤" ]
        ]


ratingsControl : Model -> Html Msg
ratingsControl model =
    case model.step of
        NeedAnchorsPlaced ->
            needAnchorsPlaced

        AddSurfaceRating ->
            addSurfaceRating model

        AddTrafficRating ->
            addTrafficRating model

        AddName ->
            addName model


star : String -> String -> Html msg
star fillColor strokeColor =
    svg
        [ xmlSpace "http://www.w3.org/2000/svg"
        , width "32"
        , height "32"
        , viewBox "0 0 32 32"
        , fill fillColor
        , stroke strokeColor
        , strokeWidth "1"
        , strokeLinecap "round"
        , strokeLinejoin "round"
        ]
        [ polygon [ points "16,2 20.326,11.216 30,12.703 23.001,19.872 24.651,30 16,25.215 7.348,30 9,19.872 2,12.703 11.675,11.216" ] [] ]


surfaceRatingOneString : String
surfaceRatingOneString =
    "rgb(166, 3, 15)"


surfaceRatingTwoString : String
surfaceRatingTwoString =
    "rgb(198, 97, 22)"


surfaceRatingThreeString : String
surfaceRatingThreeString =
    "rgb(230, 180, 28)"


surfaceRatingFourString : String
surfaceRatingFourString =
    "rgb(100, 180, 28)"


surfaceRatingFiveString : String
surfaceRatingFiveString =
    "rgb(60, 145, 50)"


trafficRatingOneString : String
trafficRatingOneString =
    "rgb(252, 0, 0)"


trafficRatingTwoString : String
trafficRatingTwoString =
    "rgb(189, 0, 63)"


trafficRatingThreeString : String
trafficRatingThreeString =
    "rgb(126, 0, 126)"


trafficRatingFourString : String
trafficRatingFourString =
    "rgb(63, 0, 189)"


trafficRatingFiveString : String
trafficRatingFiveString =
    "rgb(0, 0, 252)"


whiteString : String
whiteString =
    "rgb(255, 255, 255)"


greyString : String
greyString =
    "rgb(170, 170, 170)"


blackString : String
blackString =
    "rgb(44, 44, 44)"


needAnchorsPlaced : Html Msg
needAnchorsPlaced =
    div [ class [ RatingsMenu ] ]
        [ div [] []
        , h2 []
            [ text "Start by selecting your route on the "
            , span [] [ text "map" ]
            , text "."
            ]
        ]


addSurfaceRating : Model -> Html Msg
addSurfaceRating model =
    let
        selectedRating =
            case ( model.surfaceRating, model.ratingHover ) of
                ( _, Just ratingHover ) ->
                    Just ratingHover

                ( Just surfaceRating, Nothing ) ->
                    Just surfaceRating

                ( Nothing, Nothing ) ->
                    Nothing

        ratingInfo =
            case selectedRating of
                Just 1 ->
                    "For all intents and purposes this road doesn't exist"

                Just 2 ->
                    "This road is in desperate need of some repairs"

                Just 3 ->
                    "This road can be a bit bumpy but its certainly rideable"

                Just 4 ->
                    "Its not perfect but this is a good road for riding"

                Just 5 ->
                    "If all roads were like this road you'd never leave the saddle"

                _ ->
                    ""

        starActive rating =
            case ( model.surfaceRating, model.ratingHover ) of
                ( _, Just ratingHover ) ->
                    if ratingHover >= 5 && rating <= 5 then
                        star surfaceRatingFiveString surfaceRatingFiveString
                    else if ratingHover >= 4 && rating <= 4 then
                        star surfaceRatingFourString surfaceRatingFourString
                    else if ratingHover >= 3 && rating <= 3 then
                        star surfaceRatingThreeString surfaceRatingThreeString
                    else if ratingHover >= 2 && rating <= 2 then
                        star surfaceRatingTwoString surfaceRatingTwoString
                    else if ratingHover >= 1 && rating <= 1 then
                        star surfaceRatingOneString surfaceRatingOneString
                    else
                        star whiteString greyString

                ( Just surfaceRating, Nothing ) ->
                    if surfaceRating >= 5 && rating <= 5 then
                        star surfaceRatingFiveString surfaceRatingFiveString
                    else if surfaceRating >= 4 && rating <= 4 then
                        star surfaceRatingFourString surfaceRatingFourString
                    else if surfaceRating >= 3 && rating <= 3 then
                        star surfaceRatingThreeString surfaceRatingThreeString
                    else if surfaceRating >= 2 && rating <= 2 then
                        star surfaceRatingTwoString surfaceRatingTwoString
                    else if surfaceRating >= 1 && rating <= 1 then
                        star surfaceRatingOneString surfaceRatingOneString
                    else
                        star whiteString greyString

                ( Nothing, Nothing ) ->
                    star whiteString greyString
    in
        div [ class [ RatingsMenu ] ]
            [ div [] []
            , h2 []
                [ text "How would rate the "
                , span [] [ text "surface quality" ]
                , text "?"
                ]
            , div
                [ class [ RatingsControl ] ]
                [ span
                    [ onClick <| ChangeSurfaceRating <| Just 1
                    , onMouseEnter <| ChangeRatingHover <| Just 1
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 1 ]
                , span
                    [ onClick <| ChangeSurfaceRating <| Just 2
                    , onMouseEnter <| ChangeRatingHover <| Just 2
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 2 ]
                , span
                    [ onClick <| ChangeSurfaceRating <| Just 3
                    , onMouseEnter <| ChangeRatingHover <| Just 3
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 3 ]
                , span
                    [ onClick <| ChangeSurfaceRating <| Just 4
                    , onMouseEnter <| ChangeRatingHover <| Just 4
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 4 ]
                , span
                    [ onClick <| ChangeSurfaceRating <| Just 5
                    , onMouseEnter <| ChangeRatingHover <| Just 5
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 5 ]
                ]
            , div [ class [ RatingInfo ] ] [ text ratingInfo ]
            ]


addTrafficRating : Model -> Html Msg
addTrafficRating model =
    let
        selectedRating =
            case ( model.trafficRating, model.ratingHover ) of
                ( _, Just ratingHover ) ->
                    Just ratingHover

                ( Just trafficRating, Nothing ) ->
                    Just trafficRating

                ( Nothing, Nothing ) ->
                    Nothing

        ratingInfo =
            case selectedRating of
                Just 1 ->
                    "Heavy motor traffic, avoid riding this road at all costs"

                Just 2 ->
                    "Lots of car traffic, you would only ride as a last resort"

                Just 3 ->
                    "Some car traffic but this road is definitely rideable"

                Just 4 ->
                    "Fairly light car traffic, this is a good road for riding"

                Just 5 ->
                    "Virtually no car traffic, you could ride here for days"

                _ ->
                    ""

        starActive rating =
            case ( model.trafficRating, model.ratingHover ) of
                ( _, Just ratingHover ) ->
                    if ratingHover >= 5 && rating <= 5 then
                        star trafficRatingFiveString trafficRatingFiveString
                    else if ratingHover >= 4 && rating <= 4 then
                        star trafficRatingFourString trafficRatingFourString
                    else if ratingHover >= 3 && rating <= 3 then
                        star trafficRatingThreeString trafficRatingThreeString
                    else if ratingHover >= 2 && rating <= 2 then
                        star trafficRatingTwoString trafficRatingTwoString
                    else if ratingHover >= 1 && rating <= 1 then
                        star trafficRatingOneString trafficRatingOneString
                    else
                        star whiteString greyString

                ( Just trafficRating, Nothing ) ->
                    if trafficRating >= 5 && rating <= 5 then
                        star trafficRatingFiveString trafficRatingFiveString
                    else if trafficRating >= 4 && rating <= 4 then
                        star trafficRatingFourString trafficRatingFourString
                    else if trafficRating >= 3 && rating <= 3 then
                        star trafficRatingThreeString trafficRatingThreeString
                    else if trafficRating >= 2 && rating <= 2 then
                        star trafficRatingTwoString trafficRatingTwoString
                    else if trafficRating >= 1 && rating <= 1 then
                        star trafficRatingOneString trafficRatingOneString
                    else
                        star whiteString greyString

                ( Nothing, Nothing ) ->
                    star whiteString greyString
    in
        div [ class [ RatingsMenu ] ]
            [ div [] []
            , h2 []
                [ text "How would rate the "
                , span [] [ text "traffic safety" ]
                , text "?"
                ]
            , div
                [ class [ RatingsControl ] ]
                [ span
                    [ onClick <| ChangeTrafficRating <| Just 1
                    , onMouseEnter <| ChangeRatingHover <| Just 1
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 1 ]
                , span
                    [ onClick <| ChangeTrafficRating <| Just 2
                    , onMouseEnter <| ChangeRatingHover <| Just 2
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 2 ]
                , span
                    [ onClick <| ChangeTrafficRating <| Just 3
                    , onMouseEnter <| ChangeRatingHover <| Just 3
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 3 ]
                , span
                    [ onClick <| ChangeTrafficRating <| Just 4
                    , onMouseEnter <| ChangeRatingHover <| Just 4
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 4 ]
                , span
                    [ onClick <| ChangeTrafficRating <| Just 5
                    , onMouseEnter <| ChangeRatingHover <| Just 5
                    , onMouseLeave <| ChangeRatingHover Nothing
                    ]
                    [ starActive 5 ]
                ]
            , div [ class [ RatingInfo ] ] [ text ratingInfo ]
            ]


addName : Model -> Html Msg
addName model =
    let
        activeStar modelRating rating =
            case modelRating of
                Nothing ->
                    star "transparent" whiteString

                Just number ->
                    if number >= rating then
                        star whiteString whiteString
                    else
                        star "transparent" whiteString
    in
        div []
            [ div [ class [ RatingsSummary ] ]
                [ div [] [ text "Surface Quality" ]
                , div []
                    [ span [] [ activeStar model.surfaceRating 1 ]
                    , span [] [ activeStar model.surfaceRating 2 ]
                    , span [] [ activeStar model.surfaceRating 3 ]
                    , span [] [ activeStar model.surfaceRating 4 ]
                    , span [] [ activeStar model.surfaceRating 5 ]
                    ]
                , div [] [ text "Traffic Safety" ]
                , div []
                    [ span [] [ activeStar model.trafficRating 1 ]
                    , span [] [ activeStar model.trafficRating 2 ]
                    , span [] [ activeStar model.trafficRating 3 ]
                    , span [] [ activeStar model.trafficRating 4 ]
                    , span [] [ activeStar model.trafficRating 5 ]
                    ]
                , span
                    [ g.class [ SecondaryButton ]
                    , class [ SaveButton ]
                    , onClick <| SaveSegment True
                    ]
                    [ text "Quick Save" ]
                ]
            , input
                [ class [ SegmentNameInput ]
                , type_ "text"
                , onInput ChangeName
                , value model.name
                , placeholder "Name"
                ]
                []
            , textarea
                [ class [ SegmentDescriptionInput ]
                , onInput ChangeDescription
                , value model.description
                , placeholder "Description"
                ]
                []
            , div
                [ g.class [ PrimaryButton ]
                , class [ SaveButton ]
                , onClick <| SaveSegment False
                ]
                [ text "Save as Segment" ]
            , div
                [ class [ SegmentInfo ] ]
                [ h3 [] [ text "Why save as a segment?" ]
                , h4 [] [ text "If you save a rating as a segment is allows you and others to easily access it later to make more ratings." ]
                ]
            ]



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Animation.subscription AnimateMenu [ model.style ]



-- UPDATE --


type Msg
    = SetMenuStep MenuStep
    | ShowMenu
    | AnimateMenu Animation.Msg
    | ChangeRatingHover (Maybe Int)
    | ChangeSurfaceRating (Maybe Int)
    | ChangeTrafficRating (Maybe Int)
    | ChangeName String
    | ChangeDescription String
    | ClearAnchors
    | SaveSegment Bool


type ExternalMsg
    = OpenMenu
    | CloseMenu
    | Completed Int Int String String Bool
    | Error String
    | NoOp


anchorCountUpdate : Int -> Model -> Model
anchorCountUpdate anchorCount model =
    if anchorCount < 2 then
        { model | step = NeedAnchorsPlaced }
    else if anchorCount == 2 && model.step == NeedAnchorsPlaced then
        { model | step = AddSurfaceRating }
    else
        model


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SetMenuStep step ->
            { model | step = step } => Cmd.none => NoOp

        ShowMenu ->
            { initModel
                | style =
                    Animation.interrupt
                        [ Animation.to styles.open ]
                        model.style
            }
                => Ports.isRouting True
                => OpenMenu

        AnimateMenu animMsg ->
            { model | style = Animation.update animMsg model.style }
                => Cmd.none
                => NoOp

        ChangeRatingHover rating ->
            { model | ratingHover = rating } => Cmd.none => NoOp

        ChangeSurfaceRating rating ->
            { model | surfaceRating = rating } => Cmd.none => NoOp

        ChangeTrafficRating rating ->
            { model | trafficRating = rating } => Cmd.none => NoOp

        ChangeName name ->
            { model | name = name } => Cmd.none => NoOp

        ChangeDescription description ->
            { model | description = description } => Cmd.none => NoOp

        ClearAnchors ->
            { model
                | style =
                    Animation.interrupt
                        [ Animation.to styles.closed ]
                        model.style
            }
                => Ports.isRouting False
                => CloseMenu

        SaveSegment quickSave ->
            if quickSave == False && model.name == "" then
                model => Cmd.none => Error "Add a name to save your segment."
            else
                let
                    ( name, description ) =
                        if quickSave == True then
                            ( "", "" )
                        else
                            ( model.name, model.description )
                in
                    case
                        ( model.surfaceRating, model.trafficRating )
                    of
                        ( Just sRating, Just tRating ) ->
                            { model
                                | style =
                                    Animation.interrupt
                                        [ Animation.to styles.closed ]
                                        model.style
                            }
                                => Ports.isRouting False
                                => Completed sRating tRating name description quickSave

                        _ ->
                            model
                                => Cmd.none
                                => Error "There was a client error saving your segment. Sorry!"
