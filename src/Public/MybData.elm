module Public.MybData exposing (MybData, MybOpening, mybDataDecoder)

import DateUtils
import Json.Decode as D
import Json.Decode.Pipeline as P
import Time exposing (Posix)


type alias MybData =
    { todayUsers : Int
    , yearUsers : Int
    , totalUsers : Int
    , todayOrders : Int
    , yearOrders : Int
    , totalOrders : Int
    , todayExhibitors : Int
    , yearExhibitors : Int
    , totalExhibitors : Int
    , todayClients : Int
    , yearClients : Int
    , totalClients : Int
    , todayProdOccurrences : Int
    , yearProdOccurrences : Int
    , totalProdOccurrences : Int
    , todayOpenOccurrences : Int
    , totalOpenOccurrences : Int
    , todayVA : Int
    , yearVA : Int
    , totalVA : Int
    , avgCart : Int
    , openings : List MybOpening
    }


type alias MybOpening =
    { name : String
    , openingDate : Posix
    }


mybDataDecoder : D.Decoder MybData
mybDataDecoder =
    D.succeed MybData
        |> P.required "todayUsers" D.int
        |> P.required "yearUsers" D.int
        |> P.required "totalUsers" D.int
        |> P.required "todayOrders" D.int
        |> P.required "yearOrders" D.int
        |> P.required "totalOrders" D.int
        |> P.required "todayExhibitors" D.int
        |> P.required "yearExhibitors" D.int
        |> P.required "totalExhibitors" D.int
        |> P.required "todayClients" D.int
        |> P.required "yearClients" D.int
        |> P.required "totalClients" D.int
        |> P.required "todayProdOccurrences" D.int
        |> P.required "yearProdOccurrences" D.int
        |> P.required "totalProdOccurrences" D.int
        |> P.required "todayOpenOccurrences" D.int
        |> P.required "totalOpenOccurrences" D.int
        |> P.required "todayVA" D.int
        |> P.required "yearVA" D.int
        |> P.required "totalVA" D.int
        |> P.required "avgCart" D.int
        |> P.required "openings" (D.list mybOpeningDecoder)


mybOpeningDecoder : D.Decoder MybOpening
mybOpeningDecoder =
    D.succeed MybOpening
        |> P.required "name" D.string
        |> P.required "openingDate" DateUtils.dateDecoder
