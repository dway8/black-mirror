module Public.Model exposing (ImageSize, Media, Model, Msg(..), Slide(..), Tweet, Weather, Window, fetchLastTweetCmd, fetchMessagesCmd, fetchMybDataCmd, fetchSoundsCmd, fetchWeatherCmd, initSaint, initTime)

import Http
import Json.Decode as D
import Json.Decode.Pipeline as P
import Model exposing (Message, Sound)
import Ports exposing (InfoForElm)
import Public.Ephemeris as Ephemeris
import Public.MybData as MybData exposing (MybData)
import RemoteData as RD exposing (RemoteData(..), WebData)
import Task
import Time exposing (Posix, Zone)


type alias Model =
    { mybData : WebData MybData
    , now : Posix
    , zone : Zone
    , weather : Weather
    , lastTweet : WebData Tweet
    , saint : String
    , window : Window
    , messages : WebData (List Message)
    , sounds : WebData (List Sound)
    , currentSlide : Slide
    }


type Slide
    = MoneySlide
    | MessageSlide Int
    | TweetSlide
    | OpeningsSlide


type alias Window =
    { width : Int
    , height : Int
    }


type alias Weather =
    { icon : String
    , summary : String
    , temperature : Float
    }


type alias Tweet =
    { createdAt : String
    , text : String
    , media : List Media
    }


type alias Media =
    { mediaUrl : String
    , size : ImageSize
    }


type alias ImageSize =
    { width : Float
    , height : Float
    }



-- MESSAGES


type Msg
    = NoOp
    | InitTime ( Posix, Zone )
    | UpdateTime Posix
    | MorningFetchMybData
    | FetchMybDataResponse (WebData MybData)
    | FetchWeather
    | FetchWeatherResponse (WebData Weather)
    | FetchLastTweet
    | FetchLastTweetResponse (WebData Tweet)
    | UpdateSaint
    | FetchMessagesResponse (WebData (List Message))
    | ChangeSlide
    | InfoFromOutside InfoForElm
    | FetchSoundsResponse (WebData (List Sound))


initTime : Cmd Msg
initTime =
    Task.map2 (\time zone -> ( time, zone )) Time.now Time.here
        |> Task.perform InitTime


initSaint : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initSaint =
    Tuple.mapFirst
        (\({ zone, now } as model) ->
            let
                newSaint =
                    getNewSaint zone now |> Maybe.withDefault model.saint
            in
            { model | saint = newSaint }
        )


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


fetchWeatherCmd : Cmd Msg
fetchWeatherCmd =
    Http.get
        { url = "/api/forecast/45.7701213,4.829064300000027?lang=fr&units=si&exclude=minutely,alerts,flags"
        , expect =
            Http.expectJson (RD.fromResult >> FetchWeatherResponse) weatherDecoder
        }


fetchLastTweetCmd : Cmd Msg
fetchLastTweetCmd =
    Http.get
        { url = "/api/last-tweet"
        , expect =
            Http.expectJson (RD.fromResult >> FetchLastTweetResponse) tweetDecoder
        }


fetchMybDataCmd : Cmd Msg
fetchMybDataCmd =
    Http.get
        { url = "/api/myb-data"
        , expect = Http.expectJson (RD.fromResult >> FetchMybDataResponse) <| MybData.mybDataDecoder
        }


weatherDecoder : D.Decoder Weather
weatherDecoder =
    D.succeed Weather
        |> P.requiredAt [ "currently", "icon" ] D.string
        |> P.requiredAt [ "currently", "summary" ] D.string
        |> P.requiredAt [ "currently", "temperature" ] D.float


tweetDecoder : D.Decoder Tweet
tweetDecoder =
    D.succeed Tweet
        |> P.required "created_at" D.string
        |> P.required "full_text" tweetTextDecoder
        |> P.requiredAt [ "entities", "media" ] (D.list mediaDecoder)


tweetTextDecoder : D.Decoder String
tweetTextDecoder =
    D.string
        |> D.andThen
            (\s ->
                let
                    ind =
                        String.indexes "http" s
                in
                case List.head (List.reverse ind) of
                    Just lastIndex ->
                        s
                            |> String.length
                            |> (\length -> length - lastIndex)
                            |> (\a -> String.dropRight a s)
                            |> D.succeed

                    _ ->
                        D.succeed s
            )


mediaDecoder : D.Decoder Media
mediaDecoder =
    D.succeed Media
        |> P.required "media_url_https" D.string
        |> P.requiredAt [ "sizes", "small" ] imageSizeDecoder


imageSizeDecoder : D.Decoder ImageSize
imageSizeDecoder =
    D.succeed ImageSize
        |> P.required "w" D.float
        |> P.required "h" D.float


fetchMessagesCmd : Cmd Msg
fetchMessagesCmd =
    Http.get
        { url = "/api/messages"
        , expect = Http.expectJson (RD.fromResult >> FetchMessagesResponse) Model.messagesDecoder
        }


fetchSoundsCmd : Cmd Msg
fetchSoundsCmd =
    Http.get
        { url = "/api/sounds"
        , expect = Http.expectJson (RD.fromResult >> FetchSoundsResponse) Model.soundsDecoder
        }
