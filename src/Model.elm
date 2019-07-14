module Model exposing (Event(..), Message, Sound, eventDecoder, eventToString, messagesDecoder, soundDecoder, soundsDecoder)

import DateUtils
import Editable exposing (Editable(..))
import Json.Decode as D
import Json.Decode.Pipeline as P
import Time exposing (Posix)


type alias Message =
    { id : Int
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
        |> P.required "id" D.int
        |> P.required "title" D.string
        |> P.required "content" D.string
        |> P.required "createdAt" DateUtils.dateDecoder
        |> P.required "active" D.bool


type alias Sound =
    { id : Int
    , event : Event
    , url : Editable (Maybe String)
    }


type Event
    = NewOrder
    | NewProdOccurrence
    | NewUser
    | NewMessage
    | Alarm
    | Custom


soundsDecoder : D.Decoder (List Sound)
soundsDecoder =
    D.list soundDecoder


soundDecoder : D.Decoder Sound
soundDecoder =
    D.succeed Sound
        |> P.required "id" D.int
        |> P.required "event" eventDecoder
        |> P.required "url" (D.map ReadOnly <| D.nullable D.string)


eventDecoder : D.Decoder Event
eventDecoder =
    D.string
        |> D.andThen
            (\str ->
                case str of
                    "new_order" ->
                        D.succeed NewOrder

                    "new_prod_occurrence" ->
                        D.succeed NewProdOccurrence

                    "new_user" ->
                        D.succeed NewUser

                    "new_message" ->
                        D.succeed NewMessage

                    "alarm" ->
                        D.succeed Alarm

                    "custom" ->
                        D.succeed Custom

                    _ ->
                        D.fail <| "unknown event: " ++ str
            )


eventToString : Event -> String
eventToString event =
    case event of
        NewOrder ->
            "Commande"

        NewProdOccurrence ->
            "Activation"

        NewUser ->
            "Inscrit"

        NewMessage ->
            "Message"

        Alarm ->
            "Alarma"

        Custom ->
            "Custom"
