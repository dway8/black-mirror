module Admin.Main exposing (main)

import Admin.Model exposing (ApiResponse(..), EditableData(..), Flags, Model, Msg(..), archiveMessageCmd, fetchMessagesCmd, fetchSoundsCmd, saveMessageCmd, triggerSoundCmd)
import Admin.View as View
import Browser
import Element exposing (..)
import Model exposing (Message)
import Ports exposing (InfoForOutside(..))
import RemoteData exposing (RemoteData(..))
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


initMessage : Message
initMessage =
    { id = 0
    , title = ""
    , content = ""
    , createdAt = Time.millisToPosix 0
    , active = False
    }
