module Request.Map exposing (snap, makeRoute, saveSegment, saveRating, getSegments, getBoundedSegments)

import Http
import HttpBuilder exposing (withExpect, withQueryParams, withBody)
import Json.Decode as Decode
import Data.AuthToken as AuthToken exposing (AuthToken, withAuthorization)
import Data.Map as Map exposing (..)
import Util exposing ((=>))


snap : String -> Maybe AuthToken -> ( Float, Float ) -> Http.Request Point
snap apiUrl maybeToken ( lat, lng ) =
    let
        queryParams =
            [ "lat" => toString lat
            , "lng" => toString lng
            ]
    in
        (apiUrl ++ "/mapRoutes/snap")
            |> HttpBuilder.get
            |> withExpect (Http.expectJson decodePoint)
            |> withQueryParams queryParams
            |> withAuthorization maybeToken
            |> HttpBuilder.toRequest


makeRoute : String -> Maybe AuthToken -> List Point -> Http.Request CycleRoute
makeRoute apiUrl maybeToken points =
    let
        pointString =
            points
                |> List.map
                    (\p -> String.join "," [ toString p.lng, toString p.lat ])
                |> String.join ";"
    in
        (apiUrl ++ "/mapRoutes/" ++ pointString)
            |> HttpBuilder.get
            |> withExpect (Http.expectJson decodeCycleRoute)
            |> withAuthorization maybeToken
            |> HttpBuilder.toRequest


saveSegment : String -> Maybe AuthToken -> CreateSegmentForm -> Float -> Bool -> Http.Request Segment
saveSegment apiUrl maybeToken createSegmentForm zoom hidden =
    let
        body =
            createSegmentForm
                |> encodeCreateSegmentForm
                |> Http.jsonBody

        zoomString =
            zoom
                |> round
                |> toString
    in
        (apiUrl ++ "/segments")
            |> HttpBuilder.post
            |> withExpect (Http.expectJson decodeSegment)
            |> withQueryParams
                [ "hidden" => (String.toLower <| toString hidden)
                , "currentZoomLevel" => zoomString
                ]
            |> withBody body
            |> withAuthorization maybeToken
            |> HttpBuilder.toRequest


saveRating : String -> Maybe AuthToken -> CreateSegmentForm -> String -> Float -> Http.Request Segment
saveRating apiUrl maybeToken createSegmentForm segmentId zoom =
    let
        body =
            createSegmentForm
                |> encodeCreateSegmentForm
                |> Http.jsonBody

        zoomString =
            zoom
                |> round
                |> toString
    in
        (apiUrl ++ "/segmentRatings")
            |> HttpBuilder.post
            |> withExpect (Http.expectJson decodeSegment)
            |> withQueryParams
                [ "id" => segmentId
                , "currentZoomLevel" => zoomString
                ]
            |> withBody body
            |> withAuthorization maybeToken
            |> HttpBuilder.toRequest


getSegments : String -> Maybe AuthToken -> Http.Request (List Segment)
getSegments apiUrl maybeToken =
    let
        expect =
            Decode.list decodeSegment
                |> Http.expectJson
    in
        (apiUrl ++ "/segments")
            |> HttpBuilder.get
            |> withExpect expect
            |> withAuthorization maybeToken
            |> HttpBuilder.toRequest


getBoundedSegments : String -> Maybe AuthToken -> Point -> Point -> Http.Request (List Segment)
getBoundedSegments apiUrl maybeToken southWest northEast =
    let
        expect =
            Decode.list decodeSegment
                |> Http.expectJson

        queryParams =
            [ "xmin" => toString southWest.lng
            , "ymin" => toString southWest.lat
            , "xmax" => toString northEast.lng
            , "ymax" => toString northEast.lat
            ]
    in
        (apiUrl ++ "/segments/boundingbox")
            |> HttpBuilder.get
            |> withExpect expect
            |> withQueryParams queryParams
            |> withAuthorization maybeToken
            |> HttpBuilder.toRequest
