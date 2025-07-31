import strutils, asyncdispatch, tables, options
import dimscord
import typedefs, databaseprocs

using
    s: Shard
    m: Message
    i: Interaction

type
    LogEvent* = enum
        messageDelete, messageUpdate,
        memberJoin, memberLeave, memberUpdate
    LogMessage* = object
        content*: string
        attachments*: seq[Attachment]
        embeds*: seq[Embed]


proc dispatchLogMessage*(channel_id: string, m: LogMessage): Future[Message] {.async.} =
    return await discord.api.sendMessage(
        channel_id,
        m.content,
        embeds = m.embeds,
        attachments = m.attachments
    )

proc sendLogMessage*(guild_id: string, eventType: LogEvent, m: LogMessage) =
    let server: ServerDataObject = dbGetServer(guild_id)
    if $server.channels == "{:}": return
    let channels = server.channels

    # Handle event and send message to channel:
    case eventType:
    of messageDelete, messageUpdate:
        if not channels.hasKey($channelMessageLogging): return
        discard dispatchLogMessage(channels[$channelMessageLogging], m)

    of memberJoin, memberLeave:
        if not channels.hasKey($channelWelcomeMessages): return
        discard dispatchLogMessage(channels[$channelWelcomeMessages], m)

    of memberUpdate:
        if not channels.hasKey($channelUserChanges): return
        discard dispatchLogMessage(channels[$channelUserChanges], m)
