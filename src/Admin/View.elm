module Admin.View exposing (view)

import Admin.Model exposing (EditableData(..), Model, Msg(..))
import Browser exposing (Document)
import DateUtils
import Editable exposing (Editable(..))
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick)
import Element.Font as Font
import Element.Input as Input
import Html.Attributes as HA
import Model exposing (Event(..), Message, Sound, eventToString)
import RemoteData exposing (RemoteData(..))
import Style exposing (..)
import Time exposing (Zone)
import Utils


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
                    , row [ width fill ]
                        [ case model.messages of
                            Success messages ->
                                column [ spacing 20, paddingXY 40 0 ]
                                    [ viewMessages model.zone messages
                                    , viewNewMessage model.newMessage
                                    ]

                            _ ->
                                text "Chargement..."
                        , case model.sounds of
                            Success sounds ->
                                viewSounds sounds

                            _ ->
                                text "Chargement..."
                        ]
                    ]
    }


viewMessages : Zone -> List Message -> Element Msg
viewMessages zone messages =
    if messages == [] then
        text "Aucun message"

    else
        column
            [ width fill
            , alignTop
            , spacing 30
            ]
            [ el [ Font.size 20, Font.bold ] <| text "Messages"
            , column [ spacing 10 ]
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
                                        , onPress = Just <| ArchiveMessageButtonPressed message
                                        }

                                  else
                                    el [ Font.color mediumGreyColor ] <| text "Archivé"
                                , el [ Font.light, Font.italic, Font.size 14 ] <| text <| "Créé le " ++ DateUtils.dateTimeToString zone message.createdAt
                                ]
                        )
                )
            ]


viewNewMessage : EditableData Message -> Element Msg
viewNewMessage newMessage =
    case newMessage of
        NotEdited ->
            Input.button [ paddingXY 25 10, Border.rounded 4, Background.color greenColor, Font.color whiteColor ]
                { label = text "Ajouter un message"
                , onPress = Just NewMessageButtonPressed
                }

        Editing message ->
            row [ spacing 10 ]
                [ Input.text [ width <| px 200, Border.solid, Border.width 1, Border.color mediumGreyColor, Border.rounded 4, paddingXY 13 7 ]
                    { onChange = MessageTitleUpdated
                    , text = message.title
                    , placeholder = Nothing
                    , label = Input.labelAbove [ Font.bold ] <| text "Titre"
                    }
                , Input.text [ width <| px 300, Border.solid, Border.width 1, Border.color mediumGreyColor, Border.rounded 4, paddingXY 13 7 ]
                    { onChange = MessageContentUpdated
                    , text = message.content
                    , placeholder = Nothing
                    , label = Input.labelAbove [ Font.bold ] <| text "Contenu"
                    }
                , Input.button [ paddingXY 25 10, Border.rounded 4, Background.color greenColor, Font.color whiteColor, alignBottom ]
                    { label = text "OK"
                    , onPress = Just SaveMessageButtonPressed
                    }
                ]

        _ ->
            text "other"


viewSounds : List Sound -> Element Msg
viewSounds sounds =
    column
        [ width <| maximum 650 fill
        , Border.widthEach { left = 1, right = 0, bottom = 0, top = 0 }
        , Border.color mediumGreyColor
        , paddingXY 40 0
        , alignTop
        , spacing 30
        ]
        [ el [ Font.size 20, Font.bold ] <| text "Événements & sons"
        , column
            [ spacing 15
            , width fill
            ]
            (sounds
                |> List.filter (\{ event } -> not <| List.member event triggerableEvents)
                |> List.sortBy (.event >> eventToString)
                |> List.map viewSound
            )
        , column
            [ spacing 15
            , Border.widthEach { left = 0, right = 0, bottom = 0, top = 1 }
            , paddingEach { left = 0, right = 0, bottom = 0, top = 20 }
            , Border.color mediumGreyColor
            , width fill
            ]
            (sounds
                |> List.filter (\{ event } -> List.member event triggerableEvents)
                |> List.sortBy (.event >> eventToString)
                |> List.map
                    (\sound ->
                        row [ spacing 10 ]
                            [ viewSound sound
                            , Utils.viewIf (Editable.isReadOnly sound.url) <|
                                Input.button [ paddingXY 12 8, Border.rounded 4, Background.color redColor, Font.color whiteColor ]
                                    { label = text "Déclencher"
                                    , onPress = Just <| TriggerSoundButtonPressed sound
                                    }
                            ]
                    )
            )
        ]


viewSound : Sound -> Element Msg
viewSound ({ event, url } as sound) =
    row [ spacing 10, width fill ]
        [ el [ width <| px 100 ] <| text (eventToString event)
        , el [ width <| px 30, Font.size 20 ]
            (url
                |> Editable.value
                |> Maybe.map
                    (\u ->
                        el
                            [ htmlAttribute <| HA.title "Lire le son"
                            , onClick <| SoundIconClicked u
                            , pointer
                            ]
                        <|
                            Utils.icon "volume-up"
                    )
                |> Maybe.withDefault (el [ Font.color mediumGreyColor ] <| Utils.icon "volume-off")
            )
        , case url of
            ReadOnly _ ->
                el [ width <| px 100 ] <|
                    Input.button [ paddingXY 12 8, Border.rounded 4, Background.color greenColor, Font.color whiteColor ]
                        { label = text "Changer"
                        , onPress = Just <| EditSoundButtonPressed sound
                        }

            Editable _ new ->
                row [ spacing 8 ]
                    [ Input.text [ width <| px 400, Border.solid, Border.width 1, Border.color mediumGreyColor, Border.rounded 4, paddingXY 13 7 ]
                        { onChange = SoundUrlUpdated sound
                        , text = new |> Maybe.withDefault ""
                        , placeholder = Just <| Input.placeholder [ height fill ] <| el [ centerY ] <| text "URL"
                        , label = Input.labelHidden ""
                        }
                    , Input.button [ paddingXY 12 8, Border.rounded 4, Background.color redColor, Font.color whiteColor ]
                        { label = el [] <| Utils.icon "close"
                        , onPress = Just <| CancelSoundEditButtonPressed sound
                        }
                    , Input.button [ paddingXY 12 8, Border.rounded 4, Background.color greenColor, Font.color whiteColor ]
                        { label = el [] <| Utils.icon "check"
                        , onPress = Just <| SaveSoundButtonPressed sound
                        }
                    ]
        ]


triggerableEvents : List Event
triggerableEvents =
    [ Alarm, Custom ]
