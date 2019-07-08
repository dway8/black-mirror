module Public.MybData exposing (MybData, mybDataDecoder)

import Json.Decode as D
import Json.Decode.Pipeline as P


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
