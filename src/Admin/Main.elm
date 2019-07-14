module Admin.Main exposing (main)

import Admin.Model exposing (ApiResponse(..), EditableData(..), Flags, Model, Msg(..), archiveMessageCmd, fetchMessagesCmd, fetchSoundsCmd, saveMessageCmd, saveSoundCmd, triggerSoundCmd)
import Admin.View as View
import Browser
import Editable
import Element exposing (..)
import Model exposing (Message, Sound)
import Ports exposing (InfoForOutside(..))
import RemoteData as RD exposing (RemoteData(..), WebData)
import Task
import Time


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = View.view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { messages = Loading
      , newMessage = NotEdited
      , zone = Time.utc
      , sounds = Loading
      }
    , Cmd.batch [ fetchMessagesCmd, fetchSoundsCmd, initZone ]
    )


initZone : Cmd Msg
initZone =
    Time.here
        |> Task.perform InitZone


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotFetchMessagesResponse response ->
            ( { model | messages = response }, Cmd.none )

        NewMessageButtonPressed ->
            ( { model | newMessage = Editing initMessage }, Cmd.none )

        MessageTitleUpdated title ->
            let
                newMessage =
                    case model.newMessage of
                        Editing message ->
                            Editing { message | title = title }

                        _ ->
                            model.newMessage
            in
            ( { model | newMessage = newMessage }, Cmd.none )

        MessageContentUpdated content ->
            let
                newMessage =
                    case model.newMessage of
                        Editing message ->
                            Editing { message | content = content }

                        _ ->
                            model.newMessage
            in
            ( { model | newMessage = newMessage }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        SaveMessageButtonPressed ->
            case model.newMessage of
                Editing message ->
                    ( { model | newMessage = EditSubmitting message }, saveMessageCmd message )

                _ ->
                    ( model, Cmd.none )

        GotSaveMessageResponse response ->
            case response of
                Success (RespOk messages) ->
                    ( { model | messages = Success messages, newMessage = NotEdited }, Cmd.none )

                _ ->
                    --TODO display error
                    ( model, Cmd.none )

        ArchiveMessageButtonPressed message ->
            ( model, archiveMessageCmd message )

        GotArchiveMessageResponse response ->
            case response of
                Success (RespOk messages) ->
                    ( { model | messages = Success messages }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        InitZone zone ->
            ( { model | zone = zone }, Cmd.none )

        GotFetchSoundsResponse response ->
            ( { model | sounds = response }, Cmd.none )

        SoundIconClicked url ->
            ( model, Ports.sendInfoOutside <| PlaySound url )

        TriggerSoundButtonPressed sound ->
            ( model, triggerSoundCmd sound.id )

        EditSoundButtonPressed sound ->
            let
                updateSoundFn s =
                    { s
                        | url =
                            s.url
                                |> Editable.edit
                                |> Editable.map identity
                    }

                newSounds =
                    model.sounds
                        |> updateSoundInList updateSoundFn sound
            in
            ( { model | sounds = newSounds }, Cmd.none )

        SoundUrlUpdated sound val ->
            let
                updateSoundFn s =
                    { s | url = Editable.map (always (Just val)) s.url }

                newSounds =
                    model.sounds
                        |> updateSoundInList updateSoundFn sound
            in
            ( { model | sounds = newSounds }, Cmd.none )

        CancelSoundEditButtonPressed sound ->
            let
                updateSoundFn s =
                    { s | url = Editable.cancel s.url }

                newSounds =
                    model.sounds
                        |> updateSoundInList updateSoundFn sound
            in
            ( { model | sounds = newSounds }, Cmd.none )

        SaveSoundButtonPressed sound ->
            let
                cmd =
                    if Editable.isDirty sound.url then
                        saveSoundCmd sound

                    else
                        Cmd.none
            in
            ( model, cmd )

        GotSaveSoundResponse response ->
            case response of
                Success (RespOk sounds) ->
                    ( { model | sounds = Success sounds }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


updateSoundInList : (Sound -> Sound) -> Sound -> WebData (List Sound) -> WebData (List Sound)
updateSoundInList updateFn sound sounds =
    sounds
        |> RD.map
            (List.map
                (\s ->
                    if s.id == sound.id then
                        updateFn s

                    else
                        s
                )
            )


initMessage : Message
initMessage =
    { id = 0
    , title = ""
    , content = ""
    , createdAt = Time.millisToPosix 0
    , active = False
    }
