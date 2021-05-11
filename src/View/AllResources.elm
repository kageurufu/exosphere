module View.AllResources exposing (allResources)

import Element
import Element.Events as Events
import Element.Font as Font
import Helpers.String
import Style.Helpers as SH
import Types.Defaults as Defaults
import Types.Types
    exposing
        ( AllResourcesListViewParams
        , Msg(..)
        , NonProjectViewConstructor(..)
        , Project
        , ProjectSpecificMsgConstructor(..)
        , ProjectViewConstructor(..)
        , ViewState(..)
        )
import View.Helpers as VH
import View.Keypairs
import View.ServerList
import View.Types
import View.Volumes


allResources :
    View.Types.Context
    -> Project
    -> AllResourcesListViewParams
    -> Element.Element Msg
allResources context p viewParams =
    let
        renderHeaderLink : String -> Msg -> Element.Element Msg
        renderHeaderLink str msg =
            Element.el
                (VH.heading3
                    ++ [ Events.onClick msg
                       , Element.mouseOver
                            [ Font.color
                                (context.palette.primary
                                    |> SH.toElementColor
                                )
                            ]
                       , Element.pointer
                       ]
                )
                (Element.text str)
    in
    Element.column
        [ Element.spacing 25, Element.width Element.fill ]
        [ Element.column
            [ Element.width Element.fill ]
            [ renderHeaderLink
                (context.localization.virtualComputer
                    |> Helpers.String.pluralize
                    |> Helpers.String.toTitleCase
                )
                (ProjectMsg p.auth.project.uuid <|
                    SetProjectView <|
                        ListProjectServers
                            Defaults.serverListViewParams
                )
            , View.ServerList.serverList context
                False
                p
                viewParams.serverListViewParams
                (\newParams ->
                    ProjectMsg p.auth.project.uuid <|
                        SetProjectView <|
                            AllResources { viewParams | serverListViewParams = newParams }
                )
            ]
        , Element.column
            [ Element.width Element.fill ]
            [ renderHeaderLink
                (context.localization.blockDevice
                    |> Helpers.String.pluralize
                    |> Helpers.String.toTitleCase
                )
                (ProjectMsg p.auth.project.uuid <|
                    SetProjectView <|
                        ListProjectVolumes
                            Defaults.volumeListViewParams
                )
            , View.Volumes.volumes context
                False
                p
                viewParams.volumeListViewParams
                (\newParams ->
                    ProjectMsg p.auth.project.uuid <|
                        SetProjectView <|
                            AllResources { viewParams | volumeListViewParams = newParams }
                )
            ]
        , Element.column
            [ Element.width Element.fill ]
            [ renderHeaderLink
                (context.localization.floatingIpAddress
                    |> Helpers.String.pluralize
                    |> Helpers.String.toTitleCase
                )
                (ProjectMsg p.auth.project.uuid <|
                    SetProjectView <|
                        ListFloatingIps
                            Defaults.floatingIpListViewParams
                )
            ]
        , Element.column
            [ Element.width Element.fill
            , Element.spacingXY 0 15 -- Because no quota view taking up space
            ]
            [ renderHeaderLink
                (context.localization.pkiPublicKeyForSsh
                    |> Helpers.String.pluralize
                    |> Helpers.String.toTitleCase
                )
                (ProjectMsg p.auth.project.uuid <|
                    SetProjectView <|
                        ListKeypairs
                            Defaults.keypairListViewParams
                )
            , View.Keypairs.listKeypairs context
                False
                p
                viewParams.keypairListViewParams
                (\newParams ->
                    ProjectMsg p.auth.project.uuid <|
                        SetProjectView <|
                            AllResources { viewParams | keypairListViewParams = newParams }
                )
            ]
        ]
