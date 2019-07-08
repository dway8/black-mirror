module Utils exposing (getAt, icon, isBigPortrait, isDesktop, ucfirst)

import Char
import Element exposing (Element, html)
import Html
import Html.Attributes as HA
import Public.Model exposing (Window)


ucfirst : String -> String
ucfirst string =
    case String.uncons string of
        Just ( firstLetter, rest ) ->
            String.cons (Char.toUpper firstLetter) rest

        Nothing ->
            ""


icon : String -> Element msg
icon ico =
    html <| Html.i [ HA.class ("zmdi zmdi-" ++ ico) ] []


isBigPortrait : Window -> Bool
isBigPortrait window =
    window.height > 900


isDesktop : Window -> Bool
isDesktop window =
    window.width > window.height


getAt : List a -> Int -> Maybe a
getAt xs idx =
    List.head <| List.drop idx xs
