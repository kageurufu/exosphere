module Types.Types exposing
    ( CockpitLoginStatus(..)
    , CreateServerField(..)
    , CreateServerRequest
    , Endpoints
    , ExoServerProps
    , Flags
    , FloatingIpState(..)
    , GlobalDefaults
    , HttpRequestMethod(..)
    , IPInfoLevel(..)
    , LoginField(..)
    , Model
    , Msg(..)
    , NewServerNetworkOptions(..)
    , NonProjectViewConstructor(..)
    , OpenstackCreds
    , PasswordVisibility(..)
    , Project
    , ProjectIdentifier
    , ProjectName
    , ProjectSpecificMsgConstructor(..)
    , ProjectTitle
    , ProjectViewConstructor(..)
    , Server
    , ServerUiStatus(..)
    , VerboseStatus
    , ViewState(..)
    , ViewStateParams
    , WindowSize
    )

import Http
import Json.Decode as Decode
import OpenStack.Types as OSTypes
import RemoteData exposing (WebData)
import Time
import Toasty
import Toasty.Defaults
import Types.HelperTypes as HelperTypes



{- App-Level Types -}


type alias Flags =
    { width : Int
    , height : Int
    , storedState : Maybe Decode.Value
    , proxyUrl : Maybe HelperTypes.Url
    , isElectron : Bool
    }


type alias WindowSize =
    { width : Int
    , height : Int
    }


type alias Model =
    { messages : List String
    , viewState : ViewState
    , maybeWindowSize : Maybe WindowSize
    , projects : List Project
    , creds : OpenstackCreds
    , imageFilterTag : Maybe String
    , globalDefaults : GlobalDefaults
    , toasties : Toasty.Stack Toasty.Defaults.Toast
    , proxyUrl : Maybe HelperTypes.Url
    , isElectron : Bool
    }


type alias GlobalDefaults =
    { shellUserData : String
    }


type alias Project =
    { creds : OpenstackCreds
    , auth : OSTypes.AuthToken
    , endpoints : Endpoints
    , images : List OSTypes.Image
    , servers : WebData (List Server)
    , flavors : List OSTypes.Flavor
    , keypairs : List OSTypes.Keypair
    , volumes : WebData (List OSTypes.Volume)
    , networks : List OSTypes.Network
    , floatingIps : List OSTypes.IpAddress
    , ports : List OSTypes.Port
    , securityGroups : List OSTypes.SecurityGroup
    , pendingCredentialedRequests : List (OSTypes.AuthTokenString -> Cmd Msg) -- Requests waiting for a valid auth token
    }


type alias ProjectIdentifier =
    -- We use this when referencing a Project in a Msg (or otherwise passing through the runtime)
    { name : ProjectName
    , authUrl : HelperTypes.Url
    }


type alias Endpoints =
    { cinder : HelperTypes.Url
    , glance : HelperTypes.Url
    , nova : HelperTypes.Url
    , neutron : HelperTypes.Url
    }


type Msg
    = Tick Time.Posix
    | SetNonProjectView NonProjectViewConstructor
    | RequestNewProjectToken
    | ReceiveAuthToken OpenstackCreds (Result Http.Error ( Http.Metadata, String ))
    | ProjectMsg ProjectIdentifier ProjectSpecificMsgConstructor
    | InputLoginField LoginField
    | InputCreateServerField CreateServerRequest CreateServerField
    | InputImageFilterTag String
    | OpenInBrowser String
    | OpenNewWindow String
    | RandomPassword Project String
    | ToastyMsg (Toasty.Msg Toasty.Defaults.Toast)
    | MsgChangeWindowSize Int Int


type ProjectSpecificMsgConstructor
    = SetProjectView ProjectViewConstructor
    | ValidateTokenForCredentialedRequest (OSTypes.AuthTokenString -> Cmd Msg) Time.Posix
    | RemoveProject
    | SelectServer Server Bool
    | SelectAllServers Bool
    | RequestServers
    | RequestServer OSTypes.ServerUuid
    | RequestCreateServer CreateServerRequest
    | RequestDeleteServer Server
    | RequestDeleteServers (List Server)
    | RequestServerAction Server (Project -> Maybe HelperTypes.Url -> Server -> Cmd Msg) (List OSTypes.ServerStatus)
    | RequestCreateVolume OSTypes.VolumeName OSTypes.VolumeSize
    | RequestDeleteVolume OSTypes.VolumeUuid
    | RequestAttachVolume OSTypes.ServerUuid OSTypes.VolumeUuid
    | RequestDetachVolume OSTypes.VolumeUuid
    | ReceiveImages (Result Http.Error (List OSTypes.Image))
    | ReceiveServers (Result Http.Error (List OSTypes.Server))
    | ReceiveServer OSTypes.ServerUuid (Result Http.Error OSTypes.ServerDetails)
    | ReceiveConsoleUrl OSTypes.ServerUuid (Result Http.Error OSTypes.ConsoleUrl)
    | ReceiveCreateServer (Result Http.Error OSTypes.ServerUuid)
    | ReceiveDeleteServer OSTypes.ServerUuid (Maybe OSTypes.IpAddressValue) (Result Http.Error String)
    | ReceiveFlavors (Result Http.Error (List OSTypes.Flavor))
    | ReceiveKeypairs (Result Http.Error (List OSTypes.Keypair))
    | ReceiveNetworks (Result Http.Error (List OSTypes.Network))
    | ReceiveFloatingIps (Result Http.Error (List OSTypes.IpAddress))
    | GetFloatingIpReceivePorts OSTypes.ServerUuid (Result Http.Error (List OSTypes.Port))
    | ReceiveCreateFloatingIp OSTypes.ServerUuid (Result Http.Error OSTypes.IpAddress)
    | ReceiveDeleteFloatingIp OSTypes.IpAddressUuid (Result Http.Error String)
    | ReceiveSecurityGroups (Result Http.Error (List OSTypes.SecurityGroup))
    | ReceiveCreateExoSecurityGroup (Result Http.Error OSTypes.SecurityGroup)
    | ReceiveCreateExoSecurityGroupRules (Result Http.Error String)
    | ReceiveCockpitLoginStatus OSTypes.ServerUuid (Result Http.Error String)
    | ReceiveServerAction OSTypes.ServerUuid (Result Http.Error String)
    | ReceiveCreateVolume (Result Http.Error OSTypes.Volume)
    | ReceiveVolumes (Result Http.Error (List OSTypes.Volume))
    | ReceiveDeleteVolume (Result Http.Error String)
    | ReceiveAttachVolume (Result Http.Error OSTypes.VolumeAttachment)
    | ReceiveDetachVolume (Result Http.Error String)


type ViewState
    = NonProjectView NonProjectViewConstructor
    | ProjectView ProjectIdentifier ProjectViewConstructor


type NonProjectViewConstructor
    = Login
    | MessageLog
    | HelpAbout


type ProjectViewConstructor
    = ListImages
    | ListProjectServers
    | ListProjectVolumes
    | ServerDetail OSTypes.ServerUuid ViewStateParams
    | VolumeDetail OSTypes.VolumeUuid
    | CreateServer CreateServerRequest
    | CreateVolume OSTypes.VolumeName String
    | AttachVolumeModal (Maybe OSTypes.ServerUuid) (Maybe OSTypes.VolumeUuid)
    | MountVolInstructions OSTypes.VolumeAttachment


type alias ViewStateParams =
    { verboseStatus : VerboseStatus
    , passwordVisibility : PasswordVisibility
    , ipInfoLevel : IPInfoLevel
    }


type IPInfoLevel
    = IPDetails
    | IPSummary


type alias VerboseStatus =
    Bool


type PasswordVisibility
    = PasswordShown
    | PasswordHidden


type LoginField
    = AuthUrl String
    | ProjectDomain String
    | ProjectName String
    | UserDomain String
    | Username String
    | Password String
    | OpenRc String


type CreateServerField
    = CreateServerName String
    | CreateServerCount String
    | CreateServerUserData String
    | CreateServerShowAdvancedOptions Bool
    | CreateServerSize String
    | CreateServerKeypairName String
    | CreateServerVolBacked Bool
    | CreateServerVolBackedSize String
    | CreateServerNetworkUuid OSTypes.NetworkUuid


type alias OpenstackCreds =
    { authUrl : String
    , projectDomain : String
    , projectName : String
    , userDomain : String
    , username : String
    , password : String
    }



-- Resource-Level Types


type alias ExoServerProps =
    { floatingIpState : FloatingIpState
    , selected : Bool
    , cockpitStatus : CockpitLoginStatus
    , deletionAttempted : Bool
    , targetOpenstackStatus : Maybe (List OSTypes.ServerStatus) -- Maybe we have performed an instance action and are waiting for server to reflect that
    }


type alias Server =
    { osProps : OSTypes.Server
    , exoProps : ExoServerProps
    }


type FloatingIpState
    = Unknown
    | NotRequestable
    | Requestable
    | RequestedWaiting
    | Success
    | Failed


type CockpitLoginStatus
    = NotChecked
    | CheckedNotReady
    | Ready


type ServerUiStatus
    = ServerUiStatusUnknown
    | ServerUiStatusBuilding
    | ServerUiStatusPartiallyActive
    | ServerUiStatusReady
    | ServerUiStatusPaused
    | ServerUiStatusReboot
    | ServerUiStatusSuspended
    | ServerUiStatusShutoff
    | ServerUiStatusStopped
    | ServerUiStatusSoftDeleted
    | ServerUiStatusError
    | ServerUiStatusRescued
    | ServerUiStatusShelved


type alias CreateServerRequest =
    { name : String
    , projectId : ProjectIdentifier
    , imageUuid : OSTypes.ImageUuid
    , imageName : String
    , count : String
    , flavorUuid : OSTypes.FlavorUuid
    , volBacked : Bool
    , volBackedSizeGb : String
    , keypairName : Maybe String
    , userData : String
    , exouserPassword : String
    , networkUuid : OSTypes.NetworkUuid
    , showAdvancedOptions : Bool
    }


type alias ProjectName =
    String


type alias ProjectTitle =
    String


type NewServerNetworkOptions
    = NoNetsAutoAllocate
    | OneNet OSTypes.Network
    | MultipleNetsWithGuess (List OSTypes.Network) OSTypes.Network GoodGuess


type alias GoodGuess =
    Bool



-- REST Types


type HttpRequestMethod
    = Get
    | Post
    | Delete
