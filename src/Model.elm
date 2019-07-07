module Model exposing (Message, messageDecoder, messagesDecoder)

import DateUtils
import Json.Decode as D
import Json.Decode.Pipeline as P
import Time exposing (Posix)


type alias Message =
    { id : String
    , title : String
    , content : String
    , createdAt : Posix
    , active : Bool
    }


messagesDecoder : D.Decoder (List Message)
messagesDecoder =
    D.list messageDecoder


messageDecoder : D.Decoder Message
messageDecoder =
    D.succeed Message
        |> P.required "id" D.string
        |> P.required "title" D.string
        |> P.required "content" D.string
        |> P.required "createdAt" DateUtils.dateDecoder
        |> P.required "active" D.bool
