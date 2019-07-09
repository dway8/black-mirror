module Public.Main exposing (main)

import Browser
import DateUtils
import Public.Model exposing (Model, Msg(..), Weather, Window, fetchLastTweet, fetchMessagesCmd, fetchMybData, fetchWeather, initSaint, initTime)
import Public.Ports as Ports exposing (InfoForElm(..), InfoForOutside(..))
import Public.View as View
import RemoteData as RD exposing (RemoteData(..))
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
    , initTime
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
subscriptions { zone, now } =
    Sub.batch
        ([ Time.every (60 * 1000) (\time -> UpdateTime time)
         , Time.every (60 * 60 * 1000)
            (\time ->
                if Time.toHour zone time == 0 then
                    UpdateSaint

                else
                    NoOp
            )
         , Time.every (60 * 60 * 1000)
            (\time ->
                if Time.toHour zone time == 8 then
                    MorningFetchMybData

                else
                    NoOp
            )
         ]
            ++ (if DateUtils.isNightTime zone now then
                    []

                else
                    [ Time.every (15 * 60 * 1000) <| always FetchWeather
                    , Time.every (15 * 60 * 1000) <| always FetchLastTweet
                    , Time.every (6 * 1000) <| always AnimateMessagesAndTweet
                    , Ports.getInfoFromOutside InfoFromOutside (always NoOp)
                    ]
               )
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

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

        InitTime ( now, zone ) ->
            let
                cmds =
                    if DateUtils.isNightTime zone now then
                        Cmd.none

                    else
                        Cmd.batch [ fetchMybData, fetchWeather, fetchLastTweet, fetchMessagesCmd ]
            in
            ( { model | now = now, zone = zone }, cmds )
                |> initSaint

        UpdateTime now ->
            ( { model | now = now }, Cmd.none )

        UpdateSaint ->
            ( model, Cmd.none )
                |> initSaint

        MorningFetchMybData ->
            ( model, fetchMybData )

        FetchWeather ->
            ( model, Cmd.none )

        FetchLastTweet ->
            ( model, Cmd.none )
