import options, asyncdispatch, times, strutils, tables, random
from unicode import capitalize
import dimscord
import typedefs, configfile

# -------------------------------------------------
# Setup:
# -------------------------------------------------

randomize()


# -------------------------------------------------
# Local procs:
# -------------------------------------------------

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

# -------------------------------------------------
# Command procs:
# -------------------------------------------------

# SYSTEM ------------------------------------------

# Test ping command:
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

# Help Command:
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

# Documentation command:
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


# MATH --------------------------------------------

# Roll command:
proc parseRollFromInts(strTimes, strSides: string): seq[int] =
    try:
        result = @[strTimes.parseInt(), strSides.parseInt()]
    except ValueError:
        result = @[0, 0]
    return result
proc parseRollFromString(str: string): seq[int] =
    try:
        var seperated: seq[string] = str.toLower().split("d")
        result = parseRollFromInts(seperated[0], seperated[1])
    except Exception:
        result = @[0, 0]
    return result

proc rollCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    var times, sides: int
    var nums: seq[int]

    # Parse ints from input string(s):
    case args.len:
    of 1:
        # No arguments passed:
        nums = @[1, 6]
    of 2:
        # One string passed:
        nums = parseRollFromString(args[1])
    else:
        # Two ints passed:
        nums = parseRollFromInts(args[1], args[2])
    
    # Error handling while parsing:
    if nums[0] < 1 or nums[1] < 1:
        discard sendErrorMessage(m, VALUE, "You have to provide two valid integers above 0 or a string with two valid ints seperated by a 'd'!")
        return
    times = nums[0]
    sides = nums[1]

    # Check if request is larger than limit:
    if times > config.rollCommandLimit:
        discard sendErrorMessage(m, VALUE, "You cannot request more than " & $config.rollCommandLimit & " rolls at a time...")
        return
    
    # Proceed with rolling:
    var rollResults: seq[int]
    for times in 1..times:
        let roll: int = rand(sides - 1) + 1
        rollResults.add(roll)

    # Send results:
    var resultEmbed = Embed(
        author: EmbedAuthor(
            name: m.author.username & " rolled a " & $sides & "-sided die " & $times & " times!",
            icon_url: m.author.avatarUrl.some
        ).some,
        title: "Here are your results:".some,
        description: rollResults.join(", ").some
    )

    # Add statistics, if more than one throw:
    if times > 1:
        var sum: int
        for i in rollResults: sum = sum + i

        resultEmbed.fields = @[
            EmbedField(
                name: "Total sum",
                value: $sum
            ),
            EmbedField(
                name: "Average roll",
                value: $(sum / times)
            )
        ].some

    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[resultEmbed]
    )


