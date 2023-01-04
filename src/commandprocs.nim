import options, asyncdispatch, times, strutils, sequtils, tables, random, json, base64
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

proc sendErrorMessage*(m: Message, errorType: ErrorType, desc: string = "An undefined error occured."): Future[system.void] {.async.} =
    discard discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            title: (($errorType).toLower().capitalize() & " Error").some,
            description: desc.some,
            footer: EmbedFooter(
                text: "See help or doc command for further help."
            ).some,
            color: EmbedColour.error.some
        )]
    )

proc mentionUser*[T: string|int](id: T): string =
    return "<@" & $id & ">"
proc mentionUser*(user: User): string =
    return mentionUser(user.id)

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
        if command.hidden: continue
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
            fields: embedFields.some,
            color: EmbedColour.default.some
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
        fields: embedFields.some,
        color: EmbedColour.default.some
    )

    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[embedDoc]
    )


# SOCIAL ------------------------------------------

# Greet back:
proc helloCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    var helloList: JsonNode
    try:
        let jsonRaw: string = readFile(config.fileLocations[fileHelloList])
        helloList = jsonRaw.parseJson()
    except IOError:
        discard sendErrorMessage(m, INTERNAL, "Response json-file could not be located. Please report this.")
        return
    except JsonParsingError:
        discard sendErrorMessage(m, INTERNAL, "Response json-file could not be parsed. Please report this.")
        return

    let response: string = helloList[rand(helloList.len - 1)].getStr
    discard await discord.api.sendMessage(
        m.channel_id,
        response
    )

# Hug, pat, kiss, boop, slap commands:
proc sendSocialEmbed(operation: string, s: Shard, m: Message): Future[system.void] {.async.} =
    # Check if another user was mentioned:
    if m.mention_users.len == 0:
        discard sendErrorMessage(m, SYNTAX, "You have to ping another user to person to " & operation & "!")
        return
    let target: User = m.mention_users[0]

    # Check if pinged self:
    if target.id == m.author.id:
        discard await discord.api.sendMessage(
            m.channel_id,
            embeds = @[Embed(
                author: EmbedAuthor(
                    name: s.user.username & " is comforting you, " & m.author.username & ". :)",
                    icon_url: s.user.avatarUrl.some
                ).some,
                description: "Pat pat, it's okay".some,
                image: EmbedImage(
                    url: "https://media.tenor.com/dgbF5WN6ujoAAAAC/headpat-cat.gif"
                ).some,
                color: EmbedColour.warning.some
            )]
        )
        return

    # Parse json file:
    var jsonObj: JsonNode
    try:
        jsonObj = config.fileLocations[fileSocialGifs].readFile.parseJson
    except JsonParsingError:
        discard sendErrorMessage(m, INTERNAL, "An issue occured while parsing json file. Please report this.")
        return

    # Get sequence of gifs:
    let
        gifList: JsonNode = jsonObj{operation}
        randomGifId: int = rand(int(gifList.len) - 1)
        randomGif: string = gifList{randomGifId}.getStr("https://media.tenor.com/qsthhHhdjsQAAAAC/error-windows.gif")

    # Send Message with GIF:
    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            author: EmbedAuthor(
                name: m.author.username & " gave " & target.username & " a " & operation & "!",
                icon_url: m.author.avatarUrl.some
            ).some,
            image: EmbedImage(
                url: randomGif
            ).some,
            color: EmbedColour.default.some
        )]
    )
proc hugCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    return sendSocialEmbed("hug", s, m)

proc patCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    return sendSocialEmbed("pat", s, m)

proc kissCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    return sendSocialEmbed("kiss", s, m)

proc slapCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    return sendSocialEmbed("slap", s, m)

proc boopCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    return sendSocialEmbed("boop", s, m)


# CHATTING ----------------------------------------

# Truth value:
proc evaluateStringPercent(str: string): string =
    var sumOfCharacters: int
    let encoded: string = base64.encode(str)
    for letter in encoded:
        sumOfCharacters += letter.char().int()
    
    let percent = sumOfCharacters mod 101
    return $percent & "%"

proc truthValueCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    # Check for presend args:
    if args.len < 2:
        discard sendErrorMessage(m, SYNTAX, "You have to provide a string as input to check truth value for.")
        return

    # Calculate truth value:
    let statement: string = args[1..args.len-1].join(" ")
    let percent: string = statement.evaluateStringPercent()

    # Send Message:
    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            author: EmbedAuthor(
                name: m.author.username & " requested a truth value",
                icon_url: m.author.avatarUrl.some
            ).some,
            title: ("The following statement is " & percent & " true:").some,
            description: statement.some,
            color: EmbedColour.default.some
        )]
    )

# Love command:
proc loveValueCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    var ids: seq[string]

    # Nobody was mentioned:
    if m.mention_users.len == 0:
        discard sendErrorMessage(m, SYNTAX, "You have to mention users for this command.")
        return

    # Add user-self to ids if only one was mentioned:
    if m.mention_users.len == 1:
        ids.add(m.author.id)
    
    # Add mentioned users:
    for user in m.mention_users:
        ids.add(user.id)
    let final_ids: seq[string] = ids.deduplicate()

    # Check if the same user is inserted twice:
    if final_ids.len < 2:
        discard sendErrorMessage(m, VALUE, "You have to mention two unique users.")
        return

    # Send message:
    let percent: string = evaluateStringPercent($(
        final_ids[0].parseInt + final_ids[1].parseInt
    ))
    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            title: "Love-o-meter".some,
            description: some(final_ids[0].mentionUser & " 💕 " & final_ids[1].mentionUser & " = " & percent),
            color: EmbedColour.default.some
        )]
    )

# Echo and echodel:
proc echoCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    var argsClean: seq[string] = args
    argsClean.delete(0)
    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            author: EmbedAuthor(
                name: m.author.username & " said:",
                icon_url: m.author.avatarUrl.some
            ).some,
            description: argsClean.join(" ").some,
            color: EmbedColour.success.some
        )]
    )
proc echodelCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    discard echoCommand(s, m, args)
    discard discord.api.deleteMessage(
        m.channel_id,
        m.id,
        "performed echodel command"
    )

type AnswerYNM = object
    weight*: int
    answers*: seq[string]

proc yesnomaybeCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    if args.len == 1:
        discard sendErrorMessage(m, SYNTAX, "You have to provide a statement for me to answer as argument.")
        return

    # Parse Json:
    var jsonResponses: JsonNode
    try:
        jsonResponses = config.fileLocations[fileYesNoMaybe].readFile().parseJson()
    except JsonParsingError:
        discard sendErrorMessage(m, INTERNAL, "An issue occured while parsing json file. Please report this.")
        return

    # Convert to answers:
    var
        answerList: seq[AnswerYNM]
        totalWeight: int

    for answer in @["yes", "no", "maybe"]:
        let newAnswer: AnswerYNM = jsonResponses{answer}.to(AnswerYNM)
        answerList.add(newAnswer)
        totalWeight += newAnswer.weight

    # Choose random answer:
    let ranNum: int = rand(totalWeight - 1) + 1
    var
        finalAnswer: string
        sum: int
    for answer in answerList:
        sum += answer.weight
        if sum >= ranNum:
            finalAnswer = answer.answers[rand(answer.answers.len - 1)]
            break

    # Send response:
    discard await discord.api.sendMessage(
        m.channel_id,
        finalAnswer.strip().capitalize() & ", " & mentionUser(m.author.id) & "."
    )


# MATH --------------------------------------------

# Pick-Random-Word command:
proc pickRandomWordCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    # Return if no args given:
    if args.len < 2:
        discard sendErrorMessage(m, SYNTAX, "You have to provide options seperated by spaces as arguments.")
        return
    
    # Pick random:
    var choices: seq[string] = args
    choices.delete(0)
    let pick: string = choices[rand(choices.len - 1)].strip().capitalize()

    # Send result:
    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            author: EmbedAuthor(
                name: m.author.username & "'s random word is:",
                icon_url: m.author.avatarUrl.some
            ).some,
            description: pick.some,
            color: EmbedColour.default.some
        )]
    )

# Pick random number between x and y:
proc pickRandomNumberCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    return


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
        description: rollResults.join(", ").some,
        color: EmbedColour.default.some
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

# Coin flip and flop:
proc getCoinFlipResultEmbed(m: Message, bias: float = 0.5): Embed =
    let randomNumber: float = rand(1.0)

    # Operation name:
    var operation: string
    if bias == 0.5: operation = "flip"
    else: operation = "flop"

    # Decide if heads or tails:
    var coinResult: string
    if randomNumber <= bias: coinResult = "Tails"
    else: coinResult = "Heads"

    # Init Embed:
    result = Embed(
        author: EmbedAuthor(
            name: m.author.username & " " & operation & "ped a coin!",
            icon_url: m.author.avatarUrl.some
        ).some,
        title: ("They got **" & coinResult & "**!").some,
        color: EmbedColour.default.some
    )

    # Add footer about flop, if flopped:
    if bias != 0.5:
        result.footer = EmbedFooter(text: "This is an unjust coin, beware this operation is not 50/50%!").some
    
    # Return ready-to-send embed object:
    return result

proc flipCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[m.getCoinFlipResultEmbed()]
    )
proc flopCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    discard await discord.api.sendMessage(
        m.channel_id,
        embeds = @[m.getCoinFlipResultEmbed(0.75)]
    )


# FUN ---------------------------------------------

# acab command: (inside meme from one of my older bots)
proc acabCommand*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
    discard await discord.api.sendMessage(
        m.channel_id,
        ":taxi:"
    )


