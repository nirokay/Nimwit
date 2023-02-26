import os, asyncdispatch, strutils, strformat, options, tables, json
import dimscord, pixie

type
    # ---------------------------------------------------------------------------------------
    # Config and Files
    # ---------------------------------------------------------------------------------------

    DataLocationEnum* = enum
        fileHelloList, fileUsers, fileSocialGifs,
        fileYesNoMaybe, fileInfo, fileImgTemplate,

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

    SlashResponse* = InteractionCallbackDataMessage
    SlashOption* = ApplicationCommandOption
    SlashCommand* = object of CommandTemplate
        specialPermission*: bool
        permissions*: seq[PermissionFlags]
        kind*: ApplicationCommandType
        options*: seq[SlashOption]
        call*: proc(s: Shard, i: Interaction): Future[SlashResponse] {.async.}

    SubstringReaction* = object    
        trigger*: seq[string]
        probability*: float
        caseSensitive*: bool

        emoji*, response*: string

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


# Directories:
const dirs: seq[string] = @[
    "private",
        "private/logs", "private/data"
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
    DataLocation* {.global.} = {
        fileHelloList:   "public/hello_list.json",
        fileUsers:       "private/data/users.json",
        fileSocialGifs:  "public/social_gifs.json",
        fileYesNoMaybe:  "public/yes_no_maybe_responses.json",
        fileInfo:        "public/info.json",
        fileImgTemplate: "public/image_template_list.json",

        fontDefault:          "public/font/DejaVuSans.ttf",
        fontDefaultBold:      "public/font/DejaVuSans-Bold.ttf",
        fontDefaultSerif:     "public/font/DejaVuSerif.ttf",
        fontDefaultSerifBold: "public/font/DejaVuSerif-Bold.ttf",
        fontPapyrus:          "public/font/PAPYRUS.ttf",

        dirImageTemplates: "public/image_templates/",
        dirCache:          "private/cache/",
        dirLogs:           "private/logs/"
    }.toTable

    # Init from json files:
    ImageTemplateList* {.global.} = initListFromJson[seq[ImageTemplate]](DataLocation[fileImgTemplate])


# Getter for file location:
proc getLocation*(file: DataLocationEnum): string =
    if not DataLocation.hasKey(file): return ""
    return DataLocation[file]

proc getFontLocation*(file: DataLocationEnum | string): string =
    # I cheated around to make "string == enum", it's ugly but works :)
    var font: string = DataLocation[fontDefault]
    for fontEnum, location in pairs(DataLocation):
        if $fontEnum == $file: return location
    return font

