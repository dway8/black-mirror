module Style exposing (blackColor, size0, size1, size2, whiteColor, windowRatio)

import Element exposing (..)
import Model exposing (Window)


blackColor : Color
blackColor =
    rgb255 0 0 0


whiteColor : Color
whiteColor =
    rgb255 255 255 255


windowRatio : Window -> Float -> Int
windowRatio window size =
    size
        * 0.001
        * toFloat window.height
        |> round


size0 : Window -> Int
size0 window =
    90
        |> windowRatio window


size1 : Window -> Int
size1 window =
    50
        |> windowRatio window


size2 : Window -> Int
size2 window =
    34
        |> windowRatio window
