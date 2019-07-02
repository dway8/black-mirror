module DateUtils exposing (dateDecoder, dateTimeToShortString, dateTimeToString, dateToShortSlashedString, dateToShortestSlashedString, dateToSlashedString, dateToString, frenchDateFormat, frenchDayName, frenchMonthName, relativeTimeOptions, sortByDateAsc, sortByDateDesc, timeToString)

import DateFormat as DF
import DateFormat.Language as DFL exposing (english)
import DateFormat.Relative as DFR
import Json.Decode as D
import Time exposing (Month(..), Posix, Weekday(..), Zone)
import ViewUtils


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


dateToString : Zone -> Posix -> String
dateToString zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.dayOfWeekNameFull
        , DF.text " "
        , DF.dayOfMonthNumber

        -- , DF.dayOfMonthSuffix
        , DF.text " "
        , DF.monthNameFull
        , DF.text " "
        , DF.yearNumber
        ]
        zone
        date


dateToShortSlashedString : Zone -> Posix -> String
dateToShortSlashedString zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.dayOfMonthFixed
        , DF.text "/"
        , DF.monthFixed
        , DF.text "/"
        , DF.yearNumberLastTwo
        ]
        zone
        date


dateToShortestSlashedString : Zone -> Posix -> String
dateToShortestSlashedString zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.dayOfMonthFixed
        , DF.text "/"
        , DF.monthFixed
        ]
        zone
        date


dateToSlashedString : Zone -> Posix -> String
dateToSlashedString zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.dayOfMonthFixed
        , DF.text "/"
        , DF.monthFixed
        , DF.text "/"
        , DF.yearNumber
        ]
        zone
        date


dateTimeToString : Zone -> Posix -> String
dateTimeToString zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.dayOfWeekNameFull
        , DF.text " "
        , DF.dayOfMonthNumber

        -- , DF.dayOfMonthSuffix
        , DF.text " "
        , DF.monthNameFull
        , DF.text " "
        , DF.yearNumber
        , DF.text " à "
        , DF.hourMilitaryNumber
        , DF.text "h"
        , DF.minuteFixed
        ]
        zone
        date


dateTimeToShortString : Zone -> Posix -> String
dateTimeToShortString zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.dayOfMonthFixed
        , DF.text "/"
        , DF.monthFixed
        , DF.text "/"
        , DF.yearNumberLastTwo
        , DF.text " à "
        , DF.hourMilitaryNumber
        , DF.text "h"
        , DF.minuteFixed
        ]
        zone
        date


timeToString : Zone -> Posix -> String
timeToString zone date =
    DF.formatWithLanguage frenchDateFormat
        [ DF.hourMilitaryNumber
        , DF.text "h"
        , DF.minuteFixed
        ]
        zone
        date
