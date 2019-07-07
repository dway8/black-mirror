module Style exposing (blackColor, errorColor, greenColor, mediumGreyColor, orangeColor, whiteColor, windowRatio)

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


errorColor : Color
errorColor =
    rgb255 255 0 0


mediumGreyColor : Color
mediumGreyColor =
    rgb255 178 178 178


windowRatio : Window -> Float -> Int
windowRatio window size =
    size
        * 0.001
        * toFloat window.height
        |> round
