import asyncdispatch, strutils, options, tables, json
import dimscord, pixie

type
    DataLocation* = enum
        fileHelloList, fileGoodies, fileSocialGifs, fileYesNoMaybe,
        fontDefault, fontPapyrus
        dirCache, dirLogs, dirImageTemplates

    Config* = object
        prefix*: string
        fileLocations*: Table[DataLocation, string]
        rollCommandLimit*: int

    ErrorType* = enum
        SYNTAX, LOGICAL, VALUE, PERMISSION, USAGE, INTERNAL

    CommandCategory* = enum
        UNDEFINED, SYSTEM, SOCIAL, MATH, FUN, CHATTING

    Command* = object
        name*, desc*: string
        category*: CommandCategory
        alias*, usage*: seq[string]

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


# Discord:
import tokenhandler
setDiscordToken()
let discord* = newDiscordClient(getDiscordToken().strip())
export discord


# Init Global Lists:
proc initListFromJson[T](filepath: string): seq[T] =
    return readFile(filepath).parseJson().to(seq[T])

# Global Lists:
var
    CommandList* {.global.}: seq[Command]
    SubstringReactionList* {.global.}: seq[SubstringReaction]
    ImageTemplateList* {.global.}: seq[ImageTemplate] = initListFromJson[ImageTemplate]("public/image_template_list.json")


# Global type procs:
proc reactToMessage*(substring: SubstringReaction, s: Shard, m: Message): Future[system.void] {.async.} =
    if substring.emoji != "":
        discard discord.api.addMessageReaction(
            m.channel_id,
            m.id,
            substring.emoji
        )
    if substring.response != "":
        discard await discord.api.sendMessage(
            m.channel_id,
            substring.response
        )



