module LegacyView.View exposing (view)

import Browser
import Element
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Helpers.GetterSetters as GetterSetters
import Helpers.String
import Html
import LegacyView.Nav
import LegacyView.PageTitle
import LegacyView.Project
import LegacyView.SelectProjects
import Page.GetSupport
import Page.HelpAbout
import Page.LoginJetstream
import Page.LoginOpenstack
import Page.LoginPicker
import Page.MessageLog
import Page.Settings
import Page.Toast
import Style.Helpers as SH
import Style.Toast
import Toasty
import Types.HelperTypes exposing (WindowSize)
import Types.OuterModel exposing (OuterModel)
import Types.OuterMsg exposing (OuterMsg(..))
import Types.SharedMsg exposing (SharedMsg(..))
import Types.View exposing (LoginView(..), NonProjectViewConstructor(..), ViewState(..))
import View.Helpers as VH
import View.Types


view : OuterModel -> Browser.Document OuterMsg
view outerModel =
    let
        context =
            VH.toViewContext outerModel.sharedModel
    in
    { title =
        LegacyView.PageTitle.pageTitle outerModel context
    , body =
        [ view_ outerModel context ]
    }


view_ : OuterModel -> View.Types.Context -> Html.Html OuterMsg
view_ outerModel context =
    Element.layout
        [ Font.size 17
        , Font.family
            [ Font.typeface "Open Sans"
            , Font.sansSerif
            ]
        , Font.color <| SH.toElementColor <| context.palette.on.background
        , Background.color <| SH.toElementColor <| context.palette.background
        ]
        (elementView outerModel.sharedModel.windowSize outerModel context)


elementView : WindowSize -> OuterModel -> View.Types.Context -> Element.Element OuterMsg
elementView windowSize outerModel context =
    let
        mainContentContainerView =
            Element.column
                [ Element.padding 10
                , Element.alignTop
                , Element.width <|
                    Element.px (windowSize.width - LegacyView.Nav.navMenuWidth)
                , Element.height Element.fill
                , Element.scrollbars
                ]
                [ case outerModel.viewState of
                    NonProjectView viewConstructor ->
                        case viewConstructor of
                            LoginPicker ->
                                Page.LoginPicker.view context outerModel.sharedModel
                                    |> Element.map LoginPickerMsg

                            Login loginView ->
                                case loginView of
                                    LoginOpenstack model ->
                                        Page.LoginOpenstack.view context model
                                            |> Element.map LoginOpenstackMsg

                                    LoginJetstream model ->
                                        Page.LoginJetstream.view context model
                                            |> Element.map LoginJetstreamMsg

                            LoadingUnscopedProjects _ ->
                                -- TODO put a fidget spinner here
                                Element.text <|
                                    String.join " "
                                        [ "Loading"
                                        , context.localization.unitOfTenancy
                                            |> Helpers.String.pluralize
                                            |> Helpers.String.toTitleCase
                                        ]

                            SelectProjects authUrl selectedProjects ->
                                LegacyView.SelectProjects.selectProjects outerModel.sharedModel context authUrl selectedProjects

                            MessageLog model ->
                                Page.MessageLog.view context outerModel.sharedModel model
                                    |> Element.map MessageLogMsg

                            Settings ->
                                Page.Settings.view context outerModel.sharedModel ()
                                    |> Element.map SettingsMsg

                            GetSupport model ->
                                Page.GetSupport.view context outerModel.sharedModel model
                                    |> Element.map GetSupportMsg

                            HelpAbout ->
                                Page.HelpAbout.view outerModel.sharedModel context

                            PageNotFound ->
                                Element.text "Error: page not found. Perhaps you are trying to reach an invalid URL."

                    ProjectView projectName projectViewParams viewConstructor ->
                        case GetterSetters.projectLookup outerModel.sharedModel projectName of
                            Nothing ->
                                Element.text <|
                                    String.join " "
                                        [ "Oops!"
                                        , context.localization.unitOfTenancy
                                            |> Helpers.String.toTitleCase
                                        , "not found"
                                        ]

                            Just project ->
                                LegacyView.Project.project
                                    outerModel.sharedModel
                                    context
                                    project
                                    projectViewParams
                                    viewConstructor
                , Element.html
                    (Toasty.view Style.Toast.toastConfig
                        (Page.Toast.view context outerModel.sharedModel)
                        (\m -> SharedMsg <| ToastyMsg m)
                        outerModel.sharedModel.toasties
                    )
                ]
    in
    Element.row
        [ Element.padding 0
        , Element.spacing 0
        , Element.width Element.fill
        , Element.height <|
            Element.px windowSize.height
        ]
        [ Element.column
            [ Element.padding 0
            , Element.spacing 0
            , Element.width Element.fill
            , Element.height <|
                Element.px windowSize.height
            ]
            [ Element.el
                [ Border.shadow { offset = ( 0, 0 ), size = 1, blur = 5, color = Element.rgb 0.1 0.1 0.1 }
                , Element.width Element.fill
                ]
                (LegacyView.Nav.navBar outerModel context)
            , Element.row
                [ Element.padding 0
                , Element.spacing 0
                , Element.width Element.fill
                , Element.height <|
                    Element.px (windowSize.height - LegacyView.Nav.navBarHeight)
                ]
                [ LegacyView.Nav.navMenu outerModel context
                , mainContentContainerView
                ]
            ]
        ]
