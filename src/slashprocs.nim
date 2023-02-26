import strutils, strformat, options, asyncdispatch, tables
from unicode import capitalize
import dimscord
import typedefs, configfile

using
    s: Shard
    i: Interaction

proc sendErrorMessage*(s, i; error: ErrorType, message: string = "An unknown error occured."): Future[SlashResponse] {.async.} =
    return SlashResponse(
        embeds: @[Embed(
            title: some &"{($error).toLower().capitalize()} Error",
            description: some message,
            color: some EmbedColour.error
        )]
    )


# Slash Command Procs:

proc helpSlash*(s, i): Future[SlashResponse] {.async.} =
    let p: string = $config.prefix
    return SlashResponse(
        content: &"My prefix is `{p}` and you can get a list of all commands with `{p}help`." &
            &"To see detailed documentation about a command, use `{p}docs`!"
    )

proc echoSlash*(s, i): Future[SlashResponse] {.async.} =
    let data = i.data.get()
    return SlashResponse(
        content: data.options["message"].str
    )

