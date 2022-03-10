module Page.ImageList exposing (Model, Msg(..), init, update, view)

import Element
import Element.Font as Font
import Element.Input as Input
import FeatherIcons
import FormatNumber.Locales exposing (Decimals(..))
import Helpers.Formatting exposing (Unit(..), humanNumber)
import Helpers.GetterSetters as GetterSetters
import Helpers.RemoteDataPlusPlus as RDPP
import Helpers.ResourceList exposing (listItemColumnAttribs)
import Helpers.String
import Html.Attributes as HtmlA
import List.Extra
import OpenStack.Types as OSTypes exposing (Image)
import Route
import Set
import Set.Extra
import Style.Helpers as SH
import Style.Widgets.Button as Button
import Style.Widgets.Card as ExoCard
import Style.Widgets.DataList as DataList
import Style.Widgets.DeleteButton exposing (deleteIconButton)
import Style.Widgets.Icon as Icon
import Style.Widgets.IconButton exposing (chip)
import Types.Project exposing (Project)
import Types.SharedMsg as SharedMsg
import View.Helpers as VH
import View.Types exposing (Context, ImageTag)
import Widget


type alias Model =
    { searchText : String
    , tags : Set.Set String
    , onlyOwnImages : Bool
    , expandImageDetails : Set.Set OSTypes.ImageUuid
    , visibilityFilter : ImageListVisibilityFilter
    , deleteConfirmations : Set.Set DeleteConfirmation
    , deletionsAttempted : Set.Set DeleteConfirmation
    , showDeleteButtons : Bool
    , showHeading : Bool
    , dataListModel : DataList.Model
    }


type alias ImageListVisibilityFilter =
    { public : Bool
    , community : Bool
    , shared : Bool
    , private : Bool
    }


type alias DeleteConfirmation =
    OSTypes.ImageUuid


type Msg
    = GotSearchText String
    | GotTagSelection String Bool
    | GotOnlyOwnImages Bool
    | GotExpandImage OSTypes.ImageUuid Bool
    | GotVisibilityFilter ImageListVisibilityFilter
    | GotClearFilters
    | GotDeleteNeedsConfirm DeleteConfirmation
    | GotDeleteConfirm DeleteConfirmation
    | GotDeleteCancel DeleteConfirmation
    | DataListMsg DataList.Msg
    | NoOp


init : Bool -> Bool -> Model
init showDeleteButtons showHeading =
    { searchText = ""
    , tags = Set.empty
    , onlyOwnImages = False
    , expandImageDetails = Set.empty
    , visibilityFilter = ImageListVisibilityFilter True True True True
    , deleteConfirmations = Set.empty
    , deletionsAttempted = Set.empty
    , showDeleteButtons = showDeleteButtons
    , showHeading = showHeading
    , dataListModel = DataList.init <| DataList.getDefaultFilterOptions filters
    }


update : Msg -> Project -> Model -> ( Model, Cmd Msg, SharedMsg.SharedMsg )
update msg project model =
    case msg of
        GotSearchText searchText ->
            ( { model | searchText = searchText }, Cmd.none, SharedMsg.NoOp )

        GotTagSelection tag selected ->
            let
                action =
                    if selected then
                        Set.insert

                    else
                        Set.remove
            in
            ( { model | tags = action tag model.tags }, Cmd.none, SharedMsg.NoOp )

        GotOnlyOwnImages onlyOwn ->
            ( { model | onlyOwnImages = onlyOwn }, Cmd.none, SharedMsg.NoOp )

        GotExpandImage imageUuid expanded ->
            ( { model
                | expandImageDetails =
                    let
                        func =
                            if expanded then
                                Set.insert

                            else
                                Set.remove
                    in
                    func imageUuid model.expandImageDetails
              }
            , Cmd.none
            , SharedMsg.NoOp
            )

        GotVisibilityFilter filter ->
            ( { model | visibilityFilter = filter }, Cmd.none, SharedMsg.NoOp )

        GotClearFilters ->
            ( init model.showDeleteButtons model.showHeading, Cmd.none, SharedMsg.NoOp )

        GotDeleteNeedsConfirm imageId ->
            ( { model
                | deleteConfirmations =
                    Set.insert imageId model.deleteConfirmations
              }
            , Cmd.none
            , SharedMsg.NoOp
            )

        GotDeleteConfirm imageId ->
            ( { model | deletionsAttempted = Set.insert imageId model.deletionsAttempted }
            , Cmd.none
            , SharedMsg.ProjectMsg (GetterSetters.projectIdentifier project) <|
                SharedMsg.RequestDeleteImage imageId
            )

        GotDeleteCancel imageId ->
            ( { model
                | deleteConfirmations =
                    Set.remove imageId model.deleteConfirmations
              }
            , Cmd.none
            , SharedMsg.NoOp
            )

        DataListMsg dataListMsg ->
            ( { model
                | dataListModel =
                    DataList.update dataListMsg model.dataListModel
              }
            , Cmd.none
            , SharedMsg.NoOp
            )

        NoOp ->
            ( model, Cmd.none, SharedMsg.NoOp )


view : View.Types.Context -> Project -> Model -> Element.Element Msg
view context project model =
    let
        generateAllTags : List OSTypes.Image -> List ImageTag
        generateAllTags someImages =
            List.map (\i -> i.tags) someImages
                |> List.concat
                |> List.sort
                |> List.Extra.gatherEquals
                |> List.map (\t -> { label = Tuple.first t, frequency = 1 + List.length (Tuple.second t) })
                |> List.sortBy .frequency
                |> List.reverse

        filteredImages =
            project.images |> RDPP.withDefault [] |> filterImages model project

        tagsAfterFilteringImages =
            generateAllTags filteredImages

        noMatchWarning =
            (model.tags /= Set.empty) && (List.length filteredImages == 0)

        featuredImageNamePrefix =
            VH.featuredImageNamePrefixLookup context project

        ( featuredImages, nonFeaturedImages_ ) =
            List.partition (isImageFeaturedByDeployer featuredImageNamePrefix) filteredImages

        ( ownImages, otherImages ) =
            List.partition (\i -> projectOwnsImage project i) nonFeaturedImages_

        combinedImages =
            List.concat [ featuredImages, ownImages, otherImages ]

        tagView : ImageTag -> Element.Element Msg
        tagView tag =
            let
                iconFunction checked =
                    if checked then
                        Element.none

                    else
                        Icon.plusCircle (SH.toElementColor context.palette.on.background) 12

                tagChecked =
                    Set.member tag.label model.tags

                ( tagCount, _ ) =
                    humanNumber context.locale Count tag.frequency

                checkboxLabel =
                    tag.label ++ " (" ++ tagCount ++ ")"
            in
            if tagChecked then
                Element.none

            else
                Input.checkbox [ Element.paddingXY 10 5 ]
                    { checked = tagChecked
                    , onChange = \_ -> GotTagSelection tag.label True
                    , icon = iconFunction
                    , label = Input.labelRight [] (Element.text checkboxLabel)
                    }

        tagChipView : ImageTag -> Element.Element Msg
        tagChipView tag =
            let
                tagChecked =
                    Set.member tag.label model.tags

                chipLabel =
                    Element.text tag.label

                unselectTag =
                    GotTagSelection tag.label False
            in
            if tagChecked then
                chip context.palette (Just unselectTag) chipLabel

            else
                Element.none

        tagsView =
            Element.column [ Element.spacing 10 ]
                [ Element.text "Filtering on these tags:"
                , Element.wrappedRow
                    [ Element.height Element.shrink
                    , Element.width Element.shrink
                    ]
                    (List.map tagChipView tagsAfterFilteringImages)
                , Element.text <|
                    String.join " "
                        [ "Select tags to filter"
                        , context.localization.staticRepresentationOfBlockDeviceContents
                            |> Helpers.String.pluralize
                        , "on:"
                        ]
                , Element.wrappedRow []
                    (List.map tagView tagsAfterFilteringImages)
                ]

        imagesColumnView =
            Widget.column
                ((SH.materialStyle context.palette).column
                    |> (\x ->
                            { x
                                | containerColumn =
                                    (SH.materialStyle context.palette).column.containerColumn
                                        ++ [ Element.width Element.fill
                                           , Element.padding 0
                                           ]
                                , element =
                                    (SH.materialStyle context.palette).column.element
                                        ++ [ Element.width Element.fill
                                           ]
                            }
                       )
                )

        visibilityFilters =
            Element.row
                [ Element.spacing 10 ]
                [ Element.text <|
                    String.join " "
                        [ "Filter on"
                        , context.localization.staticRepresentationOfBlockDeviceContents
                        , "visibility:"
                        ]

                -- TODO duplication of logic in these checkboxes, factor out what is common
                , Input.checkbox []
                    { checked = model.visibilityFilter.public
                    , onChange =
                        \new ->
                            let
                                oldVisibilityFilter =
                                    model.visibilityFilter

                                newVisibilityFilter =
                                    { oldVisibilityFilter | public = new }
                            in
                            GotVisibilityFilter newVisibilityFilter
                    , icon = Input.defaultCheckbox
                    , label =
                        Input.labelRight [] <|
                            Element.text "Public"
                    }
                , Input.checkbox []
                    { checked = model.visibilityFilter.community
                    , onChange =
                        \new ->
                            let
                                oldVisibilityFilter =
                                    model.visibilityFilter

                                newVisibilityFilter =
                                    { oldVisibilityFilter | community = new }
                            in
                            GotVisibilityFilter newVisibilityFilter
                    , icon = Input.defaultCheckbox
                    , label =
                        Input.labelRight [] <|
                            Element.text "Community"
                    }
                , Input.checkbox []
                    { checked = model.visibilityFilter.shared
                    , onChange =
                        \new ->
                            let
                                oldVisibilityFilter =
                                    model.visibilityFilter

                                newVisibilityFilter =
                                    { oldVisibilityFilter | shared = new }
                            in
                            GotVisibilityFilter newVisibilityFilter
                    , icon = Input.defaultCheckbox
                    , label =
                        Input.labelRight [] <|
                            Element.text "Shared"
                    }
                , Input.checkbox []
                    { checked = model.visibilityFilter.private
                    , onChange =
                        \new ->
                            let
                                oldVisibilityFilter =
                                    model.visibilityFilter

                                newVisibilityFilter =
                                    { oldVisibilityFilter | private = new }
                            in
                            GotVisibilityFilter newVisibilityFilter
                    , icon = Input.defaultCheckbox
                    , label =
                        Input.labelRight [] <|
                            Element.text "Private"
                    }
                ]

        loadedView : List OSTypes.Image -> Element.Element Msg
        loadedView _ =
            Element.column VH.contentContainer
                [ if model.showHeading then
                    Element.row (VH.heading2 context.palette ++ [ Element.spacing 15 ])
                        [ FeatherIcons.package |> FeatherIcons.toHtml [] |> Element.html |> Element.el []
                        , Element.text
                            (context.localization.staticRepresentationOfBlockDeviceContents
                                |> Helpers.String.pluralize
                                |> Helpers.String.toTitleCase
                            )
                        ]

                  else
                    Element.none
                , Input.text (VH.inputItemAttributes context.palette.background)
                    { text = model.searchText
                    , placeholder = Just (Input.placeholder [] (Element.text "try \"Ubuntu\""))
                    , onChange = GotSearchText
                    , label =
                        Input.labelAbove []
                            (Element.text <|
                                String.join " "
                                    [ "Filter on"
                                    , context.localization.staticRepresentationOfBlockDeviceContents
                                    , "name:"
                                    ]
                            )
                    }
                , visibilityFilters
                , tagsView
                , Input.checkbox []
                    { checked = model.onlyOwnImages
                    , onChange = GotOnlyOwnImages
                    , icon = Input.defaultCheckbox
                    , label =
                        Input.labelRight [] <|
                            Element.text <|
                                String.join
                                    " "
                                    [ "Show only"
                                    , context.localization.staticRepresentationOfBlockDeviceContents
                                        |> Helpers.String.pluralize
                                    , "owned by this"
                                    , context.localization.unitOfTenancy
                                    ]
                    }
                , Button.default context.palette
                    { text = "Clear filters (show all)"
                    , onPress = Just GotClearFilters
                    }
                , if noMatchWarning then
                    Element.text "No matches found. Broaden your search terms, or clear the search filter."

                  else
                    Element.none
                , DataList.view
                    model.dataListModel
                    DataListMsg
                    context.palette
                    []
                    (imageView model context project)
                    (imageRecords context project combinedImages)
                    []
                    filters
                ]
    in
    VH.renderRDPP context project.images (Helpers.String.pluralize context.localization.staticRepresentationOfBlockDeviceContents) loadedView


renderImage : View.Types.Context -> Project -> Model -> OSTypes.Image -> Element.Element Msg
renderImage context project model image =
    let
        { locale } =
            context

        imageDetailsExpanded =
            Set.member image.uuid model.expandImageDetails

        size =
            case image.size of
                Just s ->
                    let
                        ( count, units ) =
                            humanNumber { locale | decimals = Exact 2 } Bytes s
                    in
                    count ++ " " ++ units

                Nothing ->
                    "size unknown"

        chooseRoute =
            Route.ProjectRoute (GetterSetters.projectIdentifier project) <|
                Route.ServerCreate
                    image.uuid
                    image.name
                    Nothing
                    (VH.userAppProxyLookup context project
                        |> Maybe.map (\_ -> True)
                    )

        tagChip tag =
            Element.el [ Element.paddingXY 5 0 ]
                (Widget.button (SH.materialStyle context.palette).chipButton
                    { text = tag
                    , icon = Element.none
                    , onPress =
                        Nothing
                    }
                )

        chooseButton =
            Element.link []
                { url = Route.toUrl context.urlPathPrefix chooseRoute
                , label =
                    Button.primary
                        context.palette
                        { text = "Create " ++ Helpers.String.toTitleCase context.localization.virtualComputer
                        , onPress =
                            case image.status of
                                OSTypes.ImageActive ->
                                    Just NoOp

                                _ ->
                                    Nothing
                        }
                }

        confirmationNeeded =
            Set.member image.uuid model.deleteConfirmations

        deletionAttempted =
            Set.member image.uuid model.deletionsAttempted

        deleteButton =
            if projectOwnsImage project image then
                case ( image.status, confirmationNeeded, deletionAttempted ) of
                    ( OSTypes.ImagePendingDelete, _, _ ) ->
                        Widget.circularProgressIndicator (SH.materialStyle context.palette).progressIndicator Nothing

                    ( _, _, True ) ->
                        Widget.circularProgressIndicator (SH.materialStyle context.palette).progressIndicator Nothing

                    ( _, True, _ ) ->
                        Element.row [ Element.spacing 10 ]
                            [ Element.text "Confirm delete?"
                            , Widget.iconButton
                                (SH.materialStyle context.palette).dangerButton
                                { icon = Icon.remove (SH.toElementColor context.palette.on.error) 16
                                , text = "Delete"
                                , onPress =
                                    Just <| GotDeleteConfirm image.uuid
                                }
                            , Button.default
                                context.palette
                                { text = "Cancel"
                                , onPress =
                                    Just <| GotDeleteCancel image.uuid
                                }
                            ]

                    ( _, False, _ ) ->
                        if image.protected == True then
                            Widget.iconButton
                                (SH.materialStyle context.palette).button
                                { icon = Icon.remove (SH.toElementColor context.palette.on.error) 16
                                , text = "Delete"
                                , onPress = Nothing
                                }

                        else
                            Widget.iconButton
                                (SH.materialStyle context.palette).dangerButton
                                { icon = Icon.remove (SH.toElementColor context.palette.on.error) 16
                                , text = "Delete"
                                , onPress =
                                    Just <| GotDeleteNeedsConfirm image.uuid
                                }

            else
                Element.none

        featuredImageNamePrefix =
            VH.featuredImageNamePrefixLookup context project

        featuredBadge =
            if isImageFeaturedByDeployer featuredImageNamePrefix image then
                ExoCard.badge "featured"

            else
                Element.none

        ownerBadge =
            if projectOwnsImage project image then
                ExoCard.badge <|
                    String.join " "
                        [ "belongs to this"
                        , context.localization.unitOfTenancy
                        ]

            else
                Element.none

        title =
            Element.row
                [ Element.width Element.fill
                ]
                [ Element.el
                    [ Font.bold
                    , Element.padding 5
                    ]
                    (Element.text image.name)
                , featuredBadge
                , ownerBadge
                ]

        subtitle =
            Element.row
                []
                [ Element.el
                    [ Font.color <| SH.toElementColor <| context.palette.muted
                    , Element.padding 5
                    ]
                    (Element.text size)
                ]

        imageDetailsView =
            Element.column
                (VH.exoColumnAttributes
                    ++ [ Element.width Element.fill ]
                )
                [ Element.wrappedRow
                    [ Element.width Element.fill
                    ]
                    [ Element.el
                        [ Font.color <| SH.toElementColor <| context.palette.muted
                        , Element.padding 5
                        ]
                        (Element.text <| "Visibility: " ++ OSTypes.imageVisibilityToString image.visibility)
                    ]
                , Element.wrappedRow
                    [ Element.width Element.fill
                    ]
                    (Element.el
                        [ Font.color <| SH.toElementColor <| context.palette.muted
                        , Element.padding 5
                        ]
                        (Element.text "Tags:")
                        :: List.map
                            tagChip
                            image.tags
                    )
                , Element.row [ Element.width Element.fill, Element.spacing 10 ]
                    [ chooseButton
                    , if model.showDeleteButtons then
                        Element.el [ Element.alignRight ] deleteButton

                      else
                        Element.none
                    ]
                ]
    in
    ExoCard.expandoCard
        context.palette
        imageDetailsExpanded
        (\expanded -> GotExpandImage image.uuid expanded)
        title
        subtitle
        imageDetailsView


projectOwnsImage : Project -> OSTypes.Image -> Bool
projectOwnsImage project image =
    image.projectUuid == project.auth.project.uuid


filterByOwner : Bool -> Project -> List OSTypes.Image -> List OSTypes.Image
filterByOwner onlyOwnImages project someImages =
    if not onlyOwnImages then
        someImages

    else
        List.filter (projectOwnsImage project) someImages


filterByTags : Set.Set String -> List OSTypes.Image -> List OSTypes.Image
filterByTags tagsToFilterBy someImages =
    if tagsToFilterBy == Set.empty then
        someImages

    else
        List.filter
            (\i ->
                let
                    imageTags =
                        Set.fromList i.tags
                in
                Set.Extra.subset tagsToFilterBy imageTags
            )
            someImages


filterBySearchText : String -> List OSTypes.Image -> List OSTypes.Image
filterBySearchText searchText someImages =
    if searchText == "" then
        someImages

    else
        List.filter (\i -> String.contains (String.toUpper searchText) (String.toUpper i.name)) someImages


filterByVisibility : ImageListVisibilityFilter -> List OSTypes.Image -> List OSTypes.Image
filterByVisibility filter someImages =
    let
        include i =
            List.any identity
                [ i.visibility == OSTypes.ImagePublic && filter.public
                , i.visibility == OSTypes.ImagePrivate && filter.private
                , i.visibility == OSTypes.ImageCommunity && filter.community
                , i.visibility == OSTypes.ImageShared && filter.shared
                ]
    in
    List.filter include someImages


isImageFeaturedByDeployer : Maybe String -> OSTypes.Image -> Bool
isImageFeaturedByDeployer maybeFeaturedImageNamePrefix image =
    case maybeFeaturedImageNamePrefix of
        Nothing ->
            False

        Just featuredImageNamePrefix ->
            String.startsWith featuredImageNamePrefix image.name && image.visibility == OSTypes.ImagePublic


filterImages : Model -> Project -> List OSTypes.Image -> List OSTypes.Image
filterImages model project someImages =
    someImages
        |> filterByOwner model.onlyOwnImages project
        |> filterByTags model.tags
        |> filterBySearchText model.searchText
        |> filterByVisibility model.visibilityFilter


type alias ImageRecord =
    DataList.DataRecord
        { image : Image
        , featured : Bool
        , owned : Bool
        }


imageRecords : Context -> Project -> List Image -> List ImageRecord
imageRecords context project images =
    let
        featuredImageNamePrefix =
            VH.featuredImageNamePrefixLookup context project
    in
    List.map
        (\image ->
            { id = image.uuid
            , selectable = False
            , image = image
            , featured = isImageFeaturedByDeployer featuredImageNamePrefix image
            , owned = projectOwnsImage project image
            }
        )
        images


imageView : Model -> Context -> Project -> ImageRecord -> Element.Element Msg
imageView model context project imageRecord =
    let
        deleteImageBtn =
            deleteIconButton
                context.palette
                False
                ("Delete " ++ context.localization.staticRepresentationOfBlockDeviceContents)
                Nothing

        createServerBtn =
            let
                textBtn onPress =
                    Widget.textButton
                        (SH.materialStyle context.palette).button
                        { text =
                            "Create "
                                ++ Helpers.String.toTitleCase
                                    context.localization.virtualComputer
                        , onPress = onPress
                        }

                serverCreationRoute =
                    Route.ProjectRoute (GetterSetters.projectIdentifier project) <|
                        Route.ServerCreate
                            imageRecord.image.uuid
                            imageRecord.image.name
                            Nothing
                            (VH.userAppProxyLookup context project
                                |> Maybe.map (\_ -> True)
                            )
            in
            case imageRecord.image.status of
                OSTypes.ImageActive ->
                    Element.link []
                        { url = Route.toUrl context.urlPathPrefix serverCreationRoute
                        , label = textBtn (Just NoOp)
                        }

                _ ->
                    Element.el [ Element.htmlAttribute <| HtmlA.title "Image is not active!" ] (textBtn Nothing)

        imageActions =
            Element.row [ Element.alignRight, Element.spacing 10 ]
                [ deleteImageBtn, createServerBtn ]

        size =
            case imageRecord.image.size of
                Just s ->
                    let
                        { locale } =
                            context

                        ( count, units ) =
                            humanNumber { locale | decimals = Exact 2 } Bytes s
                    in
                    count ++ " " ++ units

                Nothing ->
                    "unknown size"

        featuredIcon =
            if imageRecord.featured then
                FeatherIcons.award
                    |> FeatherIcons.withSize 20
                    |> FeatherIcons.toHtml []
                    |> Element.html
                    |> Element.el
                        [ Element.htmlAttribute <| HtmlA.title "Featured"
                        ]

            else
                Element.none

        ownerText =
            if imageRecord.owned then
                Element.text <| " belongs to this " ++ context.localization.unitOfTenancy

            else
                Element.none

        imageTags =
            Element.none
    in
    Element.column
        (listItemColumnAttribs context.palette)
        [ Element.row [ Element.width Element.fill, Element.spacing 10 ]
            [ Element.el
                [ Font.size 18
                , Font.color (SH.toElementColor context.palette.on.background)
                ]
                (Element.text imageRecord.image.name)
            , featuredIcon
            , imageActions
            ]
        , Element.row [ Element.width Element.fill, Element.spacing 8 ]
            [ Element.text size
            , Element.text "·"
            , Element.row []
                [ Element.el [ Font.color (SH.toElementColor context.palette.on.background) ]
                    (Element.text <| String.toLower <| OSTypes.imageVisibilityToString imageRecord.image.visibility)
                , Element.text <| " " ++ context.localization.staticRepresentationOfBlockDeviceContents
                , ownerText
                ]
            , imageTags
            ]
        ]


filters : List (DataList.Filter record)
filters =
    []
