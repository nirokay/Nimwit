import os, asyncdispatch, strutils, strformat, options, tables, json
import dimscord, pixie

type
    # ---------------------------------------------------------------------------------------
    # Config and Files
    # ---------------------------------------------------------------------------------------

    DataLocationEnum* = enum
        fileServers, fileUsers,

        fileSocialGifs, fileYesNoMaybe, fileImgTemplate,
        fileHelloList, fileInfo, fileJoinLeaveText, fileCoinFlip, fileUnitConversions

        fontDefault, fontDefaultBold, fontDefaultSerif,
        fontDefaultSerifBold, fontPapyrus,

        dirImageTemplates, dirCache, dirLogs

    Config* = object
        prefix*: string
        moneyGainPerMessage*: int
        rollCommandLimit*: int


    # ---------------------------------------------------------------------------------------
    # Commands
    # ---------------------------------------------------------------------------------------

    EmbedColoursConfig* = object
        error*, warning*, success*, default*: int

    ErrorType* = enum
        SYNTAX, LOGICAL, VALUE, PERMISSION, USAGE, INTERNAL

    CommandCategory* = enum
        UNDEFINED, SYSTEM, SOCIAL, MATH, FUN, CHATTING, ECONOMY

    CommandTemplate = object of RootObj
        name*, desc*: string

        category*: CommandCategory
        examples*: seq[string]

        serverOnly*: bool

    Command* = object of CommandTemplate
        alias*, usage*: seq[string]
        hidden*: bool
        call*: proc(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.}

    SlashData* = ApplicationCommandInteractionData
    SlashResponse* = InteractionCallbackDataMessage
    SlashOption* = ApplicationCommandOption
    SlashChoice* = ApplicationCommandOptionChoice
    SlashCommand* = object of CommandTemplate
        permissions*: Option[seq[PermissionFlags]]
        kind*: ApplicationCommandType
        options*: seq[SlashOption]
        call*: proc(s: Shard, i: Interaction): Future[SlashResponse] {.async.}

    SubstringReaction* = object
        trigger*: seq[string]
        probability*: float
        caseSensitive*: bool

        emoji*, response*: string


    # ---------------------------------------------------------------------------------------
    # Data Stuff
    # ---------------------------------------------------------------------------------------

    BotInfoObject = object
        name*, repository*, issues*: string

    ImageTemplate* = object
        name*, filename*: string
        alias*: seq[string]
        textbox*: array[2, array[2, float32]]
        fontsize*: float32
        rgb*: array[3, float32]
        font*: string

    UserDataObject* = object
        id*: string
        money*: Option[int]
        lastDailyReward*: Option[int]
        currentDailyStreak*: Option[int]

    ServerSettingChannelOption* = enum
        settingWelcomeMessages, settingMessageLogging, settingUserChanges

    ServerDataObject* = object
        id*: string
        channels*: Option[Table[string, string]]

    CoinFlipObject* = object
        headsUrl*, tailsUrl*: string

    Unit* = object
        name*: string
        default*: Option[bool]
        multiplicator*: float
        adder*: Option[float]
    UnitConversion* = Table[string, Unit]
    UnitConversionList* = Table[string, UnitConversion]

# Directories:
const dirs: seq[string] = @[
    "private",
        "private/logs", "private/data", "private/cache"
]
for dir in dirs:
    if not dirExists(dir):
        echo &"Creating directory: '{dir}'"
        createDir(dir)


# Discord:
import tokenhandler
setDiscordToken()
let discord* = newDiscordClient(getDiscordToken().strip())
export discord


# Init Global Lists from json files:
proc initListFromJson[T](filepath: string): T =
    try:
        return readFile(filepath).parseJson().to(T)
    except Exception as e:
        echo &"While loading from json at '{filepath}': *{e.name}*\n-----\n{e.msg}\n-----"


# Global Lists:
var
    CommandList* {.global.}: seq[Command]
    SlashCommandList* {.global.}: seq[SlashCommand]
    SubstringReactionList* {.global.}: seq[SubstringReaction]

let
    DataLocation* {.global.}: Table[DataLocationEnum, string] = toTable {
        fileServers: "private/data/servers.json",
        fileUsers:   "private/data/users.json",

        fileHelloList:       "public/helloList.json",
        fileSocialGifs:      "public/socialGifs.json",
        fileYesNoMaybe:      "public/yesNoMaybeResponses.json",
        fileJoinLeaveText:   "public/memberJoinLeave.json",
        fileInfo:            "public/info.json",
        fileImgTemplate:     "public/imageTemplateList.json",
        fileCoinFlip:        "public/coinFlip.json",
        fileUnitConversions: "public/unitConversion.json",

        fontDefault:          "public/font/DejaVuSans.ttf",
        fontDefaultBold:      "public/font/DejaVuSans-Bold.ttf",
        fontDefaultSerif:     "public/font/DejaVuSerif.ttf",
        fontDefaultSerifBold: "public/font/DejaVuSerif-Bold.ttf",
        fontPapyrus:          "public/font/PAPYRUS.ttf",

        dirImageTemplates: "public/image_templates/",
        dirCache:          "private/cache/",
        dirLogs:           "private/logs/"
    }

    # Init from json files:
    BotInfo* {.global.} = initListFromJson[BotInfoObject](DataLocation[fileInfo])
    ImageTemplateList* {.global.} = initListFromJson[seq[ImageTemplate]](DataLocation[fileImgTemplate])
    MemberJoinLeaveText* {.global.} = initListFromJson[Table[string, seq[string]]](DataLocation[fileJoinLeaveText])
    CoinFlip* {.global.} = initListFromJson[CoinFlipObject](DataLocation[fileCoinFlip])
    UnitConversions* {.global.} = initListFromJson[UnitConversionList](DataLocation[fileUnitConversions])

# Getter for file location:
proc getLocation*(file: DataLocationEnum): string =
    if not DataLocation.hasKey(file): return ""
    return DataLocation[file]

# Cheeky cheats for json:
proc getFontLocation*(file: DataLocationEnum | string): string =
    # I cheated around to make "string == enum", it's ugly but works :)
    var font: string = DataLocation[fontDefault]
    for fontEnum, location in pairs(DataLocation):
        if $fontEnum == $file: return location
    return font
