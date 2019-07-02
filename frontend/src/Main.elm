module Main exposing (main)

import Browser
import Element exposing (..)
import Element.Font as Font
import Model exposing (CurrentWeather, Model, Msg(..), Weather, Window, fetchLastTweet, fetchMybData, fetchWeather)
import RemoteData exposing (RemoteData(..))
import Task
import Time exposing (Posix)
import View


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
      , weather = initialWeather
      , lastTweet = Nothing
      , window = flags.viewport
      , saint = ""
      }
    , Cmd.batch [ Task.perform UpdateDateTime Time.now, fetchWeather, fetchLastTweet, Task.perform InitSaint Time.now ]
    )


initialWeather : Weather
initialWeather =
    { currently = initialCurrentWeather }


initialCurrentWeather : CurrentWeather
initialCurrentWeather =
    { icon = ""
    , summary = ""
    , temperature = 0
    }


type alias Flags =
    { now : Int
    , viewport : Window
    }


update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every (10 * 1000) <| always FetchMybData
        , Time.every (60 * 1000) UpdateDateTime
        , Time.every (15 * 60 * 1000) <| always FetchWeather
        , Time.every (15 * 60 * 1000) <| always FetchLastTweet
        , Time.every (60 * 60 * 1000) UpdateSaint
        ]
