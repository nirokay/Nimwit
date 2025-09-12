import std/[strutils, strformat, options, asyncdispatch, tables, json, math, random, base64, random, times, os]
import dimscord, nimcatapi
import typedefs, configfile, compiledata, databaseprocs, databaseuser, databaseserver, imagegeneration, utils

using
    s: Shard
    i: Interaction

let doNotCreateNewSlashResponse*: SlashResponse = SlashResponse(
    content: "DKCI(QM*E($Nz[te'FOLP=w9SWl?nezz#]X>%2:0TKR8nQFKOZ95iV/zyE1'S>c(qMcoJz5pCZ'h9}Ld#q80M2@ZQ+V6(71{KsJUo>cK5(-EJ@&Rp9.Rq/=v}n#*'S@e" # there should NEVER be an instance of this being the natural state of content, if yes, then fuck who knows, ill drink some bleach(?) idk
)

# -------------------------------------------------
# System:
# -------------------------------------------------

# Settings:
proc displaySettingsSlash*(s, i): Future[SlashResponse] {.async.} =
    var serverdata: string
    try:
        let jsondata: JsonNode = %dbGetServer(i.guild_id.get()).channels
        serverdata = pretty(jsondata, 2)
    except KeyError:
        return await sendErrorMessage(s, i, VALUE, "This server has no data saved. Try modifying settings first.")

    # Send message:
    var embed = Embed(
        title: some "Settings for this server in json",
        description: some &"```json\n{serverdata}\n```"
    )
    return SlashResponse(
        embeds: @[embed]
    )

proc modifySettingSlash*(s, i): Future[SlashResponse] {.async.} =
    let
        data = i.data.get()
        guild_id = i.guild_id.get()
        channel_id = i.channel_id.get()
        task: string = data.options["task"].str

    let status: DbResult = changeChannelSetting(guild_id, channel_id, task)
    if status.error:
        return await sendErrorMessage(s, i, INTERNAL, status.reason)
    return SlashResponse(
        content: status.reason
    )

proc infoSlash*(s, i): Future[SlashResponse] {.async.} =
    # Build Embed:
    let desc: string = block:
        &"Hi, I am {BotInfo.name}! My code is open-source and can be found [here]({BotInfo.repository})!\n" &
        &"If you encounter any issues, feel free to [open an issue on github]({BotInfo.issues}). Thank you :)"

    var embed = Embed(
        author: some authorBot("", BotInfo.repository),
        title: some "Information about me!",
        description: some desc,
        color: some EmbedColour.default
    )

    # Add fields:
    let i: Option[bool] = some true
    embed.fields = some @[
        EmbedField(
            name: "Bot Version",
            value: &"v{BotVersion}\nCompiled: {CompileDate} {CompileTime} UTC",
            inline: i
        ),
        EmbedField(
            name: "Running since",
            value: &"{botRunningTimePretty()}",
            inline: i
        )
    ]

    var response: SlashResponse = SlashResponse()
    response.embeds.add embed
    return response


# -------------------------------------------------
# Economy:
# -------------------------------------------------

proc balanceSlash*(s, i): Future[SlashResponse] {.async.} =
    let
        data = i.data.get()
        id: string = data.options["user"].user_id

        target: User = await discord.api.getUser(id)
        balance: int = getUserBalance(target.id)

    return SlashResponse(
        embeds: @[Embed(
            author: some authorUser(target, "'s current balance"),
            title: some $balance
        )]
    )

proc transferMoneySlash*(s, i): Future[SlashResponse] {.async.} =
    let data = i.data.get()

    let
        amountRaw: BiggestFloat = data.options["amount"].fval
        amount: int = amountRaw.floor().toInt()
        target: User = await discord.api.getUser(data.options["user"].user_id)
        source: User = getUser()

    if source.id == target.id:
        return waitFor sendErrorMessage(s, i, USAGE, "You cannot send currency to yourself.")

    # Check value:
    if amount <= 0 or amountRaw.ceil().toInt() != amount:
        return await sendErrorMessage(s, i, VALUE, "The amount has to be a positive integer. Got `" & $amountRaw & "` and parsed to `" & $amount & "`...")

    # Error while transferring:
    let status = handleUserToUserTransfer(source.id, target.id, amount)
    if status.error:
        return await sendErrorMessage(s, i, VALUE, status.reason)

    return SlashResponse(
        embeds: @[Embed(
            author: some authorUser(" transferred currency"),
            description: some("```diff\n" &
                source.fullUsername() & "'s current balance: " &
                $getUserBalance(source.id) & "\n- " & $amount & " currency\n\n" &

                target.fullUsername() & "'s current balance: " &
                $getUserBalance(target.id) & "\n+ " & $amount & " currency" &
                "```"),
            color: some EmbedColour.success
        )]
    )

proc dailySlash*(s, i): Future[SlashResponse] {.async.} =
    let
        user: User = getUser()
        status = handleUserDailyCurrency(user.id)

    if status.error:
        return await sendErrorMessage(s, i, USAGE, status.reason)

    return SlashResponse(
        embeds: @[Embed(
            author: some authorUser(" claimed their daily reward!"),
            description: some status.reason,
            color: some EmbedColour.success
        )]
    )


# -------------------------------------------------
# Chatting stuff:
# -------------------------------------------------

proc echoSlash*(s, i): Future[SlashResponse] {.async.} =
    let data = i.data.get()
    return SlashResponse(
        content: data.options["message"].str.replace("\\n", "\n")
    )

proc getImageListChoices*(): seq[SlashChoice] =
    for image in ImageTemplateList:
        result.add SlashChoice(name: image.name, value: (some image.name, none int))
proc imageSlash*(s, i): Future[SlashResponse] {.async.} =
    let
        data = i.data.get()
        user: User = getUser()
        imageName: string = data.options["image"].str.toLower()
        imageText: string = data.options["text"].str.replace("\\n", "\n")

    var requestedImage: ImageTemplate
    for image in ImageTemplateList:
        if image.name.toLower() == imageName:
            requestedImage = image
            break

    if requestedImage notin ImageTemplateList:
        return await sendErrorMessage(s, i, USAGE, "Image `" & imageName & "` not found in list. This is probably a discord issue.")

    let imageFilePath: string = getNewImageFileName(requestedImage)
    discard createImageFile(requestedImage, imageFilePath, imageText)
    result = SlashResponse(
        content: "Here is your requested image " & user.mentionUser() & "!",
        attachments: @[Attachment(filename: imageFilePath)]
    )

let ignoreChars: string = " ,.;:~-–_*'\"!?"
proc evaluateStringPercent(str: string): string =
    var normalized: string = str
    for c in ignoreChars:
        normalized = normalized.replace($c, "")
    let encoded: string = base64.encode(normalized.toLower())

    var sumOfCharacters: int
    for letter in encoded:
        sumOfCharacters += letter.char().int()

    let percent = sumOfCharacters mod 101
    return $percent & "%"

proc truthValueSlash*(s, i): Future[SlashResponse] {.async.} =
    let
        data = i.data.get()
        user: User = getUser()
    # Calculate truth value:
    let
        statement: string = data.options["statement"].str
        percent: string = statement.evaluateStringPercent()

    # Send Message:
    return SlashResponse(
        embeds: @[Embed(
            author: some authorUser(" requested my infinite wisdom"),
            title: some("The following statement is **" & percent & "** true:"),
            description: some statement,
            color: some EmbedColour.default
        )]
    )

proc loveValueSlash*(s, i): Future[SlashResponse] {.async.} =
    let
        data = i.data.get()
        userFirst: User = getUser(data.options["first"].user_id)
        userSecond: User = getUser(data.options["second"].user_id)
        percent: string = evaluateStringPercent($(
            userFirst.id.parseInt() + userSecond.id.parseInt()
        ))
    return SlashResponse(
        embeds: @[Embed(
            title: some "Love-o-meter",
            description: some(userFirst.fullUsername().sanitize() & " 💕 " & userSecond.fullUsername().sanitize() & " = " & percent),
            color: some EmbedColour.default
        )]
    )

type AnswerYNM = object
    weight*: int
    answers*: seq[string]
proc yesNoMaybeSlash*(s, i): Future[SlashResponse] {.async.} =
    let
        data = i.data.get()
        statement: string = data.options["statement"].str
        user: User = getUser()

    # Parse Json:
    var jsonResponses: JsonNode
    try:
        jsonResponses = readFile(getLocation(fileYesNoMaybe)).parseJson()
    except JsonParsingError:
        return await sendErrorMessage(s, i, INTERNAL, "An issue occurred while parsing json file. Please report this.")

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
    return SlashResponse(
        embeds: @[Embed(
            author: some authorUser(" requested my infinite wisdom"),
            title: some "Yes No Maybe",
            description: some("> " & statement & "\n# " & finalAnswer.capitalize()),
            color: some EmbedColour.default
        )]
    )

proc profileSlash*(s, i): Future[SlashResponse] {.async.} =
    let
        data = i.data.get()
        target: User = getUser(data.options["user"].user_id)
        allFlags: set[UserFlags] = target.flags + target.public_flags

    # Add emojis next to name:
    var emojis: seq[string]
    if target.bot: emojis.add("🤖")
    if target.system: emojis.add("⚙️")
    if target.premium_type.isSome(): # always returns a `None`, deprecated by API?
        emojis.add case target.premium_type.get():
            of uptNone: ""
            of uptNitroClassic: "💰"
            of uptNitro: "🤑"
            of uptNitroBasic: "💵"

    if ufDiscordEmployee in allFlags or ufDiscordCertifiedModerator in allFlags: emojis.add "👮"
    if ufActiveDeveloper in allFlags or ufEarlyVerifiedBotDeveloper in allFlags: emojis.add "🧑‍💻"

    # Add fields:
    let inlineSetting: bool = false

    # User field: (guaranteed)
    var userFieldText: seq[string]
    block `addingUserFields`:
        defer: userFieldText.add &"**User ID:** {target.id}"
        if target.global_name.isSome(): userFieldText.add &"**Global name:** {target.global_name.get().sanitize()}"
        if target.display_name.isSome(): userFieldText.add &"**Display name:** {target.display_name.get().sanitize()}"

        let houses: set[UserFlags] = allFlags * {ufHouseBravery, ufHouseBrilliance, ufHouseBalance}
        var houseList: seq[string]
        for house in houses:
            houseList.add case house:
                of ufHouseBravery: "Bravery"
                of ufHouseBrilliance: "Brilliance"
                of ufHouseBalance: "Balance"
                else: ""
        if houseList.len() != 0: userFieldText.add "**Hype House:** " & houseList.join(", ") # there SHOULD be only one house


    # Server field (only added, if user executed on a server):
    var memberField: EmbedField
    if i.member.isSome():
        let
            guild: Guild = await discord.api.getGuild(i.guild_id.get()) #s.cache.guilds[m.guild_id.get()]
            member: Member = await discord.api.getGuildMember(guild.id, target.id)

        # Format Date:
        let
            discordTimeStamp = member.joined_at[0..9]
            joinDate: string = block:
                if discordTimeStamp != "":
                    let dt: DateTime = parse(discordTimeStamp, "yyyy-MM-dd")
                    dt.format("dd- MMMM yyyy").replace("-", ".")
                else:
                    "Guest"

        var memberFieldText: seq[string] = @[
            &"**Joined on:** {joinDate}",
            &"**Server booster:** {member.premium_since.isSome()}",
            &"**Number of roles:** {member.roles.len()}"
        ]

        # Add guild emojis:
        if target.id == guild.owner_id: emojis.add("👑")
        if member.premium_since.isSome(): emojis.add("🚀")

        # Add highest role, if any roles available:
        if member.roles.len() > 0:
            var allRoles: seq[string]
            for id in member.roles:
                try:
                    allRoles.add id.mentionRole()
                except CatchableError:
                    echo "Unknown role " & id & " in guild " & guild.id
                except Defect:
                    echo "Unknown role " & id & " in guild " & guild.id

            memberFieldText.add("**All roles:** " & allRoles.join(", "))

        memberField = EmbedField(
            name: "Server stats",
            value: memberFieldText.join("\n"),
            inline: some inlineSetting
        )

    # Begin assembling Embed:
    var embed = Embed(
        thumbnail: some EmbedThumbnail(url: target.getAnimatedAvatar())
    )

    # Add title:
    embed.title = some &"""{target.fullUsername().sanitize()} {emojis.join(" ")}"""

    # User embed (always present):
    var userField = EmbedField(
        name: "User stats",
        value: userFieldText.join("\n"),
        inline: inlineSetting.some
    )

    # Add user banner as image:
    if target.banner.isSome():
        embed.image = some EmbedImage(url: target.getAnimatedBanner() & "?size=640")

    # Add fields:
    embed.fields = some @[userField, memberField]

    # Add colour:
    embed.color = block:
        if target.accent_color.isSome(): some target.accent_color.get()
        else: some EmbedColour.default

    # Send embed:
    return SlashResponse(
        embeds: @[embed]
    )

proc socialEmbed(operation: string, s; i;): Embed =
    let
        data = i.data.get()
        source: User = getUser()
        target: User = getUser(data.options["user"].user_id)

    # Check if pinged self:
    if unlikely source.id == target.id:
        return Embed(
            author: some authorBot(" is comforting you " & source.fullUsername() & ". :)"),
            description: some "Pat pat, it's okay <3",
            image: some EmbedImage(
                url: "https://media.tenor.com/dgbF5WN6ujoAAAAC/headpat-cat.gif"
            ),
            color: some EmbedColour.warning
        )

    # Parse json file:
    var jsonObj: JsonNode
    try:
        jsonObj = readFile(getLocation(fileSocialGifs)).parseJson()
    except JsonParsingError:
        return getErrorEmbed(INTERNAL, "An issue occurred while parsing json file. Please report this.")

    # Get sequence of gifs:
    let
        gifList: JsonNode = jsonObj{operation}
        randomGifId: int = rand(int(gifList.len) - 1)
        randomGif: string = gifList{randomGifId}.getStr("https://media.tenor.com/qsthhHhdjsQAAAAC/error-windows.gif")

    # Send Message with GIF:
    return Embed(
        author: some authorUser(source, " gave " & target.fullUsername() & " a " & operation & "!"),
        image: some EmbedImage(
            url: randomGif
        ),
        color: some EmbedColour.default
    )

proc hugSlash*(s, i): Future[SlashResponse] {.async.} =
    return SlashResponse(embeds: @[socialEmbed("hug", s, i)])

proc patSlash*(s, i): Future[SlashResponse] {.async.} =
    return SlashResponse(embeds: @[socialEmbed("pat", s, i)])

proc kissSlash*(s, i): Future[SlashResponse] {.async.} =
    return SlashResponse(embeds: @[socialEmbed("kiss", s, i)])

proc slapSlash*(s, i): Future[SlashResponse] {.async.} =
    return SlashResponse(embeds: @[socialEmbed("slap", s, i)])

proc boopSlash*(s, i): Future[SlashResponse] {.async.} =
    return SlashResponse(embeds: @[socialEmbed("boop", s, i)])

proc dateResponse(i; source, target: User): Future[SlashResponse] {.async.} =
    return SlashResponse(content: "yay data now")
proc slashDate*(s, i): Future[SlashResponse] {.async.} =
    const timeoutSeconds: int = 60
    let
        data = i.data.get()
        source: User = getUser()
        target: User = getUser(data.options["user"].userId)
        interactionYesId: string = &"date-{source.id}-{target.id}-{int epochTime()}"

    #if source.id == target.id:
    #    return await sendErrorMessage(s, i, USAGE, "You cannot ask yourself out on a date :/")

    let row: MessageComponent = block:
        var r: MessageComponent = newActionRow()
        r.components &= newButton(
            label = "Accept",
            idOrUrl = interactionYesId,
            emoji = Emoji(name: some "✅")
        )
        r

    waitFor discord.api.interactionResponseMessage(
        i.id, i.token,
        kind = irtChannelMessageWithSource,
        response = SlashResponse(
            content: &"{source.mentionUser()} asked {target.mentionUser()} out on a date.\nYou have {timeoutSeconds} seconds to accept or it will time out.",
            components: @[row]
        )
    )

    var interaction: Interaction
    block waitOnResponse:
        while true:
            let newInteraction: Option[Interaction] = await discord.waitForComponentUse(interactionYesId).orTimeout(seconds timeoutSeconds)
            if newInteraction.isNone():
                discard waitFor discord.api.editInteractionResponse(
                    s.user.id, i.token,
                    content = some "Timeout"
                )
                return doNotCreateNewSlashResponse

            let
                gotInteraction: Interaction = get newInteraction
                interactionUser: User = block:
                    if gotInteraction.member.isSome: gotInteraction.member.get().user
                    else: gotInteraction.user.get()
            if interactionUser.id == target.id:
                interaction = gotInteraction
                break waitOnResponse

    let response: SlashResponse = await dateResponse(interaction, source, target)
    discard waitFor discord.api.editInteractionResponse(
        s.user.id, i.token,
        content = some response.content,
        embeds = response.embeds
    )

    return doNotCreateNewSlashResponse

let
    apiCat: TheCatApi = newCatApiClient()
    apiDog: TheDogApi = newDogApiClient()
proc animalEmbed(api: TheCatApi|TheDogApi, animal: string; s, i): Embed =
    let url: string = api.requestImageUrl()
    result = Embed(
        author: some authorUser(" requested a random " & animal & " image"),
        image: some EmbedImage(
            url: url
        ),
        color: some EmbedColour.default
    )

proc catApiSlash*(s, i): Future[SlashResponse] {.async.} =
    return SlashResponse(embeds: @[animalEmbed(apiCat, "cat", s, i)])
proc dogApiSlash*(s, i): Future[SlashResponse] {.async.} =
    return SlashResponse(embeds: @[animalEmbed(apiDog, "dog", s, i)])


# -------------------------------------------------
# Math stuff:
# -------------------------------------------------

type CoinFace = enum
    coinHeads = "heads"
    coinTails = "tails"
proc coinFlipEmbed*(s, i; action: string, bias: float): Embed =
    let
        user: User = getUser()
        optionalDisclaimer: string = if bias != 0.5: "n unfair" else: ""
        value: float = rand(1.0)
        face: CoinFace = if value < bias: coinHeads else: coinTails
        url: string = case face:
            of coinHeads: CoinFlip.headsUrl
            of coinTails: CoinFlip.tailsUrl

    result.author = some EmbedAuthor(
        name: &"{user.fullUsername()} {action}ped a{optionalDisclaimer} coin!",
        icon_url: some user.avatarUrl()
    )
    result.description = some "You got **" & capitalize($face) & "**!"
    if likely url.endsWith(".gif"):
        result.image = some EmbedImage(
            url: url,
            width: some 128,
            height: some 128
        )
    else:
        result.video = some EmbedVideo( # apparently does not work for bots, YIPPIIEEE ._.
            url: some url,
            proxy_url: some url,
            width: some 128,
            height: some 128
        )

proc flipSlash*(s, i): Future[SlashResponse] {.async.} =
    return SlashResponse(embeds: @[coinFlipEmbed(s, i, "flip", 0.5)])

proc flopSlash*(s, i): Future[SlashResponse] {.async.} =
    return SlashResponse(embeds: @[coinFlipEmbed(s, i, "flop", 0.75)])


proc randomWordSlash*(s, i): Future[SlashResponse] {.async.} =
    const sep: string = ","
    let
        data = i.data.get()
        user = getUser()
        wordList: seq[string] = data.options["list"].str.sanitize().split(sep)
        index: int = rand(wordList.len() - 1)
        pick: string = block:
            let r: string = wordList[index]
            if unlikely r == "": "*empty string*" else: r

        reconstructed: string = block:
            var r: seq[string] = wordList
            r[index] = "**<<" & pick & ">>**"
            r.join(sep)

        pickSneakPeak: string = block:
            var r: string = pick.strip().replace("\n", " ") # There should not be any newlines, but its discord, who knows
            if pick.len() > 50: r = r[0 .. (49 - 3)] & "..."
            r

    var embed: Embed = Embed()
    embed.author = some EmbedAuthor(
        name: user.fullUsername() & " requested a random substring",
        icon_url: some user.avatarUrl()
    )
    embed.title = some &"I chose substring nr. {index + 1}/{wordList.len()}: {pickSneakPeak}"
    embed.description = some reconstructed
    embed.footer = some EmbedFooter(
        text: &"Word list separated by commas ({sep})."
    )

    return SlashResponse(embeds: @[embed])


const validDice: seq[int] = @[3, 4, 6, 8, 10, 12, 20, 100]
proc getDiceRollingChoices*(): seq[SlashChoice] =
    for die in validDice:
        result.add SlashChoice(name: $die & "-sided die", value: (none string, some die))
proc rollSlash*(s, i): Future[SlashResponse] {.async.} =
    let
        data = i.data.get()
        user: User = getUser()
        rawTimes: float = if data.options.hasKey("amount"): data.options["amount"].fval else: 1.0
        rawSides: float = if data.options.hasKey("die"): data.options["die"].fval else: 6.0
        times: int = rawTimes.toInt()
        sides: int = rawSides.toInt()

    # Handle invalid numbers
    var errorLines: seq[string]
    block `parsingErrorStuff`:
        const
            m0: string = "The number for "
            m1: string = " has to be a positive integer. You passed: `"
            m2: string = "`"
        if unlikely(rawTimes.floor() != rawTimes.ceil() or rawTimes < 1.0):
            errorLines.add m0 & "amount to roll the die" & m1 & $rawTimes & m2
        if unlikely(rawSides.floor() != rawSides.ceil() or rawSides < 1.0):
            errorLines.add m0 & "sides of the die" & m1 & $rawSides & m2
    if unlikely errorLines.len() != 0:
        return await sendErrorMessage(s, i, USAGE, errorLines.join("\n"))

    const maxRoll: int = 500
    if unlikely times notin 1..maxRoll:
        return await sendErrorMessage(s, i, USAGE, "The maximal amount of rolls is limited to `" & $maxRoll & "`! :(")

    if unlikely sides notin validDice: # if this happens, fuck you discord
        return await sendErrorMessage(s, i, USAGE, "You cannot roll a " & $sides & "-sided die. Here is a list of the ones you can roll: `" & validDice.join(", ") & "`")

    var performedRolls: seq[int] = newSeq[int](times)
    for current in 1..times:
        performedRolls[current - 1] = rand(1..sides)

    let
        sum: int = performedRolls.sum()
        minimum: int = performedRolls.min()
        maximum: int = performedRolls.max()
        average: float = sum / times

    result = SlashResponse(
        embeds: @[Embed(
            author: some authorUser(" rolled a " & $sides & "-sided die " & $times & " times:"),
            fields: some @[
                EmbedField(
                    name: "Sum and Average",
                    value: &"Sum: `{sum}`\nMean/Average: `{average}`",
                    inline: some true
                ),
                EmbedField(
                    name: "Minimum and Maximum",
                    value: &"Minimum: `{minimum}`\nMaximum: `{maximum}`",
                    inline: some true
                )
            ],
            description: some performedRolls.join(", "),
            color: some EmbedColour.default
        )]
    )


proc getUnitConversionChoices*(kind: string): seq[SlashChoice] =
    for name, unit in UnitConversions[kind]:
        result.add SlashChoice(name: &"{name} ({unit.name})", value: (some name, none int))

proc getDefaultUnit(kind: string, conversions: UnitConversion): (string, Unit) =
    for name, unit in conversions:
        if unit.default == some true: return (name, unit)
    raise ValueError.newException($INTERNAL & ": No default unit for '" & kind & "' found :(")

proc convertUnits(s, i; kind, sourceName, targetName: string, number: float, conversions: UnitConversion): Embed =
    var
        current: float = number
        steps: seq[string] = @["Breakdown of steps:"]
    let
        (defaultName, default) = getDefaultUnit(kind, conversions)
        source: Unit = conversions[sourceName]
        target: Unit = conversions[targetName]

    if source != target:
        # Convert to default, if not already default:
        if source.default != some true:
            let
                add: float = source.adder.get(0)
                mul: float = source.multiplicator
                stepAdd: string = if add == 0: "" else: &" - `{add}`)"
            current -= add
            current /= mul
            steps.add (if stepAdd != "": "(" else: "") & &"`{number}`{sourceName}{stepAdd} / `{mul}` = `{current}`{defaultName}"

        # Convert default to target:
        let
            numberDefault: float = current
            add: float = target.adder.get(0)
            mul: float = target.multiplicator
            stepAdd: string = if add == 0: "" else: &" + `{add}`"
        current *= mul
        current += add
        if steps.len() != 0 and defaultName != targetName:
            steps.add &"`{numberDefault}`{defaultName} * `{mul}`{stepAdd} = `{current}`{targetName}"
    else:
        steps.add &"`{number}`{sourceName} = `{current}`{targetName}"

    result = Embed(
        author: some authorUser(&" requested to convert from {source.name} to {target.name}"),
        title: some &"{kind.capitalize()} unit conversion: `{number}`{sourceName} -> `{current}`{targetName}",
        description: some steps.join("\n"),
        footer: some EmbedFooter(
            text: "Note: These calculations use floating point arithmetic and may be not 100% correct."
        ),
        color: some EmbedColour.success
    )

proc convert(s, i; kind: string): SlashResponse =
    let
        data = i.data.get()
        source: string = data.options["from"].str
        target: string = data.options["to"].str
        number: float = data.options["number"].fval
        conversions: UnitConversion = UnitConversions[kind]
    return SlashResponse(embeds: @[convertUnits(s, i, kind, source, target, number, conversions)])

proc convertLengthSlash*(s, i): Future[SlashResponse] {.async.} = return convert(s, i, "length")
proc convertAreaSlash*(s, i): Future[SlashResponse] {.async.} = return convert(s, i, "area")
proc convertTemperatureSlash*(s, i): Future[SlashResponse] {.async.} = return convert(s, i, "temperature")
proc convertSpeedSlash*(s, i): Future[SlashResponse] {.async.} = return convert(s, i, "speed")
proc convertMassSlash*(s, i): Future[SlashResponse] {.async.} = return convert(s, i, "mass")
proc convertVolumeSlash*(s, i): Future[SlashResponse] {.async.} = return convert(s, i, "volume")
