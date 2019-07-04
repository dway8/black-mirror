module View exposing (view)

import Browser exposing (Document)
import DateUtils
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import FormatNumber as FN
import FormatNumber.Locales exposing (Locale, frenchLocale)
import Html exposing (Html)
import Html.Attributes as HA
import Model exposing (Model, Msg, MybData, Tweet, Weather, Window)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import Style exposing (..)
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
                        , url = "https://fonts.googleapis.com/css?family=Roboto:100,200,200italic,300,300italic,400,400italic,600,700,800"
                        }
                    ]
                , height fill
                , width fill
                , clipX
                , clipY
                , Background.color blackColor
                , Font.color whiteColor
                ]
            <|
                column
                    [ spacingXY 0
                        (if Utils.isBigPortrait model.window then
                            200

                         else
                            30
                        )
                    ]
                    (viewHeader model
                        :: (case model.mybData of
                                Success data ->
                                    [ viewCountsMybData data
                                    , viewMoneyMybData data model.window
                                    ]

                                _ ->
                                    [ text "Chargement..." ]
                           )
                        ++ [ viewTweet model.lastTweet
                           ]
                    )
    }


viewHeader : Model -> Element Msg
viewHeader model =
    row
        [ width fill, spaceEvenly ]
        [ column
            [ alignLeft, spacing 80 ]
            [ viewDate model.zone model.now
            , viewSaint model.saint
            ]
        , column
            [ alignRight ]
            [ viewTime model.zone model.now
            , row
                [ centerY ]
                [ el [ Font.bold ] <| text (Round.round 1 model.weather.currently.temperature ++ "°")
                , viewWeatherIcon model.weather.currently.icon
                ]
            ]
        ]


viewDate : Zone -> Posix -> Element Msg
viewDate zone now =
    column
        []
        [ el [ Font.bold ] <| text (Utils.ucfirst (DateUtils.dayOfWeek zone now))
        , el [ Font.light ] <| text <| DateUtils.dayAndMonth zone now
        ]


viewSaint : String -> Element Msg
viewSaint saint =
    row
        [ spacing 30, Font.bold ]
        [ el [] <| html <| Utils.icon "zmdi zmdi-chevron-right zmdi-hc-lg"
        , el [] <| text saint
        ]


viewTime : Zone -> Posix -> Element Msg
viewTime zone now =
    el [ Font.light ] <| text <| DateUtils.time zone now


viewWeatherIcon : String -> Element Msg
viewWeatherIcon icon =
    image [ paddingEach { left = 5, right = 0, top = 0, bottom = 0 } ] { src = getSvgIcon icon, description = "" }


viewCountsMybData : MybData -> Element Msg
viewCountsMybData data =
    row
        []
        [ el [ width fill, centerX, centerY ] <|
            column
                [ spacing 50 ]
                [ viewUsers data
                , viewOrders data
                ]
        , el [ Border.widthEach { left = 1, top = 0, bottom = 0, right = 0 }, Border.solid, width fill, centerX, centerY ] <|
            column
                [ spacing 50, paddingEach { left = 55, top = 0, bottom = 0, right = 0 } ]
                [ viewProdEvents data
                , viewAds data
                ]
        ]


viewProdEvents : MybData -> Element Msg
viewProdEvents data =
    row
        [ spacing 30, centerY, width fill ]
        [ el [ width <| fillPortion 1, Font.size 50, Font.bold ] <| el [ alignRight ] <| text (String.fromInt data.prodEvents)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ Font.size 40, Font.bold ] <|
                    (data.totalEvents
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
                , el [ Font.light ] <| text "Prod"
                ]
        ]


viewAds : MybData -> Element Msg
viewAds data =
    row
        [ spacing 30, centerY, width fill ]
        [ el [ width <| fillPortion 1, Font.size 50, Font.bold ] <| el [ alignRight ] <| text ("+" ++ String.fromInt data.todayAds)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ Font.size 40, Font.bold ] <|
                    (data.ads
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
                , el [ Font.light ] <| text "Annonces"
                ]
        ]


viewMoneyMybData : MybData -> Window -> Element Msg
viewMoneyMybData data window =
    el [ centerX, centerY ] <|
        row
            [ spacing
                (if Utils.isBigPortrait window then
                    100

                 else
                    40
                )
            ]
            [ el [ Font.size 40 ] <| html <| Utils.icon "zmdi zmdi-shopping-cart zmdi-hc-4x"
            , el [] <|
                column
                    [ spacing 15 ]
                    [ el [ Font.size 50, Font.bold ] <|
                        (data.va
                            |> toFloat
                            |> (\i -> i / 100)
                            |> FN.format { frenchLocale | decimals = 0 }
                            |> (\i -> i ++ " €")
                            |> text
                        )
                    , el [] <|
                        row
                            [ spacing 40, centerY ]
                            [ el [ Font.size 40 ] <| html <| Utils.icon "zmdi zmdi-shopping-basket zmdi-hc-lg"
                            , el [ Font.size 45, Font.light ] <|
                                (data.avgCart
                                    |> String.fromInt
                                    |> (\a -> (++) a " €")
                                    |> text
                                )
                            ]
                    ]
            ]


viewUsers : MybData -> Element Msg
viewUsers data =
    row
        [ spacing 30, centerY, width fill ]
        [ el [ width <| fillPortion 1, Font.size 50, Font.bold ] <| el [ alignRight ] <| text ("+" ++ String.fromInt data.todayUsers)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ Font.size 40, Font.bold ] <|
                    (data.countUsers
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
                , el [ Font.light ] <| text "Inscrits"
                ]
        ]


viewOrders : MybData -> Element Msg
viewOrders data =
    row
        [ spacing 30, centerY, width fill ]
        [ el [ width <| fillPortion 1, Font.size 50, Font.bold ] <| el [ alignRight ] <| text ("+" ++ String.fromInt data.todayOrders)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ Font.size 40, Font.bold ] <|
                    (data.countOrders
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
                , el [ Font.light ] <| text "Commandes"
                ]
        ]


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
                        el [] <| html <| Utils.icon "zmdi zmdi-twitter zmdi-hc-5x"
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
    "img/" ++ path ++ ".svg"
