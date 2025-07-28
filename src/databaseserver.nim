import std/[tables]
import dimscord
import typedefs, databaseprocs


# Change settings:
proc changeChannelSetting*(guild_id, channel_id, task: string): DbResult =
    var server: ServerDataObject = dbGetServer(guild_id)
    server.channels[task] = channel_id
    result = dbServerSaveChannels(server)

proc changeChannelSetting*(guild_id, channel_id: string, task: ServerSettingChannelOption): DbResult =
    return changeChannelSetting(guild_id, channel_id, $task)
proc changeChannelSetting*(guild_id: string, channel: Channel, task: ServerSettingChannelOption): DbResult =
    return changeChannelSetting(guild_id, $channel.id, $task)

proc changeChannelSetting*(guild: Guild, channel_id: string, task: ServerSettingChannelOption): DbResult =
    return changeChannelSetting(guild.id, channel_id, $task)
proc changeChannelSetting*(guild: Guild, channel: Channel, task: ServerSettingChannelOption): DbResult =
    return changeChannelSetting(guild.id, $channel.id, $task)
