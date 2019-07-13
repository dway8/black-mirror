port module Public.Ports exposing (GenericOutsideData, InfoForElm(..), InfoForOutside(..), getInfoFromOutside, infoForElm, infoForOutside, sendInfoOutside)

import Json.Decode as D
import Json.Decode.Pipeline as P
import Json.Encode as E
import Public.MybData as MybData exposing (MybData)


type alias GenericOutsideData =
    { tag : String
    , data : E.Value
    }


type InfoForOutside
    = PlaySound String


type InfoForElm
    = ReceivedMYBEvent MybData String


port infoForOutside : GenericOutsideData -> Cmd msg


port infoForElm : (GenericOutsideData -> msg) -> Sub msg


sendInfoOutside : InfoForOutside -> Cmd msg
sendInfoOutside info =
    case info of
        PlaySound event ->
            case event of
                "new_order" ->
                    infoForOutside { tag = "playCashRegister", data = E.null }

                "new_user" ->
                    infoForOutside { tag = "playKnock", data = E.null }

                _ ->
                    Cmd.none



-- PlayFanfare ->
--     infoForOutside { tag = "playFanfare", data = E.null }


getInfoFromOutside : (InfoForElm -> msg) -> (String -> msg) -> Sub msg
getInfoFromOutside tagger onError =
    infoForElm
        (\outsideInfo ->
            case outsideInfo.tag of
                "receivedMYBEvent" ->
                    case D.decodeValue mybEventDecoder outsideInfo.data of
                        Ok ( mybData, event ) ->
                            tagger <| ReceivedMYBEvent mybData event

                        Err e ->
                            onError "Error when parsing SSE message"

                _ ->
                    onError "Unknown message type"
        )


mybEventDecoder : D.Decoder ( MybData, String )
mybEventDecoder =
    D.succeed Tuple.pair
        |> P.required "data" MybData.mybDataDecoder
        |> P.required "event" D.string
