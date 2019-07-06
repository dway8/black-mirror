module Style exposing (blackColor, whiteColor, windowRatio)

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
