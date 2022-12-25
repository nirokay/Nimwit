import strutils, asyncdispatch, options
import dimscord
import typedefs, configfile

# Initialize commands:
include commanddefs

# General bot procedures:
proc callCommand(command: Command, s: Shard, m: Message, args: seq[string]): bool =
    # Check for server-only commands being run outside servers:
    if not m.member.isSome and command.serverOnly:
        discard sendErrorMessage(m, USAGE, "You have to use this command on a server.")
        return false

    # TODO Implement this correctly (currently disabled)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Check for permissions when send on servers:
    if m.member.isSome and false:
        for needsPerm in command.permissions:
            echo "Checking " & $needsPerm & " on " & $command.permissions & "\nUser has: " & $m.member.get.permissions
            if contains(m.member.get.permissions, needsPerm): continue
            discard sendErrorMessage(m, PERMISSION, "You need permission `" & $needsPerm & "` to use this command.")
            return false

    # Call command and return success:
    try:
        discard command.call(s, m, args)
    except Exception:
        echo "An error occured!\n" & getCurrentExceptionMsg()
        discard sendErrorMessage(m, INTERNAL, "An error occured whilst performing this request. Please report this issue to the bot maintainer!\nThank you :)")
        return false
    return true

proc attemptCommandExecution(s: Shard, m: Message, args: seq[string]): bool =
    let request = args[0]
    echo request

    # Search for matching command:
    for command in CommandList:
        # Check for command name:
        if command.name == request:
            return command.callCommand(s, m, args)

        # Check for command alias name:
        for alias in command.alias:
            if alias == request:
                return command.callCommand(s, m, args)
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
    return attemptCommandExecution(s, m, args)


# Discord events:
proc onReady(s: Shard, r: Ready) {.event(discord).} =
    echo "Ready as " & $r.user & " in " & $r.guilds.len & " guilds!"
    discard await discord.api.bulkOverwriteApplicationCommands(
        s.user.id,
        @[ApplicationCommand(
            name: "help",
            description: "Provides general help for the bot.",
            kind: atSlash,
            default_permission: true
        )]
    )

proc interactionCreate(s: Shard, i: Interaction) {.event(discord).} =
    # Literally only to give information on how to NOT use slash commands! :)
    await discord.api.interactionResponseMessage(i.id, i.token,
        kind = irtChannelMessageWithSource,
        response = InteractionCallbackDataMessage(
            content: "My prefix is `" &
                $config.prefix &
                "` and you can see all available commands with `help` and a detailed documentation on specific commands with `docs`!"
        )
    )

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
    discard handleCommandCall(s, m)


# Connect to discord:
waitFor discord.startSession(
    gateway_intents = {giDirectMessages, giGuildMessages, giGuilds, giGuildMembers, giMessageContent}
)

