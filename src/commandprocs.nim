import options, asyncdispatch, times, strutils, tables
from unicode import capitalize
import dimscord
import typedefs

# Local procs:
proc sendErrorMessage(m: Message, errorType: ErrorType, desc: string): Future[system.void] {.async.} =
    discard discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            title: (($errorType).toLower().capitalize() & " Error").some,
            description: desc.some,
            footer: EmbedFooter(
                text: "See help or doc command for further help."
            ).some
        )]
    )


# Command procs:
proc pingCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} =
    let
        then: float = epochTime() * 1000
        msg = await discord.api.sendMessage(m.channel_id, "pinging...")
        now: float = epochTime() * 1000

    discard await discord.api.editMessage(
        m.channel_id,
        msg.id,
        "Pong! Took " & $int(now - then) & "ms.\nLatency: " & $s.latency() & "ms."
    )


proc helpCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} =
    var embedFields: seq[EmbedField]
    var commandCat: Table[CommandCategory, seq[string]]

    # * Fix issue hanging in sorting phase (idk why it was hanging, but this helps):
    for category in CommandCategory:
        commandCat[category] = @[]

    # Sort commands into table:
    for command in CommandList:
        var cat: CommandCategory = command.category
        commandCat[cat].add(command.name)

    # Add categories to embed fields:
    for category, name in commandCat:
        # * Fix issue of not sending due to empty embed field values:
        if name.len == 0: continue

        # Add embed field:
        embedFields.add(EmbedField(
            name: ($category).toLower().capitalize(),
            value: name.join(", "),
            inline: true.some
        ))    

    # Send Embed Message:
    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            title: "List of all available commands:".some,
            fields: embedFields.some
        )]
    )


proc docCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} =
    # No arguments passed:
    if args.len < 2:
        discard sendErrorMessage(m, SYNTAX, "You have to provide a command as argument.")
        return
    
    # Get requested command:
    let request: string = args[1].toLower().strip()
    var requestedCommand: Command
    for command in CommandList:
        if request == command.name: requestedCommand = command; break
        for alias in command.alias:
            if request == alias: requestedCommand = command; break
    
    # Check if command was found:
    if requestedCommand notin CommandList:
        discard sendErrorMessage(m, SYNTAX, "You have to provide a valid command name as argument.")
        return

    # Doc embed fields:
    var embedFields: seq[EmbedField] = @[
        EmbedField(
            name: "Category:",
            value: ($requestedCommand.category).toLower().capitalize(),
            inline: true.some
        )
    ]

    # Add alias, if declared:
    if requestedCommand.alias != @[]:
        embedFields.add(EmbedField(
            name: "Alias:",
            value: requestedCommand.alias.join(", "),
            inline: true.some
        ))
    
    # Add alias, if declared:
    if requestedCommand.usage != @[]:
        embedFields.add(EmbedField(
            name: "Usage:",
            value: requestedCommand.usage.join("\n"),
            inline: true.some
        ))

    # Send docs on requested command:
    var embedDoc: Embed = Embed(
        title: ("Documentation for command '" & requestedCommand.name & "':").some,
        description: requestedCommand.desc.some,
        fields: embedFields.some
    )

    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[embedDoc]
    )

