module Admin.Main exposing (main)

import Browser exposing (Document)
import Element exposing (..)
import Element.Font as Font
import RemoteData exposing (RemoteData(..))


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Flags =
    {}


type alias Model =
    {}


type Msg
    = NoOp


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( {}
    , Cmd.none
    )


view : Model -> Document Msg
view model =
    { title = "Admin - Black mirror"
    , body =
        List.singleton <|
            layout
                [ Font.family
                    [ Font.external
                        { name = "Roboto"
                        , url = "https://fonts.googleapis.com/css?family=Roboto:100,200,200italic,300,300italic,400,400italic,600,700,800"
                        }
                    ]
                , height fill
                , width fill
                , clipX
                , clipY
                ]
            <|
                text "hi!"
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )
