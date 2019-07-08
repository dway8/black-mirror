port module Public.Ports exposing (GenericOutsideData, InfoForElm(..), InfoForOutside(..), getInfoFromOutside, infoForElm, infoForOutside, sendInfoOutside)

import Json.Decode as D
import Json.Encode as E
import Public.MybData as MybData exposing (MybData)


type alias GenericOutsideData =
    { tag : String
    , data : E.Value
    }


type InfoForOutside
    = PlayCashRegister
    | PlayFanfare
    | PlayKnock


type InfoForElm
    = ReceivedMYBEvent MybData


port infoForOutside : GenericOutsideData -> Cmd msg


port infoForElm : (GenericOutsideData -> msg) -> Sub msg


sendInfoOutside : InfoForOutside -> Cmd msg
sendInfoOutside info =
    case info of
        PlayCashRegister ->
            infoForOutside { tag = "playCashRegister", data = E.null }

        PlayFanfare ->
            infoForOutside { tag = "playFanfare", data = E.null }

        PlayKnock ->
            infoForOutside { tag = "playKnock", data = E.null }


getInfoFromOutside : (InfoForElm -> msg) -> (String -> msg) -> Sub msg
getInfoFromOutside tagger onError =
    infoForElm
        (\outsideInfo ->
            case outsideInfo.tag of
                "receivedMYBEvent" ->
                    case D.decodeValue MybData.mybDataDecoder outsideInfo.data of
                        Ok mybData ->
                            tagger <| ReceivedMYBEvent mybData

                        Err _ ->
                            onError "Error when parsing SSE message"

                _ ->
                    onError "Unknown message type"
        )
