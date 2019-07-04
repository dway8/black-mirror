module Style exposing (blackColor, size1, size2, whiteColor, windowRatio)

import Element exposing (..)


blackColor : Color
blackColor =
    rgb255 0 0 0


whiteColor : Color
whiteColor =
    rgb255 255 255 255


windowRatio window size =
    size
        * 0.001
        * toFloat window.height
        |> round


size1 window =
    50
        |> windowRatio window


size2 window =
    34
        |> windowRatio window
