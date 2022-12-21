import strutils, asyncdispatch
import dimscord
import typedefs, configfile

# Initialize commands:
include commanddefs

# General bot procedures:
proc attemptCommandExecution(s: Shard, m: Message, args: seq[string]): bool =
    let request = args[0]
    echo request

    # Search for matching command:
    for command in CommandList:
        # Check for command name:
        if command.name == request:
            discard command.call(s, m, args)
            return true

        # Check for command alias name:
        for alias in command.alias:
            if alias == request:
                discard command.call(s, m, args)
                return true
    return false

proc handleCommandCall(s: Shard, m: Message): bool =
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

    # Attempt command execution:
    discard attemptCommandExecution(s, m, args)


# Discord events:
proc onReady(s: Shard, r: Ready) {.event(discord).} =
    echo "Ready as " & $r.user & " in " & $r.guilds.len & " guilds!"

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
    discard handleCommandCall(s, m)


# Connect to discord:
waitFor discord.startSession(
    gateway_intents = {giGuildMessages, giGuilds, giGuildMembers, giMessageContent}
)

