module Style.Widgets.FormValidation exposing (renderValidationError)

import Element
import Element.Font as Font
import FeatherIcons
import Style.Helpers as SH exposing (spacer)
import View.Types


renderValidationError : View.Types.Context -> String -> Element.Element a
renderValidationError context msg =
    Element.row
        [ Element.spacing spacer.px8
        , Font.color <| SH.toElementColor context.palette.danger.textOnNeutralBG
        ]
        [ Element.el
            []
            (FeatherIcons.alertCircle
                |> FeatherIcons.toHtml []
                |> Element.html
            )
        , Element.text msg
        ]
