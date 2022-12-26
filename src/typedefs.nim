import asyncdispatch, strutils, options, tables
import dimscord

type
    DataLocation* = enum
        fileHelloList, fileGoodies, fileSocialGifs, fileYesNoMaybe,
        dirLogs

    Config* = object
        prefix*: string
        fileLocations*: Table[DataLocation, string]
        rollCommandLimit*: int

    ErrorType* = enum
        SYNTAX, LOGICAL, VALUE, PERMISSION, USAGE, INTERNAL

    CommandCategory* = enum
        UNDEFINED, SYSTEM, SOCIAL, MATH, FUN, CHATTING

    Command* = object
        name*: string
        desc*: string

        category*: CommandCategory
        alias*: seq[string]
        usage*: seq[string]

        hidden*: bool
        serverOnly*: bool
        permissions*: seq[PermissionFlags]

        call*: proc(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.}
    
    SubstringReactionCategory* = enum
        EmojiReaction, MessageResponse

    SubstringReaction* = object    
        trigger*: seq[string]
        probability*: float
        caseSensitive*: bool

        emoji*: string
        response*: string


# Discord:
import tokenhandler
setDiscordToken()
let discord* = newDiscordClient(getDiscordToken().strip())
export discord


# Global Lists:
var CommandList* {.global.}: seq[Command]
var SubstringReactionList* {.global.}: seq[SubstringReaction]


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



