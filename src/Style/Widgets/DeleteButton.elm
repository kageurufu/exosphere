module Style.Widgets.DeleteButton exposing
    ( deleteIconButton
    , deletePopconfirm
    )

import Element
import FeatherIcons
import Html.Attributes as HtmlA
import Set
import Style.Helpers as SH exposing (spacer)
import Style.Types exposing (ExoPalette)
import Style.Widgets.Button as Button
import Style.Widgets.Popover.Popover exposing (popover)
import Style.Widgets.Popover.Types exposing (PopoverId)
import Widget


type alias PopconfirmContent msg =
    { confirmationText : String
    , onConfirm : Maybe msg
    , onCancel : Maybe msg
    }


deleteIconButton : ExoPalette -> Bool -> String -> Maybe msg -> Element.Element msg
deleteIconButton palette styleIsPrimary text onPress =
    let
        dangerBtnStyleDefaults =
            if styleIsPrimary then
                (SH.materialStyle palette).dangerButton

            else
                -- secondary style
                (SH.materialStyle palette).dangerButtonSecondary

        deleteBtnStyle =
            { dangerBtnStyleDefaults
                | container =
                    dangerBtnStyleDefaults.container
                        ++ [ Element.htmlAttribute <| HtmlA.title text
                           ]
                , labelRow =
                    dangerBtnStyleDefaults.labelRow
                        ++ [ Element.width Element.shrink
                           , Element.paddingXY spacer.px4 0
                           ]
            }
    in
    Widget.iconButton
        deleteBtnStyle
        { icon =
            FeatherIcons.trash2
                |> FeatherIcons.withSize 18
                |> FeatherIcons.toHtml []
                |> Element.html
        , text = text
        , onPress = onPress
        }


deletePopconfirmContent : ExoPalette -> PopconfirmContent msg -> Element.Attribute msg -> Element.Element msg
deletePopconfirmContent palette { confirmationText, onConfirm, onCancel } closePopconfirm =
    Element.column
        [ Element.spacing spacer.px16, Element.padding spacer.px4 ]
        [ Element.row [ Element.spacing spacer.px8 ]
            [ FeatherIcons.alertCircle
                |> FeatherIcons.withSize 20
                |> FeatherIcons.toHtml []
                |> Element.html
                |> Element.el []
            , Element.text confirmationText
            ]
        , Element.row [ Element.spacing spacer.px12, Element.alignRight ]
            [ Element.el [ closePopconfirm ] <|
                Button.default
                    palette
                    { text = "Cancel"
                    , onPress = onCancel
                    }
            , Element.el [ closePopconfirm ] <|
                Button.button Button.Danger
                    palette
                    { text = "Delete"
                    , onPress = onConfirm
                    }
            ]
        ]


deletePopconfirm :
    { viewContext | palette : ExoPalette, showPopovers : Set.Set PopoverId }
    -> (PopoverId -> msg)
    -> PopoverId
    -> PopconfirmContent msg
    -> Style.Types.PopoverPosition
    -> (msg -> Bool -> Element.Element msg)
    -> Element.Element msg
deletePopconfirm context msgMapper id content position target =
    popover context
        msgMapper
        { id = id
        , content =
            deletePopconfirmContent context.palette
                { confirmationText = content.confirmationText
                , onCancel = content.onCancel
                , onConfirm = content.onConfirm
                }
        , contentStyleAttrs = []
        , position = position
        , distanceToTarget = Nothing
        , target = target
        , targetStyleAttrs = []
        }
