module Admin.Model exposing (ApiResponse(..), EditableData(..), Flags, Model, Msg(..), apiResponseDecoder, archiveMessageCmd, encodeMessage, fetchMessagesCmd, fetchSoundsCmd, saveMessageCmd, saveSoundCmd, triggerSoundCmd)

import Editable
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
    | EditSoundButtonPressed Sound
    | SoundUrlUpdated Sound String
    | CancelSoundEditButtonPressed Sound
    | SaveSoundButtonPressed Sound
    | GotSaveSoundResponse (WebData (ApiResponse (List Sound)))


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
        { url = "/api/sounds"
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


saveSoundCmd : Sound -> Cmd Msg
saveSoundCmd { id, url } =
    let
        body =
            [ ( "id", E.int id )
            , ( "url", E.string <| Maybe.withDefault "" <| Editable.value url )
            ]
                |> E.object
                |> Http.jsonBody
    in
    Http.post
        { url = "/api/sounds/admin/url"
        , body = body
        , expect =
            Http.expectJson (RD.fromResult >> GotSaveSoundResponse) (apiResponseDecoder Model.soundsDecoder)
        }
