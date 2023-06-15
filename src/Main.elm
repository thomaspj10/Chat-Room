module Main exposing (main)

import Browser
import Html exposing (Html, b, button, div, input, p, text)
import Html.Attributes exposing (class, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Platform.Cmd as Cmd
import Time


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type Page
    = Author
    | Chat


type alias Model =
    { page : Page
    , messages : List Message
    , currentMessage : String
    , author : String
    }


fetchMessages : Cmd Msg
fetchMessages =
    Http.get
        { url = "/messages"
        , expect = Http.expectJson FetchedServerMessages messagesDecoder
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { page = Author, messages = [], currentMessage = "", author = "" }, Cmd.none )


type alias Message =
    { message : String
    , author : String
    }


messagesDecoder : JD.Decoder (List Message)
messagesDecoder =
    JD.list
        (JD.map2 Message
            (JD.field "message" JD.string)
            (JD.field "author" JD.string)
        )


sendMessageEncoder : String -> String -> JE.Value
sendMessageEncoder message author =
    JE.object
        [ ( "message", JE.string message )
        , ( "author", JE.string author )
        ]


type Msg
    = FetchedServerMessages (Result Http.Error (List Message))
    | FetchServerMessages Time.Posix
    | TypeMessage String
    | SendMessage
    | SendMessageSuccess (Result Http.Error ())
    | TypeAuthor String
    | SubmitAuthor


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchedServerMessages result ->
            case result of
                Ok messages ->
                    ( { model | messages = messages }, Cmd.none )

                Err _ ->
                    ( { model | messages = [] }, Cmd.none )

        FetchServerMessages _ ->
            ( model, fetchMessages )

        TypeMessage message ->
            ( { model | currentMessage = message }, Cmd.none )

        SendMessage ->
            ( { model | currentMessage = "" }, sendMessage model.currentMessage model.author )

        SendMessageSuccess _ ->
            ( model, fetchMessages )

        TypeAuthor author ->
            ( { model | author = author }, Cmd.none )

        SubmitAuthor ->
            ( { model | page = Chat }, fetchMessages )


sendMessage : String -> String -> Cmd Msg
sendMessage message author =
    Http.post
        { url = "/send"
        , body = Http.jsonBody <| sendMessageEncoder message author
        , expect = Http.expectWhatever SendMessageSuccess
        }


subscriptions model =
    Time.every 1000 FetchServerMessages


view : Model -> Html Msg
view model =
    case model.page of
        Chat ->
            renderChat model

        Author ->
            div [ class "container" ]
                [ input [ class "mr-10", placeholder "Your name", onInput TypeAuthor ] []
                , button [ onClick SubmitAuthor ] [ text "Join chat" ]
                ]


renderChat : Model -> Html Msg
renderChat model =
    div [ class "container" ]
        [ div [] (List.map renderMessage model.messages)
        , input [ class "ml-2 mr-10", placeholder "Message", onInput TypeMessage, value model.currentMessage ] []
        , button [ onClick SendMessage ] [ text "Send" ]
        ]


renderMessage : Message -> Html Msg
renderMessage message =
    div [ class "container mb-2 p-2" ]
        [ b [] [ text message.author ]
        , p [] [ text message.message ]
        ]
