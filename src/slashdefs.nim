import asyncdispatch, options, strutils, strformat
import dimscord
import typedefs, logger, slashprocs

using
    s: Shard
    i: Interaction


proc getApplicationCommandList*(): seq[ApplicationCommand] =
    for command in SlashCommandList:
        # Permissions:
        let defaultPerms: bool = command.permissions.isNone()
        var permissionset: set[PermissionFlags]
        if command.permissions.isSome():
            # Idk what I am doing here:
            for perm in command.permissions.get():
                let tempSet: set[PermissionFlags] = {perm}
                permissionset = permissionset + tempSet

        result.add(ApplicationCommand(
            name: command.name,
            description: command.desc,
            kind: command.kind,
            options: command.options,
            default_permission: some defaultPerms,
            default_member_permissions: some permissionset
        ))

proc handleSlashInteraction*(s, i): Future[system.void] {.async.} =
    let data = i.data.get()

    # Get requested command:
    var command: SlashCommand
    for cmd in SlashCommandList:
        if cmd.name == data.name:
            command = cmd
            break

    # No command found (should *normally* not happen):
    if command.name == "":
        await discord.api.interactionResponseMessage(
            i.id, i.token,
            kind = irtChannelMessageWithSource,
            response = SlashResponse(
                content: &"The requested command '{data.name}' was not found. This is most likely a discord error."
            )
        )
        return

    # Check if server-only command:
    if i.guild_id.isNone() and command.serverOnly:
        await discord.api.interactionResponseMessage(
            i.id, i.token,
            kind = irtChannelMessageWithSource,
            response = await sendErrorMessage(s, i, USAGE, "This command can only be executed on servers.")
        )
        return

    # Call command:
    try:
        await discord.api.interactionResponseMessage(
            i.id, i.token,
            kind = irtChannelMessageWithSource,
            response = await command.call(s, i)
        )
    # Catch runtime errors:
    except Exception as e:
        logger e
        await discord.api.interactionResponseMessage(
            i.id, i.token,
            kind = irtChannelMessageWithSource,
            response = await sendErrorMessage(s, i, INTERNAL, &"A runtime error was caught, detailed information:\n\n**{e.name}**\n{e.msg}")
        )
        return

proc TODO(s, i): Future[SlashResponse] {.async, deprecated: "expected implementation".} =
    return SlashResponse(
        content: "Implementation missing, see this command in the future!"
    )

# Add commands:
var cat: CommandCategory
proc add(command: SlashCommand) =
    SlashCommandList.add(command)


# -------------------------------------------------
# System:
# -------------------------------------------------
cat = SYSTEM

# General:
add SlashCommand(
    name: "help",
    desc: "Provides general information about the bot",
    category: cat,

    kind: atSlash,
    call: helpSlash
)

add SlashCommand(
    name: "info",
    desc: "Provides information about the bot.",
    category: cat,

    kind: atSlash,
    call: infoSlash
)

# Settings:
add SlashCommand(
    name: "settings",
    desc: "See the current server settings",
    category: cat,

    serverOnly: true,
    permissions: some @[permManageChannels],

    kind: atSlash,
    call: displaySettingsSlash
)
add SlashCommand(
    name: "setchannel",
    desc: "Assign task to current channel",
    category: cat,

    serverOnly: true,
    permissions: some @[permManageChannels],

    options: @[SlashOption(
        kind: acotStr,
        name: "task",
        description: "Choose task for this channel",
        required: some true,
        choices: @[
            SlashChoice(name: $settingWelcomeMessages, value: (some $settingWelcomeMessages, none int)),
            SlashChoice(name: $settingUserChanges,     value: (some $settingUserChanges,     none int)),
            SlashChoice(name: $settingMessageLogging,  value: (some $settingMessageLogging,  none int))
        ]
    )],
    kind: atSlash,
    call: modifySettingSlash
)


# -------------------------------------------------
# Economy stuff:
# -------------------------------------------------
cat = ECONOMY

# See currency:
add SlashCommand(
    name: "balance",
    desc: "See a users balance.",
    category: cat,

    options: @[SlashOption(
        kind: acotUser,
        name: "user",
        description: "Target user to see balance of",
        required: some true
    )],

    kind: atSlash,
    call: balanceSlash
)

# Transfer currency:
add SlashCommand(
    name: "transfer",
    desc: "Transfer currency to another user",
    category: cat,

    options: @[
        SlashOption(
            kind: acotUser,
            name: "user",
            description: "Target user to transfer currency to",
            required: some true
        ),
        SlashOption(
            kind: acotNumber, # TODO: change this to string, API always returns `0.0` for number
            name: "amount",
            description: "Amount of currency to transfer",
            required: some true
        )
    ],

    kind: atSlash,
    call: transferMoneySlash
)

# Get daily reward:
add SlashCommand(
    name: "daily",
    desc: "Claim your daily currency; the amount grows with your daily streak.",
    category: cat,

    kind: atSlash,
    call: dailySlash
)


# -------------------------------------------------
# Chatting stuff:
# -------------------------------------------------
cat = CHATTING

# Echo:
add SlashCommand(
    name: "echomessage",
    desc: "Echoes back anything that you say!",
    category: cat,

    options: @[SlashOption(
        kind: acotStr,
        name: "message",
        description: "This string will be sent as a message",
        required: some true
    )],

    kind: atSlash,
    call: echoSlash
)

# Evaluations:
add SlashCommand(
    name: "truth-o-meter",
    desc: "Evaluates the truth-percentage of a given statement.",
    category: cat,

    options: @[SlashOption(
        kind: acotStr,
        name: "statement",
        description: "Statement to evaluate",
        required: some true
    )],

    kind: atSlash,
    call: truthValueSlash
)

add SlashCommand(
    name: "love-o-meter",
    desc: "Evaluates the amount of love between two users calculated based on their unique discord user IDs.",
    category: cat,

    options: @[
        SlashOption(
            kind: acotUser,
            name: "firstUser",
            description: "First user",
            required: some true
        ),
        SlashOption(
            kind: acotUser,
            name: "secondUser",
            description: "Second user",
            required: some true
        )
    ],

    kind: atSlash,
    call: loveValueSlash
)

add SlashCommand(
    name: "ynm",
    desc: "Responds to a question with yes, no or maybe randomly.",
    category: cat,

    options: @[SlashOption(
        kind: acotStr,
        name: "statement",
        description: "Statement to evaluate",
        required: some true
    )],

    kind: atSlash,
    call: yesNoMaybeSlash
)


# -------------------------------------------------
# Social stuff:
# -------------------------------------------------
cat = SOCIAL

# Profile:
add SlashCommand(
    name: "profile",
    desc: "Displays the users profile and some additional information.",
    category: cat,

    options: @[SlashOption(
        kind: acotUser,
        name: "user",
        description: "Display this users profile",
        required: some true
    )],

    kind: atSlash,
    call: TODO
)

# Action @ user commands:
add SlashCommand(
    name: "hug",
    desc: "Sends a gif performing this action in a message.",
    category: cat,

    options: @[SlashOption(
        kind: acotUser,
        name: "user",
        description: "User to hug",
        required: some true
    )],

    kind: atSlash,
    call: hugSlash
)

add SlashCommand(
    name: "pat",
    desc: "Sends a gif performing this action in a message.",
    category: cat,

    options: @[SlashOption(
        kind: acotUser,
        name: "user",
        description: "User to pat",
        required: some true
    )],

    kind: atSlash,
    call: patSlash
)

add SlashCommand(
    name: "kiss",
    desc: "Sends a gif performing this action in a message.",
    category: cat,

    options: @[SlashOption(
        kind: acotUser,
        name: "user",
        description: "User to kiss",
        required: some true
    )],

    kind: atSlash,
    call: kissSlash
)

add SlashCommand(
    name: "boop",
    desc: "Sends a gif performing this action in a message.",
    category: cat,

    options: @[SlashOption(
        kind: acotUser,
        name: "user",
        description: "User to nose boop",
        required: some true
    )],

    kind: atSlash,
    call: boopSlash
)

add SlashCommand(
    name: "slap",
    desc: "Sends a gif performing this action in a message.",
    category: cat,

    options: @[SlashOption(
        kind: acotUser,
        name: "user",
        description: "User to slap",
        required: some true
    )],

    kind: atSlash,
    call: slapSlash
)


# -------------------------------------------------
# Math stuff:
# -------------------------------------------------
cat = MATH

# Die rolling:
add SlashCommand(
    name: "roll",
    desc: "Rolls a die. Accepts custom side and throw amounts. Rolls a 6-sided die once, if no arguments declared.",
    category: cat,

    # TODO: Options as numbers would be fucked here

    kind: atSlash,
    call: TODO
)

# Coin flipping:
add SlashCommand(
    name: "flip",
    desc: "Flips a coin.",
    category: cat,

    kind: atSlash,
    call: TODO
)

add SlashCommand(
    name: "flop",
    desc: "Flips... or i guess... flops an unfair coin.",
    category: cat,

    kind: atSlash,
    call: TODO
)

# Random word:
add SlashCommand(
    name: "randomword",
    desc: "Picks a random word from provided arguments (split by spaces).",
    category: cat,

    options: @[SlashOption(
        kind: acotStr,
        name: "list",
        description: "List of words separated by spaces",
        required: some true
    )],

    kind: atSlash,
    call: TODO
)
