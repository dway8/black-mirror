module Public.View exposing (view)

import Browser exposing (Document)
import DateUtils
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import FormatNumber as FN
import FormatNumber.Locales exposing (frenchLocale)
import List.Extra as LE
import Model exposing (Message)
import Public.Model exposing (Model, Msg, Tweet, Window)
import Public.MybData exposing (MybData)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import Style exposing (blackColor, whiteColor, windowRatio)
import Time exposing (Posix, Zone)
import Utils


view : Model -> Document Msg
view model =
    { title = "Black mirror"
    , body =
        List.singleton <|
            layout
                [ Font.family
                    [ Font.external
                        { name = "Roboto"
                        , url = "https://fonts.googleapis.com/css?family=Roboto:300,300italic,400,400italic,700"
                        }
                    ]
                , height fill
                , width fill
                , Background.color (rgb255 240 240 240)
                ]
            <|
                el
                    ([ centerX
                     , clipX
                     , clipY
                     , Background.color blackColor
                     , Font.color whiteColor
                     ]
                        ++ (if Utils.isDesktop model.window then
                                [ centerY, padding 30, width <| px 500, height <| px 889 ]

                            else
                                [ width fill, height fill ]
                           )
                    )
                <|
                    column
                        [ width fill
                        , height fill
                        , centerX
                        ]
                        (viewHeader model
                            :: (if DateUtils.isNightTime model.zone model.now then
                                    [ el [ centerX, centerY, Font.size (windowRatio model.window 150) ] <| Utils.icon "notifications-paused" ]

                                else
                                    (case model.mybData of
                                        Success data ->
                                            [ viewCountsMybData model.window data
                                            , viewMoneyMybData model.window data
                                            ]

                                        _ ->
                                            [ el [ centerX, centerY ] <| text "Chargement..." ]
                                    )
                                        ++ [ viewMessagesAndTweet model.window model.messageCursor model.messages model.lastTweet
                                           ]
                               )
                        )
    }


viewHeader : Model -> Element Msg
viewHeader { zone, now, window, saint, weather } =
    column
        [ width fill, spacing (windowRatio window 20) ]
        [ row
            [ spaceEvenly, alignTop, width fill ]
            [ viewDate window zone now
            , viewTime window zone now
            ]
        , row
            [ width fill, spaceEvenly ]
            [ viewSaint window saint
            , row
                [ centerY, Font.size (windowRatio window 60), alignRight ]
                [ el [ Font.bold, moveRight (toFloat (windowRatio window 20)) ] <| text (Round.round 1 weather.temperature ++ "°")
                , viewWeatherIcon window weather.icon
                ]
            ]
        ]


viewDate : Window -> Zone -> Posix -> Element Msg
viewDate window zone now =
    column
        [ spacing (windowRatio window 10) ]
        [ el [ Font.bold, Font.size (windowRatio window 50) ] <| text (Utils.ucfirst (DateUtils.dayOfWeek zone now))
        , el [ Font.light, Font.size (windowRatio window 34) ] <| text <| DateUtils.dayAndMonth zone now
        ]


viewTime : Window -> Zone -> Posix -> Element Msg
viewTime window zone now =
    el [ Font.light, Font.size (windowRatio window 90), alignRight ] <| text <| DateUtils.time zone now


viewSaint : Window -> String -> Element Msg
viewSaint window saint =
    row
        [ spacing 30, Font.bold, Font.size (windowRatio window 24) ]
        [ el [] <| Utils.icon "chevron-right zmdi-hc-lg"
        , el [] <| text saint
        ]


viewWeatherIcon : Window -> String -> Element Msg
viewWeatherIcon window icon =
    image [ width (px (windowRatio window 100)) ] { src = getSvgIcon icon, description = "" }


viewCountsMybData : Window -> MybData -> Element Msg
viewCountsMybData window { todayUsers, totalUsers, todayOrders, totalOrders, todayExhibitors, totalExhibitors, todayClients, totalClients, todayProdOccurrences, totalProdOccurrences, todayOpenOccurrences, totalOpenOccurrences } =
    row
        [ width fill, spaceEvenly ]
        [ column
            [ spacing 50, alignLeft, centerY ]
            [ viewGenericCount window todayUsers totalUsers "Orga."
            , viewGenericCount window todayOrders totalOrders "Résa"
            , viewGenericCount window todayExhibitors totalExhibitors "Exposants"
            ]
        , el [ Border.widthEach { left = 1, top = 0, bottom = 0, right = 0 }, Border.solid, centerX, centerY, height fill ] <| none
        , column [ spacing 50, alignLeft, centerY ]
            [ viewGenericCount window todayClients totalClients "Clients"
            , viewGenericCount window todayProdOccurrences totalProdOccurrences "Éd. prod"
            , viewGenericCount window todayOpenOccurrences totalOpenOccurrences "Éd. ouvertes"
            ]
        ]


viewGenericCount : Window -> Int -> Int -> String -> Element Msg
viewGenericCount window todayCount totalCount label =
    row
        [ spacing (windowRatio window 10), centerY, width fill ]
        [ row [ alignLeft, spacing (windowRatio window 10) ]
            [ el [ Font.size (windowRatio window 50) ] <| text "+"
            , el [ Font.size (windowRatio window 80), Font.bold ] <| text (String.fromInt todayCount)
            ]
        , column
            [ spacing (windowRatio window 3) ]
            [ el [ Font.size (windowRatio window 34), Font.bold ] <|
                (totalCount
                    |> toFloat
                    |> FN.format { frenchLocale | decimals = 0 }
                    |> text
                )
            , el [ Font.light, Font.size (windowRatio window 24) ] <| text label
            ]
        ]


viewMoneyMybData : Window -> MybData -> Element Msg
viewMoneyMybData window data =
    row
        [ spacing (windowRatio window 40)
        , centerX
        ]
        [ el [ Font.size (windowRatio window 34) ] <| Utils.icon "shopping-cart zmdi-hc-4x"
        , column
            [ spacing 15 ]
            [ el [ Font.size (windowRatio window 46), Font.bold ] <|
                (data.va
                    |> toFloat
                    |> (\i -> i / 100)
                    |> FN.format { frenchLocale | decimals = 0 }
                    |> (\i -> i ++ " €")
                    |> text
                )
            , row
                [ spacing 40, centerY ]
                [ el [ Font.size (windowRatio window 34) ] <| Utils.icon "shopping-basket zmdi-hc-lg"
                , el [ Font.size (windowRatio window 40), Font.light ] <|
                    (data.avgCart
                        |> String.fromInt
                        |> (\a -> a ++ " €")
                        |> text
                    )
                ]
            ]
        ]


viewMessagesAndTweet : Window -> Int -> WebData (List Message) -> WebData Tweet -> Element Msg
viewMessagesAndTweet window messageCursor rdMessages tweet =
    case rdMessages of
        Success messages ->
            let
                currentMessage =
                    LE.getAt messageCursor messages
            in
            case currentMessage of
                Nothing ->
                    viewTweet tweet

                Just message ->
                    column
                        [ Background.color whiteColor
                        , Font.color blackColor
                        , centerX
                        , centerY
                        , Border.rounded (windowRatio window 14)
                        , paddingEach { top = windowRatio window 20, bottom = windowRatio window 28, left = windowRatio window 20, right = windowRatio window 20 }
                        , spacing (windowRatio window 15)
                        ]
                        [ paragraph [ Font.size (windowRatio window 30), Font.bold ] [ text message.title ]
                        , paragraph [ Font.size (windowRatio window 28) ] [ text message.content ]
                        ]

        _ ->
            viewTweet tweet


viewTweet : WebData Tweet -> Element Msg
viewTweet tweet =
    case tweet of
        Success t ->
            row
                [ spacing 40, centerY, width fill ]
                [ case t.media of
                    photo :: [] ->
                        el [] <|
                            image
                                [ width <| px (round (photo.size.width * 0.5))
                                , height <| px (round (photo.size.height * 0.5))
                                ]
                                { src = photo.mediaUrl, description = "" }

                    _ ->
                        el [] <| Utils.icon "twitter zmdi-hc-5x"
                , paragraph [ Font.light ] [ text t.text ]
                ]

        _ ->
            none


getSvgIcon : String -> String
getSvgIcon icon =
    let
        path =
            case icon of
                "clear-day" ->
                    "Sun"

                "clear-night" ->
                    "Moon"

                "rain" ->
                    "Cloud-Rain"

                "snow" ->
                    "Cloud-Snow-Alt"

                "sleet" ->
                    "Cloud-Hail"

                "hail" ->
                    "Cloud-Hail-Alt"

                "wind" ->
                    "Wind"

                "fog" ->
                    "Cloud-Fog"

                "cloudy" ->
                    "Cloud"

                "partly-cloudy-day" ->
                    "Cloud-Sun"

                "partly-cloudy-night" ->
                    "Cloud-Moon"

                "thunderstorm" ->
                    "Cloud-Lightning"

                "tornado" ->
                    "Tornado"

                _ ->
                    "Sun"
    in
    "climacons/" ++ path ++ ".svg"
