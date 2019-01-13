module Style.Widgets.MenuItem exposing (MenuItemState(..), menuItem)

import Color exposing (toElementColor)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Framework.Color


type MenuItemState
    = Active
    | Inactive


{-| Generate an Input.button element suitable use as a menu item

    menuItem Active "Add Provider" Nothing

-}
menuItem : MenuItemState -> String -> Maybe msg -> Element msg
menuItem state itemLabel onPress =
    let
        ( fontWeight, fontColor, backgroundColor ) =
            case state of
                Active ->
                    ( Font.bold
                    , Framework.Color.white
                    , Framework.Color.grey_darker
                    )

                Inactive ->
                    ( Font.regular
                    , Framework.Color.grey_light
                    , Framework.Color.black_ter
                    )

        menuItemButtonAttrs =
            [ Element.width Element.fill
            , Border.color (toElementColor <| Framework.Color.black)
            , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
            , Element.spacing 15
            , Element.paddingXY 15 24
            , Background.color (toElementColor <| backgroundColor)
            , Font.color (toElementColor <| fontColor)
            ]

        menuItemElementAttrs =
            let
                borderProps =
                    case state of
                        Active ->
                            [ Border.color (toElementColor <| Framework.Color.primary)
                            , Border.widthEach { bottom = 0, left = 3, right = 0, top = 0 }
                            ]

                        Inactive ->
                            []

                otherProps =
                    [ Element.width Element.fill ]
            in
            List.concat [ borderProps, otherProps ]

        label =
            Element.column
                []
                [ Element.row
                    []
                    [ Element.paragraph
                        [ Font.size 15
                        , fontWeight
                        ]
                        [ Element.text itemLabel ]
                    ]
                ]
    in
    Element.el
        menuItemElementAttrs
        (Input.button
            menuItemButtonAttrs
            { onPress = onPress
            , label = label
            }
        )
