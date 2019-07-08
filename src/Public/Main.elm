module Public.Main exposing (main)

import Browser
import Public.Ephemeris as Ephemeris
import Public.Model exposing (Model, Msg(..), Weather, Window, fetchLastTweet, fetchMessagesCmd, fetchMybData, fetchWeather, getTimeNow)
import Public.Ports as Ports exposing (InfoForElm(..), InfoForOutside(..))
import Public.View as View
import RemoteData as RD exposing (RemoteData(..))
import Task
import Time exposing (Posix, Zone)


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = View.view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { mybData = NotAsked
      , now = Time.millisToPosix flags.now
      , zone = Time.utc
      , weather = initialWeather
      , lastTweet = NotAsked
      , window = flags.viewport
      , saint = ""
      , messages = NotAsked
      , messageCursor = 0
      }
    , Cmd.batch
        [ fetchMybData
        , getTimeNow
        , fetchWeather
        , fetchLastTweet
        , Task.map2 (\time zone -> ( time, zone )) Time.now Time.here
            |> Task.perform InitSaint
        , fetchMessagesCmd
        ]
    )


initialWeather : Weather
initialWeather =
    { icon = ""
    , summary = ""
    , temperature = 0
    }


type alias Flags =
    { now : Int
    , viewport : Window
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every (60 * 1000) (\time -> UpdateTime ( time, model.zone ))
        , Time.every (15 * 60 * 1000) <| always FetchWeather
        , Time.every (15 * 60 * 1000) <| always FetchLastTweet
        , Time.every (6 * 1000) <| always AnimateMessagesAndTweet
        , Ports.getInfoFromOutside InfoFromOutside (always NoOp)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchWeatherResponse response ->
            case response of
                Success w ->
                    ( { model | weather = w }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        FetchLastTweetResponse response ->
            ( { model | lastTweet = response }, Cmd.none )

        FetchMybDataResponse response ->
            ( { model | mybData = response }, Cmd.none )

        InitSaint ( now, zone ) ->
            let
                newSaint =
                    getNewSaint zone now |> Maybe.withDefault model.saint
            in
            ( { model | saint = newSaint }
            , Cmd.none
            )

        FetchMessagesResponse response ->
            ( { model | messages = response }, Cmd.none )

        AnimateMessagesAndTweet ->
            case model.messages of
                Success messages ->
                    if messages == [] then
                        ( model, Cmd.none )

                    else
                        let
                            messagesLength =
                                model.messages
                                    |> RD.withDefault []
                                    |> List.length

                            newMessageCursor =
                                if model.messageCursor == messagesLength then
                                    0

                                else
                                    model.messageCursor + 1
                        in
                        ( { model | messageCursor = newMessageCursor }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        InfoFromOutside info ->
            case info of
                ReceivedMYBEvent mybData event ->
                    ( { model | mybData = Success mybData }
                    , Ports.sendInfoOutside <| PlaySound event
                    )

        _ ->
            ( model, Cmd.none )


getNewSaint : Zone -> Posix -> Maybe String
getNewSaint zone now =
    Ephemeris.getDaySaint zone now
        |> Maybe.map
            (\( name, prefix ) ->
                if prefix == "" then
                    name

                else
                    prefix ++ " " ++ name
            )
