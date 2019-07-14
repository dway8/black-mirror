module Style exposing (blackColor, greenColor, mediumGreyColor, orangeColor, redColor, whiteColor, windowRatio)

import Element exposing (Color, rgb255)
import Public.Model exposing (Window)


blackColor : Color
blackColor =
    rgb255 0 0 0


whiteColor : Color
whiteColor =
    rgb255 255 255 255


orangeColor : Color
orangeColor =
    rgb255 255 157 0


greenColor : Color
greenColor =
    rgb255 100 227 199


redColor : Color
redColor =
    rgb255 247 75 79


mediumGreyColor : Color
mediumGreyColor =
    rgb255 178 178 178


windowRatio : Window -> Float -> Int
windowRatio window size =
    size
        * 0.001
        * toFloat window.height
        |> round
