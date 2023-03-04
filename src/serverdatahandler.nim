import os, json, tables, strutils, strformat, options
import dimscord
import typedefs, logger

var ServerData: Table[string, ServerDataObject]
let filepath: string = getLocation(fileServers)

# Create server data file:
proc createServerDataFile() =
    writeFile(getLocation(fileServers), "{}")

proc writeServerData(): bool =
    var stringJson: string
    stringJson.toUgly(%*ServerData)

    try:
        writeFile(filepath, stringJson)
    except IOError as e:
        logger e
        return false
    return true

proc verifyServerIdExists(guild_id: string) =
    if not ServerData.hasKey(guild_id):
        ServerData[guild_id] = ServerDataObject(
            id: guild_id
        )
        discard writeServerData()


# Fetch data:
proc getServerData(): Table[string, ServerDataObject] =
    if not filepath.fileExists(): createServerDataFile()
    result = readFile(filepath).parseJson().to(Table[string, ServerDataObject])

    ServerData = result
    return result

proc getServerDataObject(guild_id: string): ServerDataObject =
    verifyServerIdExists(guild_id)
    return ServerData[guild_id]

proc loadServerData*() =
    discard getServerData()

proc getServerData*(guild_id: string): ServerDataObject =
    guild_id.verifyServerIdExists()
    loadServerData()
    return ServerData[guild_id]

proc getServerDataAsJson*(guild_id: string): string =
    guild_id.verifyServerIdExists()
    loadServerData()

    let serverdata: ServerDataObject = ServerData[guild_id]
    return pretty(%*serverdata, 2)

# Writing to disk:
proc overrideServer(id: string, server: ServerDataObject): bool =
    ServerData[id] = server
    return writeServerData()

# Change settings:
proc changeChannelSetting*(guild_id, channel_id, task: string): (bool, string) =
    verifyServerIdExists(guild_id)
    var
        server = guild_id.getServerDataObject()
        channels: Table[string, string]

    # Change settings:
    if server.channels.isNone(): server.channels = some channels
    var temp: Table[string, string] = server.channels.get()
    temp[task] = channel_id
    server.channels = some temp

    # Save to disk:
    let success: bool = overrideServer(guild_id, server)
    if not success: return (false, "Could not save settings to disk. Please try again later...")
    return (true, &"Successfully linked <#{channel_id}> to task '{task}'!")

# Public settings changer for added security (i will 100% mistype the task as a string...):
proc changeChannelSetting*(guild_id, channel_id: string, task: ServerSettingChannelOption): (bool, string) =
    return changeChannelSetting(guild_id, channel_id, $task)
proc changeChannelSetting*(guild_id: string, channel: objects.Channel, task: ServerSettingChannelOption): (bool, string) =
    return changeChannelSetting(guild_id, $channel.id, $task)
