import std/[strutils, strformat, sequtils, options]
from unicode import capitalize
import dimscord
import ../typedefs, ../substringdefs, ../slashdefs

proc paragraphSlashOption(option: SlashOption): seq[string] =
    result = @[
        &"* `{option.name}`" & (
            if option.required == some true: " (*required*)"
            else: ""
        ),
        "",
        &"**Description:** {option.description}",
        ""
    ]

    # Choices:
    if option.choices.len() != 0:
        result.add "**Choices:**\n"
        for choice in option.choices:
            result.add &"  * `{choice.name}`"

    # Recursive options:
    if option.options.len() != 0:
        for o in option.options:
            result.add o.paragraphSlashOption().join("\n").indent(2)
proc paragraphSlashCommand(command: SlashCommand): seq[string] =
    result = @[
        &"### Command `/{command.name}`" & (
            if not command.serverOnly: ""
            else: " (*server only*)"
        ),
        "",
        &"**Category:** {toLower($command.category).capitalize()}",
        "",
        &"**Description:** {command.desc}",
        ""
    ]

    block commandPermissions:
        if command.permissions.isSome():
            let perms: seq[PermissionFlags] = command.permissions.get()
            if perms.len() == 0: break commandPermissions

            result.add "**Required permissions:**"
            for perm in perms:
                result.add &"* `{perm}`"
            result.add ""

    if command.options.len() != 0:
        result.add "**Options:**\n"
        for option in command.options:
            result.add option.paragraphSlashOption().join("\n").indent(2)
        result.add ""

proc paragraphSubstring(reaction: SubstringReaction): seq[string] =
    result = @[
        &"### {reaction.name}",
        "",
        "**Trigger prerequisites:**",
        "",
        "Any of the following substrings...",
        ""
    ]

    for trigger in reaction.trigger:
        result.add &"* `{trigger}`"
    result.add ""

    result.add "... will be reacted to with:"
    result.add ""

    if reaction.emoji != "":
        result.add &"* Emoji: {reaction.emoji}"
    if reaction.response != "":
        let normalised: string = "> " & reaction.response.strip().replace("\n", "\n> ")
        result.add &"* Response:\n{normalised.indent(2)}"
    result.add ""

    let probability: string = &"{reaction.probability * 100}%"
    if reaction.probability > 0.0:
        result.add &"with a {probability} chance!"
        result.add ""


# =============================================================================


const filepath: string = "docs/Commands.md"

var lines: seq[string] = @[
    "# Nimwit command reference",
    "",
    "This is a list of all available commands for Nimwit.",
    ""
]

lines.add "## Slash Commands"
lines.add ""

for command in SlashCommandList:
    lines.add command.paragraphSlashCommand().join("\n")


lines.add "## Substring Reactions"
lines.add ""

for reaction in SubstringReactionList:
    lines.add reaction.paragraphSubstring().join("\n")

filepath.writeFile(lines.join("\n"))
