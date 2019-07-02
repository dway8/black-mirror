module View exposing (view)

import Browser exposing (Document)
import Element exposing (..)
import Element.Font as Font
import FormatNumber as FN
import FormatNumber.Locales exposing (Locale, frenchLocale)
import Html exposing (Html)
import Model exposing (Model, Msg, MybData, Tweet, Weather)
import RemoteData exposing (RemoteData(..))
import Round
import Time exposing (Posix)
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
                ]
            <|
                case model.mybData of
                    Success data ->
                        column
                            [ spacingXY 0
                                (if Utils.isBigPortrait model.window then
                                    200

                                 else
                                    30
                                )
                            ]
                            [ viewHeader model
                            , viewCountsMybData data
                            , viewMoneyMybData data model.device
                            , viewTweet model.lastTweet
                            ]

                    _ ->
                        text "Chargement..."
    }


viewHeader : Model -> Element Msg
viewHeader model =
    row
        [ width fill, spaceEvenly ]
        [ column
            [ alignLeft, spacing 80 ]
            [ viewDate model.datetime
            , viewSaint model.saint
            ]
        , column
            [ alignRight ]
            [ viewTime model.datetime
            , row
                [ centerY ]
                [ el [ Font.bold ] <| text (Round.round 1 model.weather.currently.temperature ++ "°")
                , viewWeatherIcon model.weather.currently.icon
                ]
            ]
        ]


viewDate : Posix -> Element Msg
viewDate now =
    column
        []
        [ el [ Font.bold ] <| text (ucfirst (Utils.dayOfWeek d))
        , el [ Font.light ] <| text <| Utils.dayAndMonth d
        ]


viewSaint : String -> Element Msg
viewSaint saint =
    row
        [ spacing 30, Font.bold ]
        [ el [] <| html <| Utils.icon "zmdi zmdi-chevron-right zmdi-hc-lg"
        , el [] <| text saint
        ]


viewTime : Posix -> Element Msg
viewTime now =
    el [ Font.light ] <| text <| timeToStringFr now


viewWeatherIcon : String -> Element Msg
viewWeatherIcon icon =
    image WeatherIcon [ paddingLeft 5 ] { src = getSvgIcon icon, caption = "" }


viewCountsMybData : MybData -> Element Msg
viewCountsMybData data =
    row
        []
        [ el [ width <| percent 50, center ] <|
            column
                [ spacing 50 ]
                [ viewUsers data
                , viewOrders data
                ]
        , el Border [ vary Left True, width <| percent 50, center ] <|
            column
                [ spacing 50, paddingLeft 55 ]
                [ viewProdEvents data
                , viewAds data
                ]
        ]


viewProdEvents : MybData -> Element Msg
viewProdEvents data =
    row
        [ spacing 30, centerY, width fill ]
        [ el [ width <| fillPortion 1, vary Largest True, vary Bold True ] <| el [ alignRight ] <| text (toString data.prodEvents)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ vary Large True, vary Bold True ] <|
                    (data.totalEvents
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
                , el [ vary Light True ] <| text "Prod"
                ]
        ]


viewAds : MybData -> Element Msg
viewAds data =
    row
        [ spacing 30, verticalCenter, width fill ]
        [ el [ width <| fillPortion 1, vary Largest True, vary Bold True ] <| el [ alignRight ] <| text ("+" ++ toString data.todayAds)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ vary Large True, vary Bold True ] <|
                    (data.ads
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
                , el [ vary Light True ] <| text "Annonces"
                ]
        ]


viewMoneyMybData : MybData -> Device -> Element Msg
viewMoneyMybData data device =
    el [ center ] <|
        row
            [ spacing
                (if isBigPortrait device then
                    100

                 else
                    40
                )
            ]
            [ el [ vary Large True ] <| html <| icon "zmdi zmdi-shopping-cart zmdi-hc-4x"
            , el [] <|
                column
                    [ spacing 15 ]
                    [ el [ vary Larger True, vary Bold True ] <|
                        (data.va
                            |> toFloat
                            |> (\i -> i / 100)
                            |> FN.format { frenchLocale | decimals = 0 }
                            |> (\i -> i ++ " €")
                            |> text
                        )
                    , el [] <|
                        row
                            [ spacing 40, verticalCenter ]
                            [ el [ vary Large True ] <| html <| icon "zmdi zmdi-shopping-basket zmdi-hc-lg"
                            , el [ vary Larger True, vary Light True ] <|
                                (data.avgCart
                                    |> toString
                                    |> (\a -> (++) a " €")
                                    |> text
                                )
                            ]
                    ]
            ]


viewUsers : MybData -> Element Msg
viewUsers data =
    row
        [ spacing 30, verticalCenter, width fill ]
        [ el [ width <| fillPortion 1, vary Largest True, vary Bold True ] <| el [ alignRight ] <| text ("+" ++ toString data.todayUsers)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ vary Large True, Font.bold ] <|
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
        [ spacing 30, verticalCenter, width fill ]
        [ el [ width <| fillPortion 1, vary Largest True, vary Bold True ] <| el [ alignRight ] <| text ("+" ++ toString data.todayOrders)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ vary Large True, Font.bold ] <|
                    (data.countOrders
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
                , el [ Font.light ] <| text "Commandes"
                ]
        ]


viewTweet : Maybe Tweet -> Element Msg
viewTweet tweet =
    case tweet of
        Nothing ->
            el [] <| text "..."

        Just t ->
            row
                [ spacing 40, centerY, width fill ]
                [ case t.media of
                    photo :: [] ->
                        el [] <|
                            decorativeImage
                                [ inlineStyle [ ( "width", toString (photo.size.width * 0.5) ++ "px" ), ( "height", toString (photo.size.height * 0.5) ++ "px" ) ] ]
                                { src = photo.mediaUrl }

                    _ ->
                        el [] <| html <| icon "zmdi zmdi-twitter zmdi-hc-5x"
                , textLayout [ Font.light ] [ paragraph [] [ text t.text ] ]
                ]


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
