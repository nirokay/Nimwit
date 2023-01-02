import strutils, asyncdispatch, options, random, sequtils
import dimscord
import typedefs, configfile

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
    discard await discord.api.bulkOverwriteApplicationCommands(
        s.user.id,
        @[ApplicationCommand(
            name: "help",
            description: "Provides general help for the bot.",
            kind: atSlash,
            default_permission: true
        )]
    )


# User Interaction incoming: ----------------------

proc interactionCreate(s: Shard, i: Interaction) {.event(discord).} =
    # Literally only to give information on how to NOT use slash commands! :)
    await discord.api.interactionResponseMessage(i.id, i.token,
        kind = irtChannelMessageWithSource,
        response = InteractionCallbackDataMessage(content:
            "My prefix is `" &
            $config.prefix &
            "` and you can see all available commands with `help` and a detailed documentation on specific commands with `docs`!"
        )
    )


# Incoming Message: -------------------------------

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
    discard checkForMessageCommand(s, m)
    discard detectSubstringInMessage(s, m)


# -------------------------------------------------
# Connect to discord:
# -------------------------------------------------

waitFor discord.startSession(
    gateway_intents = {giDirectMessages, giGuildMessages, giGuilds, giGuildMembers, giMessageContent}
)

