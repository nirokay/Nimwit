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
                let tempset: set[PermissionFlags] = {perm}
                permissionset = permissionset + tempset

        result.add(ApplicationCommand(
            name: command.name,
            description: command.desc,
            kind: command.kind,
            options: command.options,
            default_permission: defaultPerms,
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


# Add commands:
var cat: CommandCategory
proc add(command: SlashCommand) =
    SlashCommandList.add(command)


# -------------------------------------------------
# System:
# -------------------------------------------------
cat = SYSTEM

add SlashCommand(
    name: "help",
    desc: "Provides general information about the bot",
    category: cat,

    kind: atSlash,
    call: helpSlash
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
# Chatting stuff:
# -------------------------------------------------
cat = CHATTING

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
