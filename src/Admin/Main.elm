module Admin.Main exposing (main)

import Browser exposing (Document)
import DateUtils
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Http
import Json.Decode as D
import Json.Encode as E
import Model exposing (Message)
import RemoteData as RD exposing (RemoteData(..), WebData)
import Style exposing (..)
import Task
import Time exposing (Posix, Zone)
import Utils


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Flags =
    {}


type alias Model =
    { messages : WebData (List Message)
    , newMessage : EditableData Message
    , zone : Zone
    }


type EditableData a
    = NotEdited
    | Editing a
    | EditSubmitting a
    | EditRefused a


type Msg
    = FetchMessagesResponse (WebData (List Message))
    | CreateMessage
    | NoOp
    | UpdateMessageTitle String
    | UpdateMessageContent String
    | SaveMessage
    | SaveMessageResponse (WebData (ApiResponse (List Message)))
    | ArchiveMessage Message
    | ArchiveMessageResponse (WebData (ApiResponse (List Message)))
    | InitZone Zone


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { messages = NotAsked, newMessage = NotEdited, zone = Time.utc }
    , Cmd.batch [ fetchMessagesCmd, initZone ]
    )


initZone : Cmd Msg
initZone =
    Time.here
        |> Task.perform InitZone


fetchMessagesCmd : Cmd Msg
fetchMessagesCmd =
    Http.get
        { url = "/api/messages/admin"
        , expect = Http.expectJson (RD.fromResult >> FetchMessagesResponse) Model.messagesDecoder
        }


view : Model -> Document Msg
view model =
    { title = "Admin - Black mirror"
    , body =
        List.singleton <|
            layout
                [ Font.family
                    [ Font.external
                        { name = "Roboto"
                        , url = "https://fonts.googleapis.com/css?family=Roboto:100,200,200italic,300,300italic,400,400italic,600,700,800"
                        }
                    ]
                , height fill
                , width fill
                , padding 40
                , Font.size 16
                ]
            <|
                column [ width fill, height fill, spacing 50 ]
                    [ el [ Font.bold, Font.size 30 ] <| text "Admin Black Mirror"
                    , case model.messages of
                        Success messages ->
                            column [ spacing 20 ]
                                [ viewMessages model.zone messages
                                , viewNewMessage model.newMessage
                                ]

                        _ ->
                            text "Chargement..."
                    ]
    }


viewNewMessage : EditableData Message -> Element Msg
viewNewMessage newMessage =
    case newMessage of
        NotEdited ->
            Input.button [ paddingXY 25 10, Border.rounded 4, Background.color greenColor, Font.color whiteColor ]
                { label = text "Ajouter un message"
                , onPress = Just CreateMessage
                }

        Editing message ->
            row [ spacing 10 ]
                [ Input.text [ width <| px 200, Border.solid, Border.width 1, Border.color mediumGreyColor, Border.rounded 4, paddingXY 13 7 ]
                    { onChange = UpdateMessageTitle
                    , text = message.title
                    , placeholder = Nothing
                    , label = Input.labelAbove [ Font.bold ] <| text "Titre"
                    }
                , Input.text [ width <| px 300, Border.solid, Border.width 1, Border.color mediumGreyColor, Border.rounded 4, paddingXY 13 7 ]
                    { onChange = UpdateMessageContent
                    , text = message.content
                    , placeholder = Nothing
                    , label = Input.labelAbove [ Font.bold ] <| text "Contenu"
                    }
                , Input.button [ paddingXY 25 10, Border.rounded 4, Background.color greenColor, Font.color whiteColor, alignBottom ]
                    { label = text "OK"
                    , onPress = Just SaveMessage
                    }
                ]

        _ ->
            text "other"


viewMessages : Zone -> List Message -> Element Msg
viewMessages zone messages =
    if messages == [] then
        text "Aucun message"

    else
        column [ spacing 10 ]
            (messages
                |> List.sortBy (.createdAt >> Time.posixToMillis)
                |> List.map
                    (\message ->
                        row [ spacing 10 ]
                            [ el [ Font.bold ] <| text message.title
                            , text message.content
                            , if message.active then
                                Input.button [ padding 6, Border.rounded 4, Background.color mediumGreyColor, Font.color whiteColor, alignBottom ]
                                    { label =
                                        row [ spacing 5 ]
                                            [ el [] <| Utils.icon "archive"
                                            , el [] <| text "Archiver"
                                            ]
                                    , onPress = Just <| ArchiveMessage message
                                    }

                              else
                                el [ Font.color mediumGreyColor ] <| text "Archivé"
                            , el [ Font.light, Font.italic, Font.size 14 ] <| text <| "Créé le " ++ DateUtils.dateTimeToString zone message.createdAt
                            ]
                    )
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchMessagesResponse response ->
            ( { model | messages = response }, Cmd.none )

        CreateMessage ->
            ( { model | newMessage = Editing initMessage }, Cmd.none )

        UpdateMessageTitle title ->
            let
                newMessage =
                    case model.newMessage of
                        Editing message ->
                            Editing { message | title = title }

                        _ ->
                            model.newMessage
            in
            ( { model | newMessage = newMessage }, Cmd.none )

        UpdateMessageContent content ->
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

        SaveMessage ->
            case model.newMessage of
                Editing message ->
                    ( { model | newMessage = EditSubmitting message }, saveMessageCmd message )

                _ ->
                    ( model, Cmd.none )

        SaveMessageResponse response ->
            case response of
                Success (RespOk messages) ->
                    ( { model | messages = Success messages, newMessage = NotEdited }, Cmd.none )

                _ ->
                    --TODO display error
                    ( model, Cmd.none )

        ArchiveMessage message ->
            ( model, archiveMessageCmd message )

        ArchiveMessageResponse response ->
            case response of
                Success (RespOk messages) ->
                    ( { model | messages = Success messages }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        InitZone zone ->
            ( { model | zone = zone }, Cmd.none )


initMessage : Message
initMessage =
    { id = 0
    , title = ""
    , content = ""
    , createdAt = Time.millisToPosix 0
    , active = False
    }


saveMessageCmd : Message -> Cmd Msg
saveMessageCmd message =
    Http.post
        { url = "/api/messages/admin"
        , body = encodeMessage message |> Http.jsonBody
        , expect =
            Http.expectJson (RD.fromResult >> SaveMessageResponse) (apiResponseDecoder Model.messagesDecoder)
        }


archiveMessageCmd : Message -> Cmd Msg
archiveMessageCmd message =
    Http.get
        { url = "/api/messages/admin/archive/" ++ String.fromInt message.id
        , expect =
            Http.expectJson (RD.fromResult >> ArchiveMessageResponse) (apiResponseDecoder Model.messagesDecoder)
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


type ApiResponse a
    = RespOk a
    | RespFail String
