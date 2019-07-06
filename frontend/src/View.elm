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
                    [ width fill
                    , height fill
                    , spaceEvenly
                    ]
                    (viewHeader model
                        :: (case model.mybData of
                                Success data ->
                                    [ viewCountsMybData model.window data
                                    , viewMoneyMybData model.window data
                                    ]

                                _ ->
                                    [ text "Chargement..." ]
                           )
                        ++ [ viewTweet model.lastTweet
                           ]
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
            [ viewSaint saint
            , row
                [ centerY, Font.size (windowRatio window 60), alignRight ]
                [ el [ Font.bold ] <| text (Round.round 1 weather.currently.temperature ++ "°")
                , viewWeatherIcon weather.currently.icon
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


viewSaint : String -> Element Msg
viewSaint saint =
    row
        [ spacing 30, Font.bold ]
        [ el [] <| html <| Utils.icon "zmdi zmdi-chevron-right zmdi-hc-lg"
        , el [] <| text saint
        ]


viewWeatherIcon : String -> Element Msg
viewWeatherIcon icon =
    image [ paddingEach { left = 5, right = 0, top = 0, bottom = 0 } ] { src = getSvgIcon icon, description = "" }


viewCountsMybData : Window -> MybData -> Element Msg
viewCountsMybData window data =
    row
        [ width fill, spaceEvenly ]
        [ column
            [ spacing 50, alignLeft, centerY ]
            [ viewUsers window data
            , viewOrders window data
            ]
        , el [ Border.widthEach { left = 1, top = 0, bottom = 0, right = 0 }, Border.solid, centerX, centerY, height fill, paddingXY (windowRatio window 30) 0 ] <| none
        , viewTotalProdEvents window data
        ]


viewTotalProdEvents : Window -> MybData -> Element Msg
viewTotalProdEvents window data =
    column
        []
        [ el [ Font.size (windowRatio window 34), Font.bold ] <|
            (data.totalProdEvents
                |> toFloat
                |> FN.format { frenchLocale | decimals = 0 }
                |> text
            )
        , el [ Font.light, Font.size (windowRatio window 26) ] <| text "Prod"
        ]


viewMoneyMybData : Window -> MybData -> Element Msg
viewMoneyMybData window data =
    row
        [ spacing (windowRatio window 40)
        , centerX
        ]
        [ el [ Font.size (windowRatio window 34) ] <| html <| Utils.icon "zmdi zmdi-shopping-cart zmdi-hc-4x"
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
                [ el [ Font.size (windowRatio window 34) ] <| html <| Utils.icon "zmdi zmdi-shopping-basket zmdi-hc-lg"
                , el [ Font.size (windowRatio window 40), Font.light ] <|
                    (data.avgCart
                        |> String.fromInt
                        |> (\a -> (++) a " €")
                        |> text
                    )
                ]
            ]
        ]


viewUsers : Window -> MybData -> Element Msg
viewUsers window data =
    row
        [ spacing 30, centerY, width fill ]
        [ el [ width <| fillPortion 1, Font.size (windowRatio window 80), Font.bold ] <| el [ alignRight ] <| text ("+" ++ String.fromInt data.todayUsers)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ Font.size (windowRatio window 34), Font.bold ] <|
                    (data.totalUsers
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
                , el [ Font.light, Font.size (windowRatio window 26) ] <| text "Inscrits"
                ]
        ]


viewOrders : Window -> MybData -> Element Msg
viewOrders window data =
    row
        [ spacing 30, centerY, width fill ]
        [ el [ width <| fillPortion 1, Font.size (windowRatio window 80), Font.bold ] <| el [ alignRight ] <| text ("+" ++ String.fromInt data.todayOrders)
        , el [ width <| fillPortion 2 ] <|
            column
                []
                [ el [ Font.size (windowRatio window 34), Font.bold ] <|
                    (data.totalOrders
                        |> toFloat
                        |> FN.format { frenchLocale | decimals = 0 }
                        |> text
                    )
                , el [ Font.light, Font.size (windowRatio window 26) ] <| text "Commandes"
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
