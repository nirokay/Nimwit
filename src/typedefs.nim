import strutils
import dimscord
import tokenhandler

type
    Config* = object
        prefix*: string

    Command* = object
        name*: string
        alias*: seq[string]
        desc*: string

        call*: proc(s: Shard, m: Message, args: seq[string])


var CommandList* {.global.}: seq[Command]


# Discord:
setDiscordToken()
let discord* {.global.} = newDiscordClient(getDiscordToken().strip())
