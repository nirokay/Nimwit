import asyncdispatch, strutils
import dimscord

type
    Config* = object
        prefix*: string
        rollCommandLimit*: int
    
    ErrorType* = enum
        SYNTAX, LOGICAL, VALUE

    CommandCategory* = enum
        UNDEFINED, SYSTEM, SOCIAL, MATH, FUN

    Command* = object
        name*: string
        desc*: string

        category*: CommandCategory
        alias*: seq[string]
        usage*: seq[string]

        call*: proc(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.}


var CommandList* {.global.}: seq[Command]


# Discord:
import tokenhandler
setDiscordToken()
let discord* = newDiscordClient(getDiscordToken().strip())

export discord
