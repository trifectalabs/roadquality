module Page.Home.RatingsMenu exposing (view, subscriptions, update, anchorCountUpdate, Model, Msg(..), ExternalMsg(..), initModel)

import Data.Map exposing (SurfaceType(..), PathType(..))
import Html exposing (..)
import Html.Attributes as Attr exposing (type_, value)
import Html.Events exposing (onClick, onInput)
import Stylesheets exposing (globalNamespace, mapNamespace, CssIds(..), CssClasses(..))
import Html.CssHelpers exposing (Namespace)
import Animation exposing (px, percent)
import Util exposing ((=>))
import Ports
import Views.Assets as Assets


-- MODEL --


type MenuStep
    = NeedAnchorsPlaced
    | AddRatings
      -- | AddTags
    | AddName


type alias Model =
    { step : MenuStep
    , style : Animation.State
    , progress : Animation.State
    , autoAdvance : Bool
    , name : String
    , description : String
    , surfaceRating : Maybe Int
    , trafficRating : Maybe Int

    -- , surfaceType : Maybe SurfaceType
    -- , pathType : Maybe PathType
    }


type alias Styles =
    { open : List Animation.Property
    , closed : List Animation.Property
    , progressWidth : Float -> List Animation.Property
    }


initModel : Model
initModel =
    { step = NeedAnchorsPlaced
    , style = Animation.style styles.closed
    , progress = Animation.style <| styles.progressWidth 33.3
    , autoAdvance = True
    , name = ""
    , description = ""
    , surfaceRating = Nothing
    , trafficRating = Nothing

    -- , surfaceType = Nothing
    -- , pathType = Nothing
    }


styles : Styles
styles =
    { open =
        [ Animation.left (px 0.0) ]
    , closed =
        [ Animation.left (px -400.0) ]
    , progressWidth =
        (\p -> [ Animation.width (percent p) ])
    }



-- VIEW --


{ id, class, classList } =
    mapNamespace


g : Namespace String class id msg
g =
    globalNamespace


view : Model -> Html Msg
view model =
    -- TODO: Add info about ratings
    div
        (Animation.render model.style ++ [ id SaveRatingControl ])
        (toolBar model ++ [ ratingsControl model, ratingsInfo model.step ])


toolBar : Model -> List (Html Msg)
toolBar model =
    let
        close =
            img
                [ class [ CloseMenu ]
                , Assets.src Assets.close
                , onClick ClearAnchors
                ]
                []

        back step =
            img
                [ class [ BackMenu ]
                , Assets.src Assets.backArrow
                , onClick <| SetMenuStep True step
                ]
                []

        next click =
            img
                [ class [ NextMenu ]
                , Assets.src Assets.nextArrow
                , click
                ]
                []

        done =
            img
                [ class [ DoneMenu ]
                , Assets.src Assets.done
                , onClick SaveSegment
                ]
                []

        nothing =
            span [] []

        ( leftAction, rightAction ) =
            case model.step of
                NeedAnchorsPlaced ->
                    ( close, nothing )

                AddRatings ->
                    if
                        model.surfaceRating
                            /= Nothing
                            && model.trafficRating
                            /= Nothing
                    then
                        ( close, next <| onClick <| SetMenuStep False AddName )
                    else
                        ( close, next <| class [ Disabled ] )

                -- AddTags ->
                --     ( back AddRatings, next AddName )
                AddName ->
                    ( back AddRatings, done )
    in
        [ leftAction
        , div
            [ class [ ProgressBar ] ]
            [ div (Animation.render model.progress) [] ]
        , rightAction
        ]


ratingsControl : Model -> Html Msg
ratingsControl model =
    case model.step of
        NeedAnchorsPlaced ->
            needAnchorsPlaced

        AddRatings ->
            addRatings model

        -- AddTags ->
        --     addTags model
        AddName ->
            addName model


needAnchorsPlaced : Html Msg
needAnchorsPlaced =
    div [ class [ NeedAnchorsControl ] ]
        [ -- span [ Attr.class "fa fa-times", onClick ClearAnchors ] []
          h3 [] [ text "Start by placing points on the map to select a road" ]
        ]


addRatings : Model -> Html Msg
addRatings model =
    div [ class [ AddRatingsControl ] ]
        [ --     span [ Attr.class "fa fa-times", onClick ClearAnchors ] []
          -- , div
          --     [ class [ ProgressBar ] ]
          --     [ div (Animation.render model.progress) [] ]
          -- , span
          --     [ g.class [ PrimaryButton ]
          --     , Attr.class "fa fa-arrow-right"
          --     , case ( model.surfaceRating, model.trafficRating ) of
          --         ( Just _, Just _ ) ->
          --             onClick <| SetMenuStep AddTags
          --         _ ->
          --             class [ Disabled ]
          --     ]
          --     []
          div
            [ class [ SurfaceRatingMenu ] ]
            [ h2 [] [ text "Surface Rating" ]
            , div
                [ onClick <| ChangeSurfaceRating <| Just 1
                , classList
                    [ ( SurfaceRatingOne, True )
                    , ( Active, model.surfaceRating == Just 1 )
                    ]
                ]
                []
            , div
                [ onClick <| ChangeSurfaceRating <| Just 2
                , classList
                    [ ( SurfaceRatingTwo, True )
                    , ( Active, model.surfaceRating == Just 2 )
                    ]
                ]
                []
            , div
                [ onClick <| ChangeSurfaceRating <| Just 3
                , classList
                    [ ( SurfaceRatingThree, True )
                    , ( Active, model.surfaceRating == Just 3 )
                    ]
                ]
                []
            , div
                [ onClick <| ChangeSurfaceRating <| Just 4
                , classList
                    [ ( SurfaceRatingFour, True )
                    , ( Active, model.surfaceRating == Just 4 )
                    ]
                ]
                []
            , div
                [ onClick <| ChangeSurfaceRating <| Just 5
                , classList
                    [ ( SurfaceRatingFive, True )
                    , ( Active, model.surfaceRating == Just 5 )
                    ]
                ]
                []
            ]
        , div
            [ class [ TrafficRatingMenu ] ]
            [ h2 [] [ text "Traffic Rating" ]
            , div
                [ onClick <| ChangeTrafficRating <| Just 1
                , classList
                    [ ( TrafficRatingOne, True )
                    , ( Active, model.trafficRating == Just 1 )
                    ]
                ]
                []
            , div
                [ onClick <| ChangeTrafficRating <| Just 2
                , classList
                    [ ( TrafficRatingTwo, True )
                    , ( Active, model.trafficRating == Just 2 )
                    ]
                ]
                []
            , div
                [ onClick <| ChangeTrafficRating <| Just 3
                , classList
                    [ ( TrafficRatingThree, True )
                    , ( Active, model.trafficRating == Just 3 )
                    ]
                ]
                []
            , div
                [ onClick <| ChangeTrafficRating <| Just 4
                , classList
                    [ ( TrafficRatingFour, True )
                    , ( Active, model.trafficRating == Just 4 )
                    ]
                ]
                []
            , div
                [ onClick <| ChangeTrafficRating <| Just 5
                , classList
                    [ ( TrafficRatingFive, True )
                    , ( Active, model.trafficRating == Just 5 )
                    ]
                ]
                []
            ]
        ]



-- addTags : Model -> Html Msg
-- addTags model =
--     div [ class [ AddTagsControl ] ]
--         [ div
--             [ class [ SurfaceTypeMenu ] ]
--             [ h2 [] [ text "Surface Type" ]
--             , div
--                 [ onClick <| ChangeSurfaceType <| Just Asphalt
--                 , classList [ ( Active, model.surface == Just Asphalt ) ]
--                 ]
--                 [ text "Asphalt" ]
--             , div
--                 [ onClick <| ChangeSurfaceType <| Just Gravel
--                 , classList [ ( Active, model.surface == Just Gravel ) ]
--                 ]
--                 [ text "Gravel" ]
--             , div
--                 [ onClick <| ChangeSurfaceType <| Just Dirt
--                 , classList [ ( Active, model.surface == Just Dirt ) ]
--                 ]
--                 [ text "Dirt" ]
--             ]
--         , div
--             [ class [ PathTypeMenu ] ]
--             [ h2 [] [ text "Path Type" ]
--             , div
--                 [ onClick <| ChangePathType <| Just Shared
--                 , classList [ ( Active, model.pathType == Just Shared ) ]
--                 ]
--                 [ text "Shared Road" ]
--             , div
--                 [ onClick <| ChangePathType <| Just DedicatedLane
--                 , classList [ ( Active, model.pathType == Just DedicatedLane ) ]
--                 ]
--                 [ text "Bike Lane" ]
--             , div
--                 [ onClick <| ChangePathType <| Just BikePath
--                 , classList [ ( Active, model.pathType == Just BikePath ) ]
--                 ]
--                 [ text "Bike Path" ]
--             ]
--         ]


addName : Model -> Html Msg
addName model =
    div [ class [ AddNameControl ] ]
        [ --     span [ Attr.class "fa fa-times", onClick ClearAnchors ] []
          -- , div
          --     [ class [ ProgressBar ] ]
          --     [ div (Animation.render model.progress) [] ]
          -- , div
          --     [ Attr.class "fa fa-arrow-left"
          --     , onClick <| SetMenuStep AddTags
          --     ]
          --     []
          -- , span
          --     [ g.class [ PrimaryButton ]
          --     , Attr.class "fa fa-check"
          --     , onClick SaveSegment
          --     ]
          --     []
          div [] [ h2 [] [ text "Make Segment (Optional)" ] ]
        , div
            [ class [ SegmentNameInput ] ]
            [ span [] [ text "Name" ]
            , input
                [ type_ "text", onInput ChangeName, value model.name ]
                []
            ]
        , div
            [ class [ SegmentDescriptionInput ] ]
            [ span [] [ text "Description" ]
            , textarea
                [ onInput ChangeDescription
                , value model.description
                ]
                []
            ]
        ]


ratingsInfo : MenuStep -> Html Msg
ratingsInfo step =
    case step of
        NeedAnchorsPlaced ->
            span [] []

        AddRatings ->
            div [ class [ AddRatingsInfo ] ]
                [ h2 [] [ text "Surface Rating Details" ]
                , div
                    []
                    [ div [ class [ SurfaceRatingOne ] ] []
                    , span [] [ text "For all intents and purposes this road doesn't exist" ]
                    ]
                , div
                    []
                    [ div [ class [ SurfaceRatingTwo ] ] []
                    , span [] [ text "This road is in desperate need of some repairs" ]
                    ]
                , div
                    []
                    [ div [ class [ SurfaceRatingThree ] ] []
                    , span [] [ text "This road can be a bit bumpy but its certainly rideable" ]
                    ]
                , div
                    []
                    [ div [ class [ SurfaceRatingFour ] ] []
                    , span [] [ text "Its not perfect but this is a good road for riding" ]
                    ]
                , div
                    []
                    [ div [ class [ SurfaceRatingFive ] ] []
                    , span [] [ text "If all roads were like this road you'd never leave the saddle" ]
                    ]
                , h2 [] [ text "Traffic Rating Details" ]
                , div
                    []
                    [ div [ class [ TrafficRatingOne ] ] []
                    , span [] [ text "Heavy motor traffic, avoid riding this road at all costs" ]
                    ]
                , div
                    []
                    [ div [ class [ TrafficRatingTwo ] ] []
                    , span [] [ text "Lots of car traffic, you would only ride as a last resort" ]
                    ]
                , div
                    []
                    [ div [ class [ TrafficRatingThree ] ] []
                    , span [] [ text "Some car traffic but this road is definitely rideable" ]
                    ]
                , div
                    []
                    [ div [ class [ TrafficRatingFour ] ] []
                    , span [] [ text "Fairly light car traffic, this is a good road for riding" ]
                    ]
                , div
                    []
                    [ div [ class [ TrafficRatingFive ] ] []
                    , span [] [ text "Virtually no car traffic, you could ride here for days" ]
                    ]
                ]

        AddName ->
            div [ class [ AddNameInfo ] ]
                [ h2 [] [ text "Why make a segment?" ]
                , h3 [] [ text "If you add a name and/or description this section of road will be saved to your segments for you to easily access again later for rating." ]
                ]



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Animation.subscription AnimateMenu [ model.style ]
        , Animation.subscription AnimateProgress [ model.progress ]
        ]



-- UPDATE --


type Msg
    = SetMenuStep Bool MenuStep
    | ShowMenu
    | AnimateMenu Animation.Msg
    | AnimateProgress Animation.Msg
    | ChangeName String
    | ChangeDescription String
    | ChangeSurfaceRating (Maybe Int)
    | ChangeTrafficRating (Maybe Int)
      -- | ChangePathType (Maybe PathType)
      -- | ChangeSurfaceType (Maybe SurfaceType)
    | ClearAnchors
    | SaveSegment


type ExternalMsg
    = Closed
    | Completed Int Int SurfaceType PathType
    | Error String
    | NoOp


anchorCountUpdate : Int -> Model -> Model
anchorCountUpdate anchorCount model =
    if anchorCount < 2 then
        { model
            | step = NeedAnchorsPlaced
            , progress =
                Animation.interrupt
                    [ Animation.to <|
                        styles.progressWidth 33.3
                    ]
                    model.progress
        }
    else if anchorCount == 2 && model.step == NeedAnchorsPlaced then
        { model
            | step = AddRatings
            , progress =
                Animation.interrupt
                    [ Animation.to <|
                        styles.progressWidth 66.6
                    ]
                    model.progress
        }
    else
        model


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SetMenuStep disableAutoAdvance step ->
            let
                progress =
                    case step of
                        NeedAnchorsPlaced ->
                            Animation.interrupt
                                [ Animation.to <|
                                    styles.progressWidth 33.3
                                ]
                                model.progress

                        AddRatings ->
                            Animation.interrupt
                                [ Animation.to <|
                                    styles.progressWidth 66.6
                                ]
                                model.progress

                        -- AddTags ->
                        --     Animation.interrupt
                        --         [ Animation.to <|
                        --             styles.progressWidth 75.0
                        --         ]
                        --         model.progress
                        AddName ->
                            Animation.interrupt
                                [ Animation.to <|
                                    styles.progressWidth 100.0
                                ]
                                model.progress
            in
                { model
                    | step = step
                    , progress = progress
                    , autoAdvance = not disableAutoAdvance
                }
                    => Cmd.none
                    => NoOp

        ShowMenu ->
            { initModel
                | style =
                    Animation.interrupt
                        [ Animation.to styles.open ]
                        model.style
            }
                => Ports.routeCreate ()
                => NoOp

        AnimateMenu animMsg ->
            { model | style = Animation.update animMsg model.style }
                => Cmd.none
                => NoOp

        AnimateProgress animMsg ->
            { model | progress = Animation.update animMsg model.progress }
                => Cmd.none
                => NoOp

        ChangeName name ->
            { model | name = name } => Cmd.none => NoOp

        ChangeDescription description ->
            { model | description = description } => Cmd.none => NoOp

        ChangeSurfaceRating rating ->
            let
                ( progress, step ) =
                    case ( model.autoAdvance, rating, model.trafficRating ) of
                        ( True, Just _, Just _ ) ->
                            ( Animation.interrupt
                                [ Animation.to <|
                                    styles.progressWidth 100.0
                                ]
                                model.progress
                            , AddName
                            )

                        _ ->
                            ( model.progress, model.step )
            in
                { model
                    | surfaceRating = rating
                    , progress = progress
                    , step = step
                }
                    => Cmd.none
                    => NoOp

        ChangeTrafficRating rating ->
            let
                ( progress, step ) =
                    case ( model.autoAdvance, rating, model.surfaceRating ) of
                        ( True, Just _, Just _ ) ->
                            ( Animation.interrupt
                                [ Animation.to <|
                                    styles.progressWidth 100.0
                                ]
                                model.progress
                            , AddName
                            )

                        _ ->
                            ( model.progress, model.step )
            in
                { model
                    | trafficRating = rating
                    , progress = progress
                    , step = step
                }
                    => Cmd.none
                    => NoOp

        -- ChangePathType pathType ->
        --     let
        --         progress =
        --             case ( pathType, model.surface ) of
        --                 ( Just _, Just _ ) ->
        --                     Animation.interrupt
        --                         [ Animation.to <|
        --                             styles.progressWidth 100.0
        --                         ]
        --                         model.progress
        --                 _ ->
        --                     model.progress
        --     in
        --         { model
        --             | pathType = pathType
        --             , progress = progress
        --         }
        --             => Cmd.none
        --             => NoOp
        -- ChangeSurfaceType surfaceType ->
        --     let
        --         progress =
        --             case ( surfaceType, model.pathType ) of
        --                 ( Just _, Just _ ) ->
        --                     Animation.interrupt
        --                         [ Animation.to <|
        --                             styles.progressWidth 100.0
        --                         ]
        --                         model.progress
        --                 _ ->
        --                     model.progress
        --     in
        --         { model
        --             | surface = surfaceType
        --             , progress = progress
        --         }
        --             => Cmd.none
        --             => NoOp
        ClearAnchors ->
            { model
                | style =
                    Animation.interrupt
                        [ Animation.to styles.closed ]
                        model.style
            }
                => Ports.clearRoute ()
                => Closed

        SaveSegment ->
            case
                ( model.surfaceRating
                , model.trafficRating
                  -- , model.surfaceType
                  -- , model.pathType
                )
            of
                ( Just sRating, Just tRating ) ->
                    model
                        => Ports.clearRoute ()
                        => Completed sRating tRating UnknownSurface UnknownPath

                _ ->
                    model
                        => Cmd.none
                        => Error "There was a client error saving your segment. Sorry!"
