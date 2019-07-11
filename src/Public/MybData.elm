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
    , todayVA : Int
    , totalVA : Int
    , avgCart : Int
    }


mybDataDecoder : D.Decoder MybData
mybDataDecoder =
    D.succeed MybData
        |> P.required "today_users" D.int
        |> P.required "total_users" D.int
        |> P.required "today_orders" D.int
        |> P.required "total_orders" D.int
        |> P.required "today_exhibitors" D.int
        |> P.required "total_exhibitors" D.int
        |> P.required "today_clients" D.int
        |> P.required "total_clients" D.int
        |> P.required "today_prod_occurrences" D.int
        |> P.required "total_prod_occurrences" D.int
        |> P.required "today_open_occurrences" D.int
        |> P.required "total_open_occurrences" D.int
        |> P.required "today_va" D.int
        |> P.required "total_va" D.int
        |> P.required "avg_cart" D.int
