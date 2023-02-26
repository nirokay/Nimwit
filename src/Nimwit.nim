import strutils, strformat, asyncdispatch, options, random, sequtils
import dimscord
import typedefs, configfile, userdatahandler

# -------------------------------------------------
# Initialize commands:
# -------------------------------------------------

include commanddefs, substringdefs, slashdefs, slashprocs


# -------------------------------------------------
# Discord events:
# -------------------------------------------------

# Connected to discord: ---------------------------

proc onReady(s: Shard, r: Ready) {.event(discord).} =
    # Errors:
    if config.prefix.len() == 0:
        echo "Prefix cannot be empty! Set a valid prefix in configfile."
        quit(1)
    
    # Ready message and begin loading/setup:
    echo &"Ready as {$r.user} in {r.guilds.len()} guilds!"

    # Init slash commands:
    discard await discord.api.bulkOverwriteApplicationCommands(
        s.user.id,
        getApplicationCommandList()
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
    discard handleSlashInteraction(s, i)


# Incoming Message: -------------------------------

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
    # User and bot commands:
    # wow so empty

    # From here on only user commands:
    if m.author.bot: return

    if not checkForMessageCommand(s, m):
        # Only gain money if it was not a command:
        discard handleMoneyTransaction(m.author.id, config.moneyGainPerMessage)
    discard detectSubstringInMessage(s, m)


# -------------------------------------------------
# Connect to discord:
# -------------------------------------------------

waitFor discord.startSession(
    gateway_intents = {giDirectMessages, giGuildMessages, giGuilds, giGuildMembers, giMessageContent}
)

