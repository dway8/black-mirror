module Public.Model exposing (ImageSize, Media, Model, Msg(..), MybData, Tweet, Weather, Window, fetchLastTweet, fetchMybData, fetchWeather, getTimeNow)

import Http
import Json.Decode as D
import Json.Decode.Pipeline as P
import RemoteData exposing (RemoteData(..), WebData)
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
    }


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


type alias MybData =
    { todayUsers : Int
    , totalUsers : Int
    , todayOrders : Int
    , totalOrders : Int
    , todayExhibitors : Int
    , totalExhibitors : Int
    , todayClients : Int
    , totalClients : Int
    , todayProdOccurrences : Int
    , totalProdOccurrences : Int
    , todayOpenOccurrences : Int
    , totalOpenOccurrences : Int
    , avgCart : Int
    , va : Int
    }



-- MESSAGES


type Msg
    = NoOp
    | FetchMybData
    | UpdateTime ( Posix, Zone )
    | FetchMybDataResponse (WebData MybData)
    | FetchWeather
    | FetchWeatherResponse (WebData Weather)
    | FetchLastTweet
    | FetchLastTweetResponse (WebData Tweet)
    | UpdateSaint Posix
    | InitSaint ( Posix, Zone )


getTimeNow : Cmd Msg
getTimeNow =
    Task.map2 (\time zone -> ( time, zone )) Time.now Time.here
        |> Task.perform UpdateTime


fetchWeather : Cmd Msg
fetchWeather =
    Http.get
        { url = "/api/forecast/45.7701213,4.829064300000027?lang=fr&units=si&exclude=minutely,alerts,flags"
        , expect =
            Http.expectJson (RemoteData.fromResult >> FetchWeatherResponse) weatherDecoder
        }


fetchLastTweet : Cmd Msg
fetchLastTweet =
    Http.get
        { url = "/api/last_tweet"
        , expect =
            Http.expectJson (RemoteData.fromResult >> FetchLastTweetResponse) tweetDecoder
        }


fetchMybData : Cmd Msg
fetchMybData =
    Http.get
        { url = "/api/myb_data"
        , expect = Http.expectJson (RemoteData.fromResult >> FetchMybDataResponse) <| mybDataDecoder
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


mybDataDecoder : D.Decoder MybData
mybDataDecoder =
    D.succeed MybData
        |> P.required "todayUsers" D.int
        |> P.required "totalUsers" D.int
        |> P.required "todayOrders" D.int
        |> P.required "totalOrders" D.int
        |> P.required "todayExhibitors" D.int
        |> P.required "totalExhibitors" D.int
        |> P.required "todayClients" D.int
        |> P.required "totalClients" D.int
        |> P.required "todayProdOccurrences" D.int
        |> P.required "totalProdOccurrences" D.int
        |> P.required "todayOpenOccurrences" D.int
        |> P.required "totalOpenOccurrences" D.int
        |> P.required "avgCart" D.int
        |> P.required "va" D.int
