import os, strutils, asyncdispatch
import dimscord
import typedefs, configfile


# Initialize commands:
include commanddefs


# General bot procedures:
proc attemptCommandExecution(s: Shard, m: Message): bool =
    if m.author.bot: return false
    if m.content.len < config.prefix.len: return false

    # Check for prefix:
    if not m.content.startsWith(config.prefix): return false

    # Clean up args:
    let rawArgs: seq[string] = m.content.strip().split(" ")
    var tempArgs: seq[string] = rawArgs
    tempArgs[0] = tempArgs[0].toLower()
    tempArgs[0].delete(0..(len(config.prefix)-1))
    let args = tempArgs

    # Find and call command:
    let request = args[0]
    echo request
    for command in CommandList:
        if command.name == request: command.call(s, m, args); return true
        for alias in command.alias:
            if alias == request: command.call(s, m, args); return true
    
    # No command found:
    return false


# Discord events:
proc onReady(s: Shard, r: Ready) {.event(discord).} =
    echo "Ready as " & $r.user & " in " & $r.guilds.len & " guilds!"

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
    discard attemptCommandExecution(s, m)


# Connect to discord:
waitFor discord.startSession(
    gateway_intents = {giGuildMessages, giGuilds, giGuildMembers, giMessageContent}
)

