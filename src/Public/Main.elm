module Public.Main exposing (main)

import Browser
import DateUtils
import Editable
import List.Extra as LE
import Model exposing (Event(..), Sound)
import Ports exposing (InfoForElm(..), InfoForOutside(..))
import Public.Model exposing (Model, Msg(..), Slide(..), Weather, Window, fetchLastTweetCmd, fetchMessagesCmd, fetchMybDataCmd, fetchSoundsCmd, fetchWeatherCmd, initSaint, initTime)
import Public.View as View
import RemoteData as RD exposing (RemoteData(..), WebData)
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
      , sounds = NotAsked
      , currentSlide = MoneySlide
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
                    , Time.every (5 * 1000) <| always ChangeSlide
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

        ChangeSlide ->
            let
                messageSlides =
                    model.messages
                        |> RD.map List.length
                        |> RD.withDefault 0
                        |> (\count -> List.range 0 (count - 1))
                        |> List.map MessageSlide

                slides =
                    MoneySlide :: messageSlides ++ [ TweetSlide, OpeningsSlide ]

                currentIndex =
                    LE.elemIndex model.currentSlide slides
                        |> Maybe.withDefault 0

                newSlide =
                    LE.getAt (currentIndex + 1) slides
                        |> Maybe.withDefault MoneySlide
            in
            ( { model | currentSlide = newSlide }, Cmd.none )

        InfoFromOutside info ->
            case info of
                ReceivedMYBEvent mybData event ->
                    let
                        cmd =
                            findSoundForEvent event model.sounds
                                |> Maybe.map (PlaySound >> Ports.sendInfoOutside)
                                |> Maybe.withDefault Cmd.none
                    in
                    ( { model | mybData = Success mybData }
                    , cmd
                    )

                ReceivedMessages messages isNew ->
                    let
                        cmd =
                            if isNew then
                                findSoundForEvent NewMessage model.sounds
                                    |> Maybe.map (PlaySound >> Ports.sendInfoOutside)
                                    |> Maybe.withDefault Cmd.none

                            else
                                Cmd.none
                    in
                    ( { model | messages = Success messages }, cmd )

                ReceivedSounds sounds ->
                    ( { model | sounds = Success sounds }, Cmd.none )

        InitTime ( now, zone ) ->
            let
                cmds =
                    if DateUtils.isNightTime zone now then
                        Cmd.none

                    else
                        Cmd.batch
                            [ fetchMybDataCmd
                            , fetchWeatherCmd
                            , fetchLastTweetCmd
                            , fetchMessagesCmd
                            , fetchSoundsCmd
                            ]
            in
            ( { model | now = now, zone = zone }, cmds )
                |> initSaint

        UpdateTime now ->
            ( { model | now = now }, Cmd.none )

        UpdateSaint ->
            ( model, Cmd.none )
                |> initSaint

        MorningFetchMybData ->
            ( model, fetchMybDataCmd )

        FetchWeather ->
            ( model, fetchWeatherCmd )

        FetchLastTweet ->
            ( model, fetchLastTweetCmd )

        FetchSoundsResponse response ->
            ( { model | sounds = response }, Cmd.none )


findSoundForEvent : Event -> WebData (List Sound) -> Maybe String
findSoundForEvent event rdSounds =
    case rdSounds of
        Success sounds ->
            sounds
                |> List.filter (\sound -> sound.event == event)
                |> List.head
                |> Maybe.andThen (.url >> Editable.value)

        _ ->
            Nothing
