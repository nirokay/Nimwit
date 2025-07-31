import asyncdispatch, options, strutils, strformat, tables
import dimscord
import typedefs, logger, slashprocs, utils, configfile

using
    s: Shard
    i: Interaction


proc getApplicationCommandList*(): seq[ApplicationCommand] =
    for command in SlashCommandList:
        # Permissions:
        let defaultPerms: bool = block:
            if command.permissions.isNone(): true
            elif command.permissions.get().len() == 0: true
            else: false
        var permissionset: set[PermissionFlags]
        if command.permissions.isSome():
            # Idk what I am doing here:
            for perm in command.permissions.get(@[]):
                let tempSet: set[PermissionFlags] = {perm}
                permissionset = permissionset + tempSet

        result.add(ApplicationCommand(
            name: command.name,
            description: command.desc,
            kind: command.kind,
            options: command.options,
            default_permission: some defaultPerms,
            default_member_permissions: if defaultPerms: none set[PermissionFlags] else: some permissionset
        ))

proc sendRuntimeErrorMessage*(s, i; error: ref CatchableError): Future[system.void] {.async.} =
    errorLogger error
    await discord.api.interactionResponseMessage(
        i.id, i.token,
        kind = irtChannelMessageWithSource,
        response = await sendErrorMessage(s, i, INTERNAL, &"A runtime error was caught, detailed information:\n\n**{error.name}**\n{error.msg}")
    )
proc sendRuntimeDefectMessage*(s, i; defect: ref Defect): Future[system.void] {.async.} =
    errorLogger defect
    await discord.api.interactionResponseMessage(
        i.id, i.token,
        kind = irtChannelMessageWithSource,
        response = await sendErrorMessage(s, i, INTERNAL, &"A runtime error was caught, detailed information:\n\n**{defect.name}**\n{defect.msg}")
    )


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
        var response: SlashResponse = await command.call(s, i)

        # Normalize embeds:
        if response.embeds.len() != 0:
            for i, embed in response.embeds:
                # Add default colour, if missing:
                if embed.color.isNone(): response.embeds[i].color = some EmbedColour.default

        await discord.api.interactionResponseMessage(
            i.id, i.token,
            kind = irtChannelMessageWithSource,
            response = response
        )
    # Catch runtime errors/defects:
    except CatchableError as e:
        errorLogger e
        await sendRuntimeErrorMessage(s, i, e)
    except Defect as d:
        errorLogger d
        await sendRuntimeDefectMessage(s, i, d)


proc TODO(s, i): Future[SlashResponse] {.async, used.} =
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
const channelTaskChoices: seq[SlashChoice] = block:
    var r: seq[SlashChoice]
    for task in ServerSettingChannelOption:
        r.add SlashChoice(name: $task, value: (some $task, none int))
    r
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
        choices: channelTaskChoices
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
            kind: acotNumber,
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

# Image:
add SlashCommand(
    name: "image",
    desc: "Creates an image from a template with custom text.",
    category: cat,

    options: @[
        SlashOption(
            kind: acotStr,
            name: "image",
            description: "Choose an image template",
            required: some true,
            choices: getImageListChoices()
        ),
        SlashOption(
            kind: acotStr,
            name: "text",
            description: "Custom text to be put ontop of the image",
            required: some true
        )
    ],

    kind: atSlash,
    call: imageSlash
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
            name: "first",
            description: "First user",
            required: some true
        ),
        SlashOption(
            kind: acotUser,
            name: "second",
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
    call: profileSlash
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

add SlashCommand(
    name: "cat",
    desc: "Requests a random cat image from thecatapi.com!",
    category: cat,

    kind: atSlash,
    call: catApiSlash
)

add SlashCommand(
    name: "dog",
    desc: "Requests a random dog image from thedogapi.com!",
    category: cat,

    kind: atSlash,
    call: dogApiSlash
)


# -------------------------------------------------
# Math stuff:
# -------------------------------------------------
cat = MATH

# Die rolling:
add SlashCommand(
    name: "roll",
    desc: "Rolls a die. Accepts custom side and throw amounts.",
    category: cat,

    options: @[
        SlashOption(
            kind: acotNumber,
            name: "amount",
            description: "How many dice to roll (default: 1x)",
        ),
        SlashOption(
            kind: acotNumber,
            name: "die",
            description: "What die to roll (default: 6-sided die)",
            choices: getDiceRollingChoices()
        )
    ],

    kind: atSlash,
    call: rollSlash
)

# Coin flipping:
add SlashCommand(
    name: "flip",
    desc: "Flips a coin.",
    category: cat,

    kind: atSlash,
    call: flipSlash
)

add SlashCommand(
    name: "flop",
    desc: "Flips... or i guess... flops an unfair coin.",
    category: cat,

    kind: atSlash,
    call: flopSlash
)

# Random word:
add SlashCommand(
    name: "randomword",
    desc: "Picks a random word from provided arguments (split by commas).",
    category: cat,

    options: @[SlashOption(
        kind: acotStr,
        name: "list",
        description: "List of words separated by commas",
        required: some true
    )],

    kind: atSlash,
    call: randomWordSlash
)

# Unit conversions:
for kind, conversions in UnitConversions:
    let call: proc = case kind:
        of "length": convertLengthSlash
        of "area": convertAreaSlash
        of "temperature": convertTemperatureSlash
        of "speed": convertSpeedSlash
        of "mass": convertMassSlash
        of "volume": convertVolumeSlash
        else: TODO
    add SlashCommand(
        name: &"convert-{kind}",
        desc: &"Converts between {kind.capitalize()} units.",
        options: @[
            SlashOption(
                kind: acotNumber,
                name: "number",
                description: "Number",
                required: some true
            ),
            SlashOption(
                kind: acotStr,
                name: "from",
                description: "Convert from this unit",
                required: some true,
                choices: getUnitConversionChoices(kind)
            ),
            SlashOption(
                kind: acotStr,
                name: "to",
                description: "Convert to this unit",
                required: some true,
                choices: getUnitConversionChoices(kind)
            )
        ],
        kind: atSlash,
        call: call
    )
