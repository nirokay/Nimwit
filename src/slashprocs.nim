import std/[strutils, strformat, options, asyncdispatch, tables, json, math]
from unicode import capitalize
import dimscord
import typedefs, configfile, compiledata, userdatahandler, serverdatahandler

using
    s: Shard
    i: Interaction

proc sendErrorMessage*(s, i; error: ErrorType, message: string = "An unknown error occurred."): Future[SlashResponse] {.async.} =
    return SlashResponse(
        embeds: @[Embed(
            title: some &"{($error).toLower().capitalize()} Error",
            description: some message,
            color: some EmbedColour.error
        )]
    )
proc sendErrorMessage*(s, i; error: ErrorType, message, footerMessage: string): Future[SlashResponse] {.async.} =
    var response: SlashResponse = waitFor sendErrorMessage(s, i, error, message)
    if response.embeds.len() != 0:
        response.embeds[0].footer = some EmbedFooter(
            text: footerMessage
        )
    return response

proc mentionUser*[T: string|int](id: T): string =
    return "<@" & $id & ">"
proc mentionUser*(user: User): string =
    return mentionUser(user.id)

template getUser(): User = ## Gets user, does not care if in DMs or on server
    # WTF discord, i spent around an hour debugging and then learned it is a "feature"
    # that `i.user.get()` is `none User` on servers, but `.isSome() == true` in DMs...
    if i.user.isSome(): i.user.get()
    else: i.member.get().user

# Slash Command Procs:

# -------------------------------------------------
# System:
# -------------------------------------------------

proc helpSlash*(s, i): Future[SlashResponse] {.async.} =
    let p: string = $config.prefix
    return SlashResponse(
        content: &"My prefix is `{p}` and you can get a list of all commands with `{p}help`." &
            &"To see detailed documentation about a command, use `{p}docs`!"
    )

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
                source.username & "'s current balance: " &
                $getUserBalance(source.id) & "\n- " & $amount & " currency\n\n" &

                target.username & "'s current balance: " &
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
