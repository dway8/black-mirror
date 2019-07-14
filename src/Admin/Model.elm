module Admin.Model exposing (ApiResponse(..), EditableData(..), Flags, Model, Msg(..), apiResponseDecoder, archiveMessageCmd, encodeMessage, fetchMessagesCmd, fetchSoundsCmd, saveMessageCmd, triggerSoundCmd)

import Http
import Json.Decode as D
import Json.Encode as E
import Model exposing (Message, Sound)
import RemoteData as RD exposing (RemoteData(..), WebData)
import Time exposing (Zone)


type alias Flags =
    {}


type alias Model =
    { messages : WebData (List Message)
    , newMessage : EditableData Message
    , zone : Zone
    , sounds : WebData (List Sound)
    }


type EditableData a
    = NotEdited
    | Editing a
    | EditSubmitting a
    | EditRefused a


type Msg
    = GotFetchMessagesResponse (WebData (List Message))
    | NewMessageButtonPressed
    | NoOp
    | MessageTitleUpdated String
    | MessageContentUpdated String
    | SaveMessageButtonPressed
    | GotSaveMessageResponse (WebData (ApiResponse (List Message)))
    | ArchiveMessageButtonPressed Message
    | GotArchiveMessageResponse (WebData (ApiResponse (List Message)))
    | InitZone Zone
    | GotFetchSoundsResponse (WebData (List Sound))
    | SoundIconClicked String
    | TriggerSoundButtonPressed Sound


type ApiResponse a
    = RespOk a
    | RespFail String


fetchMessagesCmd : Cmd Msg
fetchMessagesCmd =
    Http.get
        { url = "/api/messages/admin"
        , expect = Http.expectJson (RD.fromResult >> GotFetchMessagesResponse) Model.messagesDecoder
        }


fetchSoundsCmd : Cmd Msg
fetchSoundsCmd =
    Http.get
        { url = "/api/sounds/admin"
        , expect = Http.expectJson (RD.fromResult >> GotFetchSoundsResponse) Model.soundsDecoder
        }


saveMessageCmd : Message -> Cmd Msg
saveMessageCmd message =
    Http.post
        { url = "/api/messages/admin"
        , body = encodeMessage message |> Http.jsonBody
        , expect =
            Http.expectJson (RD.fromResult >> GotSaveMessageResponse) (apiResponseDecoder Model.messagesDecoder)
        }


archiveMessageCmd : Message -> Cmd Msg
archiveMessageCmd message =
    Http.get
        { url = "/api/messages/admin/archive/" ++ String.fromInt message.id
        , expect =
            Http.expectJson (RD.fromResult >> GotArchiveMessageResponse) (apiResponseDecoder Model.messagesDecoder)
        }


apiResponseDecoder : D.Decoder a -> D.Decoder (ApiResponse a)
apiResponseDecoder decodeA =
    D.field "success" D.bool
        |> D.andThen
            (\success ->
                if success then
                    D.map RespOk <| D.field "data" decodeA

                else
                    D.map RespFail <| D.field "error" D.string
            )


encodeMessage : Message -> E.Value
encodeMessage { title, content } =
    [ ( "title", E.string title )
    , ( "content", E.string content )
    ]
        |> E.object


triggerSoundCmd : Int -> Cmd Msg
triggerSoundCmd id =
    Http.get
        { url = "/api/sounds/admin/trigger/" ++ String.fromInt id
        , expect =
            Http.expectJson (RD.fromResult >> always NoOp) (D.succeed ())
        }
