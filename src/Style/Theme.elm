module Style.Theme exposing (Style, materialStyle)

import Element
import Widget.Style exposing (ColumnStyle, SortTableStyle, TextInputStyle)
import Widget.Style.Material as Material


type alias Style style msg =
    { style
        | textInput : TextInputStyle msg
        , column : ColumnStyle msg
        , sortTable : SortTableStyle msg
    }


materialStyle : Style {} msg
materialStyle =
    { textInput = Material.textInput Material.defaultPalette
    , column = Material.column
    , sortTable =
        { containerTable = []
        , headerButton = Material.textButton Material.defaultPalette
        , ascIcon =
            Material.expansionPanel Material.defaultPalette
                |> .collapseIcon
        , descIcon =
            Material.expansionPanel Material.defaultPalette
                |> .expandIcon
        , defaultIcon = Element.none
        }
    }
