port module Ports exposing (GenericOutsideData, InfoForElm(..), InfoForOutside(..), getInfoFromOutside, infoForElm, infoForOutside, sendInfoOutside)

import Json.Decode as D
import Json.Decode.Pipeline as P
import Json.Encode as E
import Model exposing (Event, Message, Sound)
import Public.MybData as MybData exposing (MybData)


type alias GenericOutsideData =
    { tag : String
    , data : E.Value
    }


type InfoForOutside
    = PlaySound String


type InfoForElm
    = ReceivedMYBEvent MybData Event
    | ReceivedMessages (List Message) Bool
    | ReceivedSounds (List Sound)
    | ReceivedMYBRefresh MybData


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
                    case D.decodeValue messagesEventDecoder outsideInfo.data of
                        Ok ( messages, isNew ) ->
                            tagger <| ReceivedMessages messages isNew

                        Err _ ->
                            onError "Error when parsing SSE message"

                "receivedSounds" ->
                    case D.decodeValue Model.soundsDecoder outsideInfo.data of
                        Ok sounds ->
                            tagger <| ReceivedSounds sounds

                        Err _ ->
                            onError "Error when parsing SSE message"

                "receivedMYBRefresh" ->
                    case D.decodeValue MybData.mybDataDecoder outsideInfo.data of
                        Ok mybData ->
                            tagger <| ReceivedMYBRefresh mybData

                        Err _ ->
                            onError "Error when parsing SSE message"

                _ ->
                    onError "Unknown message type"
        )


mybEventDecoder : D.Decoder ( MybData, Event )
mybEventDecoder =
    D.succeed Tuple.pair
        |> P.required "data" MybData.mybDataDecoder
        |> P.required "event" Model.eventDecoder


messagesEventDecoder : D.Decoder ( List Message, Bool )
messagesEventDecoder =
    D.succeed Tuple.pair
        |> P.required "messages" Model.messagesDecoder
        |> P.required "isNew" D.bool
