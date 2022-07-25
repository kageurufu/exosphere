port module DesignSystem.Explorer exposing (main)

import Browser.Events
import Color
import DesignSystem.Helpers exposing (Plugins, palettize, toHtml)
import DesignSystem.Stories.Card as CardStories
import DesignSystem.Stories.ColorPalette as ColorPalette
import DesignSystem.Stories.Link as LinkStories
import DesignSystem.Stories.Text as TextStories
import Element
import Element.Font as Font
import Html
import Html.Attributes exposing (src, style)
import Set
import Style.Helpers as SH
import Style.Types
import Style.Widgets.Button as Button
import Style.Widgets.Card exposing (badge)
import Style.Widgets.CopyableText exposing (copyableText)
import Style.Widgets.Icon exposing (bell, console, copyToClipboard, history, ipAddress, lock, lockOpen, plusCircle, remove, roundRect, timesCircle)
import Style.Widgets.IconButton exposing (chip)
import Style.Widgets.Meter exposing (meter)
import Style.Widgets.Popover.Popover exposing (popover, toggleIfTargetIsOutside)
import Style.Widgets.Popover.Types exposing (PopoverId)
import Style.Widgets.StatusBadge exposing (StatusBadgeState(..), statusBadge)
import UIExplorer
    exposing
        ( Config
        , UIExplorerProgram
        , category
        , createCategories
        , exploreWithCategories
        , storiesOf
        )
import UIExplorer.ColorMode exposing (ColorMode(..), colorModeToString)
import UIExplorer.Plugins.Note as NotePlugin
import UIExplorer.Plugins.Tabs as TabsPlugin
import UIExplorer.Plugins.Tabs.Icons as TabsIconsPlugin



--- theme


{-| Extracts brand colors from the config.js flags set for this application.
-}
deployerColors : Flags -> Style.Types.DeployerColorThemes
deployerColors flags =
    case flags.palette of
        Just pal ->
            { light =
                { primary = Color.rgb255 pal.light.primary.r pal.light.primary.g pal.light.primary.b
                , secondary = Color.rgb255 pal.light.secondary.r pal.light.secondary.g pal.light.secondary.b
                }
            , dark =
                { primary = Color.rgb255 pal.dark.primary.r pal.dark.primary.g pal.dark.primary.b
                , secondary = Color.rgb255 pal.dark.secondary.r pal.dark.secondary.g pal.dark.secondary.b
                }
            }

        Nothing ->
            Style.Types.defaultColors


{-| Port for signalling a color mode change to the html doc.

    ref. https://github.com/kalutheo/elm-ui-explorer/blob/master/examples/button/ExplorerWithNotes.elm#L22

-}
port onModeChanged : String -> Cmd msg



--- component helpers


{-| Create an icon with standard size & color.
-}
defaultIcon : Style.Types.ExoPalette -> (Element.Color -> number -> icon) -> icon
defaultIcon pal icon =
    icon (pal.neutral.icon |> SH.toElementColor) 25



--- MODEL


{-| Which Popovers are visible?
-}
type alias PopoverState =
    { showPopovers : Set.Set PopoverId }


type alias Model =
    { expandoCard : CardStories.ExpandoCardState
    , popover : PopoverState
    , deployerColors : Style.Types.DeployerColorThemes
    , tabs : TabsPlugin.Model
    }


initialModel : Model
initialModel =
    { expandoCard = { expanded = False }
    , deployerColors = Style.Types.defaultColors
    , popover = { showPopovers = Set.empty }
    , tabs = TabsPlugin.initialModel
    }



--- FLAGS


{-| Flags given to the Explorer on startup.

This is a pared down version of Exosphere's `Types.Flags`.

-}
type alias Flags =
    { palette :
        Maybe
            { light :
                { primary :
                    { r : Int
                    , g : Int
                    , b : Int
                    }
                , secondary :
                    { r : Int
                    , g : Int
                    , b : Int
                    }
                }
            , dark :
                { primary :
                    { r : Int
                    , g : Int
                    , b : Int
                    }
                , secondary :
                    { r : Int
                    , g : Int
                    , b : Int
                    }
                }
            }
    }



--- UPDATE


type Msg
    = NoOp
    | ToggleExpandoCard Bool
    | TogglePopover PopoverId
    | TabMsg TabsPlugin.Msg



--- MAIN


config : Config Model Msg Plugins Flags
config =
    { customModel = initialModel
    , customHeader =
        Just
            { title = "Exosphere Design System"
            , logo = UIExplorer.logoFromHtml (Html.img [ src "assets/img/logo-alt.svg", style "padding-top" "10px", style "padding-left" "5px" ] [])
            , titleColor = Just "#FFFFFF"
            , bgColor = Just "#181725"
            }
    , init = \f m -> { m | deployerColors = deployerColors f }
    , enableDarkMode = True
    , subscriptions =
        \m ->
            Sub.batch <|
                List.map
                    (\popoverId ->
                        Browser.Events.onMouseDown
                            (toggleIfTargetIsOutside popoverId TogglePopover)
                    )
                    (Set.toList m.customModel.popover.showPopovers)
    , update =
        \msg m ->
            let
                model =
                    m.customModel
            in
            case msg of
                NoOp ->
                    ( m, Cmd.none )

                ToggleExpandoCard expanded ->
                    ( { m
                        | customModel =
                            { model
                                | expandoCard = { expanded = expanded }
                            }
                      }
                    , Cmd.none
                    )

                TogglePopover popoverId ->
                    ( { m
                        | customModel =
                            { model
                                | popover =
                                    { showPopovers =
                                        if Set.member popoverId model.popover.showPopovers then
                                            Set.remove popoverId model.popover.showPopovers

                                        else
                                            Set.insert popoverId model.popover.showPopovers
                                    }
                            }
                      }
                    , Cmd.none
                    )

                TabMsg submsg ->
                    let
                        cm =
                            m.customModel
                    in
                    ( { m | customModel = { cm | tabs = TabsPlugin.update submsg m.customModel.tabs } }, Cmd.none )
    , menuViewEnhancer = \_ v -> v
    , viewEnhancer =
        \m stories ->
            let
                colorMode =
                    m.colorMode |> Maybe.withDefault Light
            in
            Html.div []
                [ stories
                , TabsPlugin.view colorMode
                    m.customModel.tabs
                    [ ( "Notes", NotePlugin.viewEnhancer m, TabsIconsPlugin.note )
                    ]
                    TabMsg
                ]
    , onModeChanged = Just (onModeChanged << colorModeToString << Maybe.withDefault Light)
    , documentTitle = Just "Exosphere Design System"
    }


main : UIExplorerProgram Model Msg Plugins Flags
main =
    exploreWithCategories
        config
        (createCategories
            |> category "Atoms"
                [ ColorPalette.stories toHtml
                , TextStories.stories toHtml
                , LinkStories.stories toHtml
                , storiesOf
                    "Icon"
                    (List.map
                        (\icon ->
                            ( Tuple.first icon, \m -> toHtml (palettize m) <| defaultIcon (palettize m) <| Tuple.second icon, { note = """
## Usage

Exosphere has several custom icons in `Style.Widgets.Icon`:

    Icon.lockOpen (SH.toElementColor context.palette.on.background) 28

For everything else, use `FeatherIcons`:

    FeatherIcons.logOut |> FeatherIcons.withSize 18 |> FeatherIcons.toHtml [] |> Element.html |> Element.el []
                            """ } )
                        )
                        [ ( "bell", bell )
                        , ( "console", console )
                        , ( "copyToClipboard", copyToClipboard )
                        , ( "history", history )
                        , ( "ipAddress", ipAddress )
                        , ( "lock", lock )
                        , ( "lockOpen", lockOpen )
                        , ( "plusCircle", plusCircle )
                        , ( "remove", remove )
                        , ( "roundRect", roundRect )
                        , ( "timesCircle", timesCircle )
                        ]
                    )
                , storiesOf
                    "Button"
                    (List.map
                        (\button ->
                            ( button.name
                            , \m ->
                                toHtml (palettize m) <|
                                    button.widget (palettize m) { text = button.text, onPress = button.onPress }
                            , { note = """
## Usage

- Primary: For major positive actions, of which there is normally at most 1 per page.

- Secondary: The most commonly used button variant, also available as `Button.default` for convenience.

- Warning: Used when an action has reversible consequences with a major impact.

- Danger: For when an action has irreversible consequences.

- Danger Secondary: Theoretically, for when an action has irreversible consequences but a minor impact.
                            """ }
                            )
                        )
                        [ { name = "primary", widget = Button.primary, text = "Create", onPress = Just NoOp }
                        , { name = "disabled", widget = Button.primary, text = "Next", onPress = Nothing }
                        , { name = "secondary", widget = Button.default, text = "Next", onPress = Just NoOp }
                        , { name = "warning", widget = Button.button Button.Warning, text = "Suspend", onPress = Just NoOp }
                        , { name = "danger", widget = Button.button Button.Danger, text = "Delete All", onPress = Just NoOp }
                        , { name = "danger secondary", widget = Button.button Button.DangerSecondary, text = "Delete All", onPress = Just NoOp }
                        ]
                    )
                , storiesOf
                    "Badge"
                    [ ( "default", \m -> toHtml (palettize m) <| badge "Experimental", { note = """
## Usage

Used to mark features as "Experimental".

(Theoretically, can be combined within components to show extra details like counts.)

### Alternatives

If you are looking for a way to display removable tags, consider a [chip](/#Organisms/Chip).

If you want to show a resource's current state or provide feedback on a process, consider using a [status badge](/#Atoms/Status%20Badge).
                        """ } )
                    ]
                , storiesOf
                    "Status Badge"
                    [ ( "good", \m -> toHtml (palettize m) <| statusBadge (palettize m) ReadyGood (Element.text "Ready"), { note = "" } )
                    , ( "muted", \m -> toHtml (palettize m) <| statusBadge (palettize m) Muted (Element.text "Unknown"), { note = "" } )
                    , ( "warning", \m -> toHtml (palettize m) <| statusBadge (palettize m) Style.Widgets.StatusBadge.Warning (Element.text "Building"), { note = "" } )
                    , ( "error", \m -> toHtml (palettize m) <| statusBadge (palettize m) Error (Element.text "Error"), { note = """
## Usage

Displays a read-only label which clearly provides guidance on the current state of a resource.

(This is most often in the context of server status.)
                        """ } )
                    ]
                ]
            |> category "Molecules"
                [ storiesOf
                    "Chip"
                    [ ( "default", \m -> toHtml (palettize m) <| chip (palettize m) Nothing (Element.text "assigned"), { note = "" } )
                    , ( "with badge", \m -> toHtml (palettize m) <| chip (palettize m) Nothing (Element.row [ Element.spacing 5 ] [ Element.text "ubuntu", badge "10" ]), { note = "" } )
                    ]
                , storiesOf
                    "Copyable Text"
                    [ ( "default"
                      , \m ->
                            toHtml (palettize m) <|
                                copyableText
                                    (palettize m)
                                    [ Font.family [ Font.monospace ] ]
                                    "192.168.1.1"
                      , { note = """
## Usage

Shows stylable text with an accessory button for copying the text content to the user's clipboard.

This uses [clipboard.js](https://clipboardjs.com/) under the hood & relies on a [port for initialisation](https://gitlab.com/exosphere/exosphere/-/blob/master/ports.js#L101).
                        """ }
                      )
                    ]
                , storiesOf
                    "Meter"
                    [ ( "default", \m -> toHtml (palettize m) <| meter (palettize m) "Space used" "6 of 10 GB" 6 10, { note = "" } )
                    ]
                ]
            |> category "Organisms"
                [ CardStories.stories toHtml { onPress = Just NoOp, onExpand = \next -> ToggleExpandoCard next }
                , storiesOf
                    "Popover"
                    (List.map
                        (\positionTuple ->
                            ( "position: " ++ Tuple.first positionTuple
                            , \m ->
                                let
                                    demoPopoverContent _ =
                                        Element.paragraph
                                            [ Element.width <| Element.px 275
                                            , Font.size 16
                                            ]
                                            [ Element.text <|
                                                "I'm a popover that can be used as dropdown, toggle tip, etc. "
                                                    ++ "Clicking outside of me will close me."
                                            ]

                                    demoPopoverTarget togglePopoverMsg _ =
                                        Button.primary (palettize m)
                                            { text = "Click me"
                                            , onPress = Just togglePopoverMsg
                                            }

                                    demoPopover =
                                        popover
                                            { palette = palettize m
                                            , showPopovers = m.customModel.popover.showPopovers
                                            }
                                            TogglePopover
                                            { id = "explorerDemoPopover"
                                            , content = demoPopoverContent
                                            , contentStyleAttrs = [ Element.padding 20 ]
                                            , position = Tuple.second positionTuple
                                            , distanceToTarget = Nothing
                                            , target = demoPopoverTarget
                                            , targetStyleAttrs = []
                                            }
                                in
                                toHtml (palettize m) <|
                                    Element.el [ Element.paddingXY 400 100 ]
                                        demoPopover
                            , { note = "" }
                            )
                        )
                        [ ( "TopLeft", Style.Types.PositionTopLeft )
                        , ( "Top", Style.Types.PositionTop )
                        , ( "TopRight", Style.Types.PositionTopRight )
                        , ( "RightTop", Style.Types.PositionRightTop )
                        , ( "Right", Style.Types.PositionRight )
                        , ( "RightBottom", Style.Types.PositionRightBottom )
                        , ( "BottomRight", Style.Types.PositionBottomRight )
                        , ( "Bottom", Style.Types.PositionBottom )
                        , ( "BottomLeft", Style.Types.PositionBottomLeft )
                        , ( "LeftBottom", Style.Types.PositionLeftBottom )
                        , ( "Left", Style.Types.PositionLeft )
                        , ( "LeftTop", Style.Types.PositionLeftTop )
                        ]
                    )
                ]
        )
