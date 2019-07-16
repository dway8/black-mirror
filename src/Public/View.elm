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
import Public.MybData exposing (MybData, MybOpening)
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
                        , spacing (windowRatio model.window 20)
                        ]
                        (viewHeader model
                            :: (if DateUtils.isNightTime model.zone model.now then
                                    [ el [ centerX, centerY, Font.size (windowRatio model.window 150) ] <| Utils.icon "notifications-paused" ]

                                else
                                    case model.mybData of
                                        Success data ->
                                            [ viewCountsMybData model.window data
                                            , viewOpeningsAndMoneyMybData model.window model.zone model.counter data
                                            , viewMessagesAndTweet model.window model.counter model.messageCursor model.messages model.lastTweet
                                            ]

                                        _ ->
                                            [ el [ centerX, centerY ] <| text "Chargement..." ]
                               )
                        )
    }


viewHeader : Model -> Element Msg
viewHeader { zone, now, window, saint, weather } =
    column
        [ width fill ]
        [ row
            [ spaceEvenly, alignTop, width fill ]
            [ viewDate window zone now
            , viewTime window zone now
            ]
        , row
            [ width fill, spaceEvenly ]
            [ viewSaint window saint
            , row
                [ centerY, Font.size (windowRatio window 44), alignRight, moveRight (toFloat (windowRatio window 20)) ]
                [ el [ Font.bold, moveRight (toFloat (windowRatio window 20)) ] <| text (Round.round 1 weather.temperature ++ "°")
                , viewWeatherIcon window weather.icon
                ]
            ]
        ]


viewDate : Window -> Zone -> Posix -> Element Msg
viewDate window zone now =
    column
        [ spacing (windowRatio window 6) ]
        [ el [ Font.bold, Font.size (windowRatio window 40) ] <| text (Utils.ucfirst (DateUtils.dayOfWeek zone now))
        , el [ Font.light, Font.size (windowRatio window 32) ] <| text <| DateUtils.dayAndMonth zone now
        ]


viewTime : Window -> Zone -> Posix -> Element Msg
viewTime window zone now =
    el [ Font.light, Font.size (windowRatio window 90), alignRight ] <| text <| DateUtils.time zone now


viewSaint : Window -> String -> Element Msg
viewSaint window saint =
    row
        [ spacing (windowRatio window 10), Font.bold, Font.size (windowRatio window 22) ]
        [ el [] <| Utils.icon "chevron-right zmdi-hc-lg"
        , el [] <| text (cropNameIfLongerThan 20 saint)
        ]


viewWeatherIcon : Window -> String -> Element Msg
viewWeatherIcon window icon =
    image [ width (px (windowRatio window 100)) ] { src = getSvgIcon icon, description = "" }


viewCountsMybData : Window -> MybData -> Element Msg
viewCountsMybData window { todayUsers, totalUsers, todayOrders, totalOrders, todayExhibitors, totalExhibitors, todayClients, totalClients, todayProdOccurrences, totalProdOccurrences, todayOpenOccurrences, totalOpenOccurrences } =
    row
        [ width fill, spaceEvenly ]
        [ column
            [ spacing (windowRatio window 22), alignLeft, centerY ]
            [ viewGenericCount window todayUsers totalUsers "Orga."
            , viewGenericCount window todayOrders totalOrders "Résa"
            , viewGenericCount window todayExhibitors totalExhibitors "Exposants"
            ]
        , el [ Border.widthEach { left = 2, top = 0, bottom = 0, right = 0 }, Border.solid, centerX, centerY, height fill, alpha 0.4 ] <| none
        , column [ spacing (windowRatio window 22), alignLeft, centerY ]
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
            , el [ Font.size (windowRatio window 76), Font.bold ] <| text (String.fromInt todayCount)
            ]
        , column
            [ spacing (windowRatio window 3) ]
            [ el [ Font.size (windowRatio window 34), Font.bold ] <|
                (totalCount
                    |> toFloat
                    |> FN.format { frenchLocale | decimals = 0 }
                    |> text
                )
            , el [ Font.size (windowRatio window 23) ] <| text label
            ]
        ]


viewOpeningsAndMoneyMybData : Window -> Zone -> Int -> MybData -> Element Msg
viewOpeningsAndMoneyMybData window zone counter data =
    el [ paddingEach { top = windowRatio window 20, bottom = 0, left = 0, right = 0 }, centerX ] <|
        if modBy 2 counter == 0 && data.openings /= [] then
            viewOpenings window zone data.openings

        else
            viewMoneyMybData window data


viewOpenings : Window -> Zone -> List MybOpening -> Element Msg
viewOpenings window zone openings =
    column [ spacing (windowRatio window 20), width fill ]
        [ el [ Font.bold, Font.size (windowRatio window 30) ] <| text "Ouvertures J+7"
        , column [ Font.size (windowRatio window 19), spacing (windowRatio window 13), width fill ]
            (openings
                |> List.sortBy (.openingDate >> Time.posixToMillis)
                |> List.map
                    (\{ name, openingDate } ->
                        row [ spacing (windowRatio window 10), width fill ]
                            [ el [ Font.bold, width <| fillPortion 1 ] <| el [ alignRight ] <| text <| Utils.ucfirst <| DateUtils.dayOfWeekShort zone openingDate ++ "."
                            , el [ width <| fillPortion 8 ] <| text (cropNameIfLongerThan 45 name)
                            ]
                    )
            )
        ]


cropNameIfLongerThan : Int -> String -> String
cropNameIfLongerThan max name =
    if String.length name > max then
        String.left max name ++ "..."

    else
        name


viewMoneyMybData : Window -> MybData -> Element Msg
viewMoneyMybData window data =
    let
        toEur va =
            va
                |> toFloat
                |> (\i -> i / 100)
                |> FN.format { frenchLocale | decimals = 0 }
                |> (\i -> i ++ "€")
    in
    column [ spacing (windowRatio window 14), centerX ]
        [ row
            [ spacing (windowRatio window 22)
            , centerX
            ]
            [ row [ alignLeft, spacing (windowRatio window 10) ]
                [ el [ Font.size (windowRatio window 50) ] <| text "+"
                , el [ Font.size (windowRatio window 68), Font.bold ] <| text (toEur data.todayVA)
                ]
            , column
                [ spacing (windowRatio window 2) ]
                [ el [ Font.size (windowRatio window 34), Font.bold ] <| text (toEur data.totalVA)
                , el [ Font.size (windowRatio window 23) ] <| text "Vol. d'affaires"
                ]
            ]
        , row
            [ spacing (windowRatio window 18), centerX ]
            [ el [ Font.size (windowRatio window 48), moveUp <| toFloat (windowRatio window 3) ] <| Utils.icon "shopping-basket"
            , el [ Font.size (windowRatio window 46) ] <|
                (data.avgCart
                    |> String.fromInt
                    |> (\a -> a ++ "\u{00A0}€")
                    |> text
                )
            ]
        ]


viewMessagesAndTweet : Window -> Int -> Int -> WebData (List Message) -> WebData Tweet -> Element Msg
viewMessagesAndTweet window counter messageCursor rdMessages tweet =
    if modBy 2 counter == 1 then
        case rdMessages of
            Success messages ->
                let
                    currentMessage =
                        LE.getAt messageCursor messages
                in
                case currentMessage of
                    Nothing ->
                        viewTweet window tweet

                    Just message ->
                        column
                            [ Background.color whiteColor
                            , Font.color blackColor
                            , width fill
                            , centerY
                            , Border.rounded (windowRatio window 14)
                            , paddingEach { top = windowRatio window 18, bottom = windowRatio window 26, left = windowRatio window 18, right = windowRatio window 18 }
                            , spacing (windowRatio window 14)
                            ]
                            [ paragraph [ Font.size (windowRatio window 28), Font.bold ] [ text message.title ]
                            , paragraph [ Font.size (windowRatio window 24) ] [ text message.content ]
                            ]

            _ ->
                viewTweet window tweet

    else
        none


viewTweet : Window -> WebData Tweet -> Element Msg
viewTweet window tweet =
    case tweet of
        Success t ->
            row
                [ spacing (windowRatio window 40), width fill, alignBottom ]
                [ case t.media of
                    photo :: [] ->
                        el [] <|
                            image
                                [ width <| px (windowRatio window (photo.size.width * 0.4))
                                , height <| px (windowRatio window (photo.size.height * 0.4))
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
