import strutils, strformat, options, asyncdispatch, tables
from unicode import capitalize
import dimscord
import typedefs, configfile, serverdatahandler

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

# -------------------------------------------------
# System:
# -------------------------------------------------

proc helpSlash*(s, i): Future[SlashResponse] {.async.} =
    let p: string = $config.prefix
    return SlashResponse(
        content: &"My prefix is `{p}` and you can get a list of all commands with `{p}help`." &
            &"To see detailed documentation about a command, use `{p}docs`!"
    )

# Settings:
proc displaySettingsSlash*(s, i): Future[SlashResponse] {.async.} =
    var serverdata: string
    try:
        serverdata = getServerDataAsJson(i.guild_id.get())
    except KeyError:
        return await sendErrorMessage(s, i, VALUE, "This server has no data saved. Try modifying settings first.")

    # Send message:
    var embed = Embed(
        title: some "Settings for this server in json",
        description: some &"```json\n{serverdata}\n```"
    )
    return SlashResponse(
        embeds: @[embed]
    )

proc modifySettingSlash*(s, i): Future[SlashResponse] {.async.} =
    #return await sendErrorMessage(s, i, USAGE, "testing")
    let
        data = i.data.get()
        guild_id = i.guild_id.get()
        channel_id = i.channel_id.get()
        task: string = data.options["task"].str
    
    let success: (bool, string) = changeChannelSetting(guild_id, channel_id, task)
    if not success[0]:
        return await sendErrorMessage(s, i, INTERNAL, success[1])
    return SlashResponse(
        content: success[1]
    )


# -------------------------------------------------
# Chatting stuff:
# -------------------------------------------------

proc echoSlash*(s, i): Future[SlashResponse] {.async.} =
    let data = i.data.get()
    return SlashResponse(
        content: data.options["message"].str
    )

