module Utils exposing (getAt, icon, isBigPortrait, styledIcon, ucfirst)

import Char
import Html exposing (Html, i)
import Html.Attributes exposing (..)
import Public.Model exposing (Window)


ucfirst : String -> String
ucfirst string =
    case String.uncons string of
        Just ( firstLetter, rest ) ->
            String.cons (Char.toUpper firstLetter) rest

        Nothing ->
            ""


icon : String -> Html a
icon str =
    styledIcon [] str


styledIcon : List ( String, String ) -> String -> Html a
styledIcon styles str =
    i
        ([ class str
         , attribute "aria-hidden" "true"
         ]
            ++ (styles |> List.map (\tuple -> style (Tuple.first tuple) (Tuple.second tuple)))
        )
        []


isBigPortrait : Window -> Bool
isBigPortrait window =
    window.height > 900


getAt : List a -> Int -> Maybe a
getAt xs idx =
    List.head <| List.drop idx xs
