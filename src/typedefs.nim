import os, asyncdispatch, strutils, strformat, options, tables, json
import dimscord, pixie

type
    DataLocation* = enum
        fileHelloList =   "public/hello_list.json"
        fileUsers =       "private/data/users.json"
        fileSocialGifs =  "public/social_gifs.json"
        fileYesNoMaybe =  "public/yes_no_maybe_responses.json"
        fileInfo =        "public/info.json"
        fileImgTemplate = "public/image_template_list.json"

        fontDefault =          "public/font/DejaVuSans.ttf"
        fontDefaultBold =      "public/font/DejaVuSans-Bold.ttf"
        fontDefaultSerif =     "public/font/DejaVuSerif.ttf"
        fontDefaultSerifBold = "public/font/DejaVuSerif-Bold.ttf"
        fontPapyrus =          "public/font/PAPYRUS.ttf"

        dirImageTemplates = "public/image_templates/"
        dirCache =          "private/cache/"
        dirLogs =           "private/logs/"

    Config* = object
        prefix*: string
        moneyGainPerMessage*: float
        rollCommandLimit*: int

    ErrorType* = enum
        SYNTAX, LOGICAL, VALUE, PERMISSION, USAGE, INTERNAL

    CommandCategory* = enum
        UNDEFINED, SYSTEM, SOCIAL, MATH, FUN, CHATTING, ECONOMY

    Command* = object
        name*, desc*: string
        category*: CommandCategory
        alias*, usage*, examples*: seq[string]

        hidden*, serverOnly*: bool
        permissions*: seq[PermissionFlags]
        call*: proc(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.}

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
        font*: DataLocation

    EmbedColoursConfig* = object
        error*, warning*, success*, default*: int
    
    UserDataObject* = object
        id*: string
        money*: Option[int]


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


# Init Global Lists:
proc initListFromJson[T](filepath: string): seq[T] =
    try:
        return readFile(filepath).parseJson().to(seq[T])
    except Exception as e:
        echo &"While loading from json at '{filepath}': *{e.name}*\n-----\n{e.msg}\n-----"

# Global Lists:
var
    CommandList* {.global.}: seq[Command]
    SubstringReactionList* {.global.}: seq[SubstringReaction]
    ImageTemplateList* {.global.}: seq[ImageTemplate] = initListFromJson[ImageTemplate]($fileImgTemplate)

