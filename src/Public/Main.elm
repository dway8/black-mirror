module Public.Main exposing (main)

import Browser
import Public.Ephemeris as Ephemeris
import Public.Model exposing (Model, Msg(..), Weather, Window, fetchLastTweet, fetchMessagesCmd, fetchMybData, fetchWeather, getTimeNow)
import Public.View as View
import RemoteData exposing (RemoteData(..))
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
        [ Time.every (10 * 1000) <| always FetchMybData
        , Time.every (60 * 1000) (\time -> UpdateTime ( time, model.zone ))
        , Time.every (15 * 60 * 1000) <| always FetchWeather
        , Time.every (15 * 60 * 1000) <| always FetchLastTweet
        , Time.every (60 * 60 * 1000) UpdateSaint
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
