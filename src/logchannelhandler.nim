import strutils, asyncdispatch, tables, options
import dimscord
import typedefs, serverdatahandler

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
    let server: ServerDataObject = guild_id.getServerData()
    if server.channels.isNone(): return
    let channels = server.channels.get()

    # Handle event and send message to channel:
    case eventType:
    of messageDelete, messageUpdate:
        if not channels.hasKey($settingMessageLogging): return
        discard dispatchLogMessage(channels[$settingMessageLogging], m)

    of memberJoin, memberLeave:
        if not channels.hasKey($settingWelcomeMessages): return
        discard dispatchLogMessage(channels[$settingWelcomeMessages], m)

    of memberUpdate:
        if not channels.hasKey($settingUserChanges): return
        discard dispatchLogMessage(channels[$settingUserChanges], m)
