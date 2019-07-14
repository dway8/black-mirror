port module Ports exposing (GenericOutsideData, InfoForElm(..), InfoForOutside(..), getInfoFromOutside, infoForElm, infoForOutside, sendInfoOutside)

import Json.Decode as D
import Json.Decode.Pipeline as P
import Json.Encode as E
import Model exposing (Message, messagesDecoder)
import Public.MybData as MybData exposing (MybData)


type alias GenericOutsideData =
    { tag : String
    , data : E.Value
    }


type InfoForOutside
    = PlaySound String


type InfoForElm
    = ReceivedMYBEvent MybData String
    | ReceivedMessages (List Message)


port infoForOutside : GenericOutsideData -> Cmd msg


port infoForElm : (GenericOutsideData -> msg) -> Sub msg


sendInfoOutside : InfoForOutside -> Cmd msg
sendInfoOutside info =
    case info of
        PlaySound url ->
            infoForOutside { tag = "playSound", data = E.string url }


getInfoFromOutside : (InfoForElm -> msg) -> (String -> msg) -> Sub msg
getInfoFromOutside tagger onError =
    infoForElm
        (\outsideInfo ->
            case outsideInfo.tag of
                "receivedMYBEvent" ->
                    case D.decodeValue mybEventDecoder outsideInfo.data of
                        Ok ( mybData, event ) ->
                            tagger <| ReceivedMYBEvent mybData event

                        Err _ ->
                            onError "Error when parsing SSE message"

                "receivedMessages" ->
                    case D.decodeValue messagesDecoder outsideInfo.data of
                        Ok messages ->
                            tagger <| ReceivedMessages messages

                        Err _ ->
                            onError "Error when parsing SSE message"

                _ ->
                    onError "Unknown message type"
        )


mybEventDecoder : D.Decoder ( MybData, String )
mybEventDecoder =
    D.succeed Tuple.pair
        |> P.required "data" MybData.mybDataDecoder
        |> P.required "event" D.string
