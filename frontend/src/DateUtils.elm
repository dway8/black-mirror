module DateUtils exposing (dayAndMonth, dayOfWeek, time)

import DateFormat as DF
import DateFormat.Language as DFL exposing (english)
import DateFormat.Relative as DFR
import Json.Decode as D
import Time exposing (Month(..), Posix, Weekday(..), Zone)


frenchDateFormat : DFL.Language
frenchDateFormat =
    { english
        | toMonthName = frenchMonthName
        , toWeekdayName = frenchDayName
    }


frenchDayName : Time.Weekday -> String
frenchDayName d =
    case d of
        Mon ->
            "lundi"

        Tue ->
            "mardi"

        Wed ->
            "mercredi"

        Thu ->
            "jeudi"

        Fri ->
            "vendredi"

        Sat ->
            "samedi"

        Sun ->
            "dimanche"


frenchMonthName : Time.Month -> String
frenchMonthName m =
    case m of
        Jan ->
            "janvier"

        Feb ->
            "février"

        Mar ->
            "mars"

        Apr ->
            "avril"

        May ->
            "mai"

        Jun ->
            "juin"

        Jul ->
            "juillet"

        Aug ->
            "août"

        Sep ->
            "septembre"

        Oct ->
            "octobre"

        Nov ->
            "novembre"

        Dec ->
            "décembre"


dayAndMonth : Zone -> Posix -> String
dayAndMonth zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.dayOfMonthNumber
        , DF.text " "
        , DF.monthNameFull
        ]
        zone
        date


dayOfWeek : Zone -> Posix -> String
dayOfWeek zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.dayOfWeekNameFull ]
        zone
        date


time : Zone -> Posix -> String
time zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.hourMilitaryNumber
        , DF.text ":"
        , DF.minuteFixed
        ]
        zone
        date
