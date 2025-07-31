import std/[strformat, tables]
import dimscord
import typedefs, databaseprocs, utils


# Change settings:
proc changeChannelSetting*(guild_id, channel_id, task: string): DbResult =
    var server: ServerDataObject = dbGetServer(guild_id)
    server.channels[task] = channel_id
    result = dbServerSaveChannels(server)
    result.reason = &"Successfully linked {channel_id.mentionChannel()} to task '{task}'"

proc changeChannelSetting*(guild_id, channel_id: string, task: ServerSettingChannelOption): DbResult =
    return changeChannelSetting(guild_id, channel_id, $task)
proc changeChannelSetting*(guild_id: string, channel: dimscord.Channel, task: ServerSettingChannelOption): DbResult =
    return changeChannelSetting(guild_id, $channel.id, $task)

proc changeChannelSetting*(guild: Guild, channel_id: string, task: ServerSettingChannelOption): DbResult =
    return changeChannelSetting(guild.id, channel_id, $task)
proc changeChannelSetting*(guild: Guild, channel: dimscord.Channel, task: ServerSettingChannelOption): DbResult =
    return changeChannelSetting(guild.id, $channel.id, $task)
