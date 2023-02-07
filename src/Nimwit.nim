import strutils, asyncdispatch, options, random, sequtils
import dimscord
import typedefs, configfile, userdatahandler

# -------------------------------------------------
# Initialize commands:
# -------------------------------------------------

include commanddefs, substringdefs


# -------------------------------------------------
# Discord events:
# -------------------------------------------------

# Connected to discord: ---------------------------

proc onReady(s: Shard, r: Ready) {.event(discord).} =
    echo "Ready as " & $r.user & " in " & $r.guilds.len & " guilds!"

    # Init slash commands:
    discard await discord.api.bulkOverwriteApplicationCommands(
        s.user.id,
        @[ApplicationCommand(
            name: "help",
            description: "Provides general help for the bot.",
            kind: atSlash,
            default_permission: true
        )]
    )

    # Update Status:
    discard s.updateStatus(
        activities = @[ActivityStatus(
            name: ".help",
            kind: atPlaying
        )],
        status = "online",
        afk = false
    )

    # User data:
    updateUserData()


# User Interaction incoming: ----------------------

proc interactionCreate(s: Shard, i: Interaction) {.event(discord).} =
    var responseString: string

    let data = get i.data
    case data.name:
    of "help":
        responseString = "My prefix is `" & $config.prefix &
            "` and you can see all available commands with `help` and a detailed documentation on specific commands with `docs`!"
    else: discard

    await discord.api.interactionResponseMessage(i.id, i.token,
        kind = irtChannelMessageWithSource,
        response = InteractionCallbackDataMessage(content: responseString)
    )


# Incoming Message: -------------------------------

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
    discard checkForMessageCommand(s, m)
    discard detectSubstringInMessage(s, m)
    discard handleMoneyTransaction(m.author.id, 1)


# -------------------------------------------------
# Connect to discord:
# -------------------------------------------------

waitFor discord.startSession(
    gateway_intents = {giDirectMessages, giGuildMessages, giGuilds, giGuildMembers, giMessageContent}
)

