module Utils exposing (icon, isBigPortrait, isDesktop, ucfirst, viewIf)

import Char
import Element exposing (Element, html, none)
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


viewIf : Bool -> Element msg -> Element msg
viewIf b view =
    if b then
        view

    else
        none
