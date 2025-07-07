import std/[strutils, strformat, options, asyncdispatch, tables, json, math, base64, random, times]
from unicode import capitalize
import dimscord
import typedefs, configfile, compiledata, userdatahandler, serverdatahandler, imagegeneration

using
    s: Shard
    i: Interaction


proc getErrorEmbed*(error: ErrorType, message: string = "An unknown error occurred."): Embed = Embed(
    title: some &"{($error).toLower().capitalize()} Error",
    description: some message,
    color: some EmbedColour.error
)
proc getErrorEmbed*(error: ErrorType, message, footerMessage: string): Embed =
    result = getErrorEmbed(error, message)
    result.footer = some EmbedFooter(
        text: footerMessage
    )
    return result

proc sendErrorMessage*(s, i; error: ErrorType, message: string = "An unknown error occurred."): Future[SlashResponse] {.async.} =
    return SlashResponse(
        embeds: @[getErrorEmbed(error, message)]
    )
proc sendErrorMessage*(s, i; error: ErrorType, message, footerMessage: string): Future[SlashResponse] {.async.} =
    return SlashResponse(
        embeds: @[getErrorEmbed(error, message, footerMessage)]
    )


proc mentionUser*[T: string|int](id: T): string =
    return "<@" & $id & ">"
proc mentionUser*(user: User): string =
    return mentionUser(user.id)

proc fullUsername*(user: User): string =
    result = user.username
    if user.discriminator notin ["0", "0000"]:
        result.add "#" & user.discriminator

let escapeChars: string = "_*~#[]()"
proc sanitize*(input: string): string =
    ## Escapes Markdown characters
    result = input
    for c in escapeChars:
        result = result.replace($c, "\\" & $c)


template getUser(): User = ## Gets user, does not care if in DMs or on server
    # WTF discord, i spent around an hour debugging and then learned it is a "feature"
    # that `i.user.get()` is `none User` on servers, but `.isSome() == true` in DMs...
    if i.user.isSome(): i.user.get()
    else: i.member.get().user

template getUser(id: string): User =
    waitFor discord.api.getUser(id)


# Slash Command Procs:

# -------------------------------------------------
# System:
# -------------------------------------------------

# Settings:
proc displaySettingsSlash*(s, i): Future[SlashResponse] {.async.} =
    var serverdata: string
    try:
        serverdata = getServerDataAsJson(i.guild_id.get())
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
    #return await sendErrorMessage(s, i, USAGE, "testing")
    let
        data = i.data.get()
        guild_id = i.guild_id.get()
        channel_id = i.channel_id.get()
        task: string = data.options["task"].str

    let success: (bool, string) = changeChannelSetting(guild_id, channel_id, task)
    if not success[0]:
        return await sendErrorMessage(s, i, INTERNAL, success[1])
    return SlashResponse(
        content: success[1]
    )

proc infoSlash*(s, i): Future[SlashResponse] {.async.} =
    let data = i.data.get()
    type InfoJson = object
        name*, repository*, issues*: string

    var infoNode: JsonNode
    try:
        infoNode = readFile(getLocation(fileInfo)).parseJson()
    except JsonParsingError:
        return await sendErrorMessage(s, i, INTERNAL, "An issue occurred while parsing json file. Please report this.")

    # Build Embed:
    let info: InfoJson = infoNode.to(InfoJson)
    let desc: string = &"Hi, I am {info.name}! My code is open-source and can be found [here]({info.repository})!\n" &
        &"I'm a general-purpose discord bot. You can see all available commands with `help` and get in-depth documentation about any command with `docs [command-name]`!\n" &
        &"If you encounter any issues, feel free to [open an issue on github]({info.issues}). Thank you :)"

    var embed = Embed(
        author: EmbedAuthor(
            name: info.name,
            url: some(info.repository),
            icon_url: s.user.avatarUrl.some
        ).some,
        title: "Information about me!".some,
        description: desc.some,
        color: EmbedColour.default.some
    )

    # Add fields:
    let i: Option[bool] = true.some
    embed.fields = @[
        EmbedField(
            name: "Bot Version",
            value: &"v{BotVersion}\nCompiled: {CompileDate} {CompileTime}",
            inline: i
        ),
        EmbedField(
            name: "Running since",
            value: &"{botRunningTimePretty()}",
            inline: i
        )
    ].some

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
            author: EmbedAuthor(
                name: "Current balance of " & target.username,
                icon_url: target.avatarUrl.some
            ).some,
            title: some($balance)
        )]
    )

proc transferMoneySlash*(s, i): Future[SlashResponse] {.async.} =
    let data = i.data.get()

    let
        amountRaw: BiggestFloat = data.options["amount"].fval # TODO: FIX THIS, API ALWAYS RETURNS `0.0`
        amount: int = amountRaw.floor().toInt()
        target: User = await discord.api.getUser(data.options["user"].user_id)
        source: User = getUser()

    if source.id == target.id:
        return waitFor sendErrorMessage(s, i, USAGE, "You cannot send currency to yourself.")

    # Check value:
    if amount <= 0 or amountRaw.ceil().toInt() != amount:
        return await sendErrorMessage(s, i, VALUE, "The amount has to be a positive integer. Got `" & $amountRaw & "` and parsed to `" & $amount & "`...")

    # Error while transferring:
    let response = handleUserMoneyTransfer(source.id, target.id, amount)
    if response[0] == false:
        return await sendErrorMessage(s, i, VALUE, response[1])

    return SlashResponse(
        embeds: @[Embed(
            author: EmbedAuthor(
                name: source.username & " transferred currency!",
                icon_url: source.avatarUrl.some
            ).some,
            description: some("```diff\n" &
                source.username.sanitize() & "'s current balance: " &
                $getUserBalance(source.id) & "\n- " & $amount & " currency\n\n" &

                target.username.sanitize() & "'s current balance: " &
                $getUserBalance(target.id) & "\n+ " & $amount & " currency" &
                "```"),
            color: some EmbedColour.success
        )]
    )

proc dailySlash*(s, i): Future[SlashResponse] {.async.} =
    let
        user: User = getUser()
        response = handleUserMoneyReward(user.id)

    if not response[0]:
        return await sendErrorMessage(s, i, USAGE, response[1])

    return SlashResponse(
        embeds: @[Embed(
            author: EmbedAuthor(
                name: &"{user.username} claimed their daily reward!",
                icon_url: user.avatarUrl.some
            ).some,
            description: some response[1],
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
        content: "Triggered image generation",
    )

    # `DiscordFile` cannot be attached to `SlashResponse`, unlike `sendMessage`
    # `Attachment`s are meant to be only be fetched from Discord, i am going insane
    discard discord.api.sendMessage(
        i.channel_id.get(),
        getUser().mentionUser() & " created an image:",
        files = @[DiscordFile(
            name: imageFilePath
        )]
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
proc truthValueSlash*(s, i): Future[SlashResponse] {.async.} = ## TODO: check
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
            author: EmbedAuthor(
                name: user.username & " requested my infinite wisdom",
                icon_url: user.avatarUrl.some
            ).some,
            title: ("The following statement is **" & percent & "** true:").some,
            description: statement.some,
            color: EmbedColour.default.some
        )]
    )

proc loveValueSlash*(s, i): Future[SlashResponse] {.async.} = ## TODO: check
    let
        data = i.data.get()
        userFirst: User = getUser(data.options["first"].user_id)
        userSecond: User = getUser(data.options["second"].user_id)
        percent: string = evaluateStringPercent($(
            userFirst.id.parseInt() + userSecond.id.parseInt()
        ))
    return SlashResponse(
        embeds: @[Embed(
            title: "Love-o-meter".some,
            description: some(userFirst.username.sanitize() & " 💕 " & userSecond.username.sanitize() & " = " & percent),
            color: EmbedColour.default.some
        )]
    )

type AnswerYNM = object
    weight*: int
    answers*: seq[string]
proc yesNoMaybeSlash*(s, i): Future[SlashResponse] {.async.} = ## TODO: check
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
            author: EmbedAuthor(
                name: &"{user.username} requested my infinite wisdom",
                icon_url: user.avatarUrl.some
            ).some,
            title: "Yes No Maybe".some,
            description: some("> " & statement & "\n# " & finalAnswer.capitalize()),
            color: EmbedColour.default.some
        )]
    )

proc profileSlash*(s, i): Future[SlashResponse] {.async.} =
    let
        data = i.data.get()
        target: User = getUser(data.options["user"].user_id)

    # Add emojis next to name:
    var emojis: seq[string]
    if target.bot: emojis.add("🤖")

    # Add fields:
    let inlineSetting: bool = false

    # User field: (guaranteed)
    let userFieldText: seq[string] = @[
        &"**User ID:** {target.id}"
    ]

    # Server field (only added, if user executed on a server):
    var memberField: EmbedField
    if i.member.isSome():
        let
            guild: Guild = await discord.api.getGuild(i.guild_id.get()) #s.cache.guilds[m.guild_id.get()]
            member: Member = await discord.api.getGuildMember(guild.id, target.id)

        # Format Date:
        let
            discordTimeStamp = member.joined_at[0..9]
            dt = parse(discordTimeStamp, "yyyy-MM-dd")
            joinDate = dt.format("dd MMMM yyyy")

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
            let highestRole = guild.roles[member.roles[0]]
            var allRoles: seq[string]
            for id in member.roles:
                try:
                    let role: Role = guild.roles[id]
                    allRoles.add "@" & role.name
                except CatchableError:
                    echo "Unknown role " & id & " in guild " & guild.id
                except Defect:
                    echo "Unknown role " & id & " in guild " & guild.id

            memberFieldText.add(&"**Highest role:** @{highestRole.name}")
            memberFieldText.add("**All roles:** " & allRoles.join(", "))

        memberField = EmbedField(
            name: "Server stats",
            value: memberFieldText.join("\n"),
            inline: inlineSetting.some
        )

    # Begin assembling Embed:
    let avatar: string = block:
        if target.avatarUrl != "": target.avatarUrl
        else: target.defaultAvatarUrl
    var embed = Embed(
        thumbnail: EmbedThumbnail(url: avatar.split("?")[0]).some
    )
    echo avatar

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
        echo target.banner.get()
        embed.image = EmbedImage(url: target.banner.get()).some

    # Add fields:
    embed.fields = @[userField, memberField].some

    # Add colour:
    embed.color = block:
        if target.accent_color.isSome(): target.accent_color.get().some
        else: EmbedColour.default.some

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
            author: EmbedAuthor(
                name: s.user.username & " is comforting you, " & source.username & ". :)",
                icon_url: s.user.avatarUrl.some
            ).some,
            description: "Pat pat, it's okay <3".some,
            image: EmbedImage(
                url: "https://media.tenor.com/dgbF5WN6ujoAAAAC/headpat-cat.gif"
            ).some,
            color: EmbedColour.warning.some
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
        author: EmbedAuthor(
            name: source.username & " gave " & target.username & " a " & operation & "!",
            icon_url: source.avatarUrl.some
        ).some,
        image: EmbedImage(
            url: randomGif
        ).some,
        color: EmbedColour.default.some
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
