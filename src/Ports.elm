port module Ports exposing (GenericOutsideData, InfoForOutside(..), infoForOutside, sendInfoOutside)

import Json.Encode as E


type alias GenericOutsideData =
    { tag : String
    , data : E.Value
    }


type InfoForOutside
    = PlayCashRegister
    | PlayFanfare
    | PlayKnock


port infoForOutside : GenericOutsideData -> Cmd msg


sendInfoOutside : InfoForOutside -> Cmd msg
sendInfoOutside info =
    case info of
        PlayCashRegister ->
            infoForOutside { tag = "playCashRegister", data = E.null }

        PlayFanfare ->
            infoForOutside { tag = "playFanfare", data = E.null }

        PlayKnock ->
            infoForOutside { tag = "playKnock", data = E.null }
