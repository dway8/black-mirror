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
import Public.Model exposing (Model, Msg, Slide(..), Tweet, Window)
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
                                [ centerY, width <| px 500, height <| px 889 ]

                            else
                                [ width fill, height fill ]
                           )
                    )
                <|
                    column
                        [ width fill
                        , height fill
                        , centerX
                        , spacing (windowRatio model.window 30)
                        ]
                        (viewHeader model
                            :: (if DateUtils.isNightTime model.zone model.now then
                                    [ el [ centerX, centerY, Font.size (windowRatio model.window 150) ] <| Utils.icon "notifications-paused" ]

                                else
                                    case model.mybData of
                                        Success data ->
                                            [ column [ width fill, spacing (windowRatio model.window 34), paddingXY (windowRatio model.window 40) 0 ]
                                                [ viewCountsMybData model.window data
                                                , el [ Border.widthEach { left = 0, top = 0, bottom = 2, right = 0 }, Border.solid, centerX, centerY, width fill, alpha 0.4 ] <| none
                                                ]
                                            , viewSlidingData model data
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
                [ centerY, Font.size (windowRatio window 44), alignRight ]
                [ el [ Font.bold ] <| text (Round.round 1 weather.temperature ++ "°")
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
    el [ width (px (windowRatio window 70)), height (px (windowRatio window 70)), clip ] <|
        image [ width (px (windowRatio window 110)), centerX, moveUp <| toFloat (windowRatio window 22) ] { src = getSvgIcon icon, description = "" }


viewCountsMybData : Window -> MybData -> Element Msg
viewCountsMybData window { todayUsers, yearUsers, totalUsers, todayOrders, yearOrders, totalOrders, todayExhibitors, yearExhibitors, totalExhibitors, todayClients, yearClients, totalClients, todayProdOccurrences, yearProdOccurrences, totalProdOccurrences, todayOpenOccurrences, totalOpenOccurrences } =
    row
        [ width fill, spaceEvenly, paddingXY (windowRatio window 20) 0 ]
        [ column
            [ spacing (windowRatio window 22), alignLeft ]
            [ viewGenericCount window todayUsers (Just yearUsers) totalUsers "Inscrits agenda"
            , viewGenericCount window todayClients (Just yearClients) totalClients "Clients"
            , viewGenericCount window todayProdOccurrences (Just yearProdOccurrences) totalProdOccurrences "Éd. prod"
            ]
        , column [ spacing (windowRatio window 22), alignLeft ]
            [ viewGenericCount window todayExhibitors (Just yearExhibitors) totalExhibitors "Exposants"
            , viewGenericCount window todayOrders (Just yearOrders) totalOrders "Commandes"
            , viewGenericCount window todayOpenOccurrences Nothing totalOpenOccurrences "Éd. ouvertes"
            ]
        ]


viewGenericCount : Window -> Int -> Maybe Int -> Int -> String -> Element Msg
viewGenericCount window todayCount maybeYearCount totalCount label =
    column
        [ spacing (windowRatio window 8), centerY, width fill ]
        [ column
            [ width fill ]
            [ row [ alignLeft, spacing (windowRatio window 6) ]
                [ el [ Font.size (windowRatio window 38) ] <| text "+"
                , el [ Font.size (windowRatio window 48), Font.bold ] <| text (String.fromInt todayCount)
                ]
            , el [ Font.size (windowRatio window 22) ] <| text label
            ]
        , case maybeYearCount of
            Just yearCount ->
                row [ spacing (windowRatio window 12) ]
                    [ el [ Font.size (windowRatio window 30), Font.bold ] <|
                        (yearCount
                            |> toFloat
                            |> FN.format { frenchLocale | decimals = 0 }
                            |> text
                        )
                    , row [ spacing (windowRatio window 12) ]
                        [ el [ Border.widthEach { left = 2, top = 0, bottom = 0, right = 0 }, Border.solid, centerX, centerY, height fill, Font.size (windowRatio window 26) ] none
                        , el [ Font.size (windowRatio window 18) ] <|
                            (totalCount
                                |> toFloat
                                |> FN.format { frenchLocale | decimals = 0 }
                                |> text
                            )
                        ]
                    ]

            Nothing ->
                el [ Font.size (windowRatio window 36), Font.bold ] <|
                    (totalCount
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
        ]


viewSlidingData : Model -> MybData -> Element Msg
viewSlidingData model mybData =
    case model.currentSlide of
        MoneySlide ->
            viewMoneyMybData model.window mybData

        MessageSlide idx ->
            viewMessage model.window model.messages idx

        TweetSlide ->
            viewTweet model.window model.lastTweet

        OpeningsSlide ->
            viewOpenings model.window model.zone mybData.openings


viewOpenings : Window -> Zone -> List MybOpening -> Element Msg
viewOpenings window zone openings =
    column [ spacing (windowRatio window 20), width fill, paddingXY (windowRatio window 40) 0 ]
        [ row [ spacing (windowRatio window 16) ]
            [ el [ Font.size (windowRatio window 46), moveUp <| toFloat (windowRatio window 3) ] <| Utils.icon "calendar-alt"
            , el [ Font.bold, Font.size (windowRatio window 30) ] <| text "Ouvertures J+7"
            ]
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
        String.left (max - 3) name ++ "..."

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
                |> (\i -> i ++ "\u{00A0}€")
    in
    row [ spacing (windowRatio window 10), paddingXY (windowRatio window 60) 0 ]
        [ el [ Font.size (windowRatio window 40), alignTop, moveDown (windowRatio window 12 |> toFloat) ] <| text "+"
        , column [ spacing (windowRatio window 16) ]
            [ column [ spacing (windowRatio window 12) ]
                [ el [ Font.size (windowRatio window 66), Font.bold, alignBottom ] <| text (toEur data.todayVA)
                , column [ spacing (windowRatio window 10) ]
                    [ el [ Font.size (windowRatio window 23) ] <| text "Volume d'affaires"
                    , row
                        [ spacing (windowRatio window 12) ]
                        [ el [ Font.size (windowRatio window 34), Font.bold ] <| text (toEur data.yearVA)
                        , row [ spacing (windowRatio window 12), height fill ]
                            [ el [ Border.widthEach { left = 2, top = 0, bottom = 0, right = 0 }, Border.solid, centerX, centerY, height fill, Font.size (windowRatio window 26) ] none
                            , el [ Font.size (windowRatio window 24), alignBottom, moveUp (windowRatio window 3 |> toFloat) ] <| text (toEur data.totalVA)
                            ]
                        ]
                    ]
                ]
            , row
                [ spacing (windowRatio window 18) ]
                [ el [ Font.size (windowRatio window 48), moveUp <| toFloat (windowRatio window 3) ] <| Utils.icon "shopping-basket"
                , el [ Font.size (windowRatio window 46) ] <|
                    (data.avgCart
                        |> String.fromInt
                        |> (\a -> a ++ "\u{00A0}€")
                        |> text
                    )
                ]
            ]
        ]


viewMessage : Window -> WebData (List Message) -> Int -> Element Msg
viewMessage window rdMessages idx =
    case rdMessages of
        Success messages ->
            let
                currentMessage =
                    LE.getAt idx messages
            in
            case currentMessage of
                Nothing ->
                    none

                Just message ->
                    el [ paddingEach { top = 0, bottom = windowRatio window 30, left = windowRatio window 30, right = windowRatio window 30 }, width fill ] <|
                        column
                            [ Background.color whiteColor
                            , Font.color blackColor
                            , width fill
                            , Border.rounded (windowRatio window 14)
                            , paddingEach { top = windowRatio window 18, bottom = windowRatio window 26, left = windowRatio window 18, right = windowRatio window 18 }
                            , spacing (windowRatio window 10)
                            ]
                            [ paragraph [ Font.size (windowRatio window 28), Font.bold ] [ text message.title ]
                            , paragraph [ Font.size (windowRatio window 22) ] [ text message.content ]
                            ]

        _ ->
            none


viewTweet : Window -> WebData Tweet -> Element Msg
viewTweet window tweet =
    case tweet of
        Success t ->
            row
                [ paddingEach { top = 0, bottom = windowRatio window 30, left = windowRatio window 30, right = windowRatio window 30 }, spacing (windowRatio window 40), width fill, alignBottom ]
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
