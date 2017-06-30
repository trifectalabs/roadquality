module Request.Map exposing (snap, makeRoute, saveSegment, getSegments)

import Http
import HttpBuilder exposing (withExpect, withQueryParams, withBody)
import Json.Decode as Decode
import Json.Encode as Encode
import Data.AuthToken as AuthToken exposing (AuthToken, withAuthorization)
import Data.Map as Map exposing (CycleRoute, decodeCycleRoute, Point, decodePoint, encodePoint, Segment, decodeSegment, CreateSegmentForm, encodeCreateSegmentForm)


snap : String -> Maybe AuthToken -> ( Float, Float ) -> Http.Request Point
snap apiUrl maybeToken ( lat, lng ) =
    let
        queryParams =
            [ ( "lat", toString lat )
            , ( "lng", toString lng )
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
        body =
            points
                |> List.map encodePoint
                |> Encode.list
                |> Http.jsonBody
    in
        (apiUrl ++ "/mapRoutes")
            |> HttpBuilder.post
            |> withExpect (Http.expectJson decodeCycleRoute)
            |> withBody body
            |> withAuthorization maybeToken
            |> HttpBuilder.toRequest


saveSegment : String -> Maybe AuthToken -> CreateSegmentForm -> Float -> Http.Request Segment
saveSegment apiUrl maybeToken createSegmentForm zoom =
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
        (apiUrl ++ "/segments?currentZoomLevel=" ++ zoomString)
            |> HttpBuilder.post
            |> withExpect (Http.expectJson decodeSegment)
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
