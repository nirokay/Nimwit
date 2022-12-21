import typedefs
import commandprocs

# -------------------------------------------------
# System:
# -------------------------------------------------

CommandList.add(Command(
    name: "ping",
    desc: "Get the current ping of the bot.",

    category: SYSTEM,
    call: pingCommand
))

CommandList.add(Command(
    name: "help",
    desc: "Displays a help message.",

    category: SYSTEM,
    alias: @["commands"],
    call: helpCommand
))

CommandList.add(Command(
    name: "docs",
    desc: "Displays a more in-depth documentation about any command.",

    category: SYSTEM,
    alias: @["doc", "documentation"],
    usage: @["[command_name: string]"],
    call: docCommand
))


# -------------------------------------------------
# Math stuff:
# -------------------------------------------------

CommandList.add(Command(
    name: "roll",
    desc: "Rolls a die. Accepts custom side and throw amounts. Rolls a 6-sided die once, if no arguments declared.",

    category: MATH,
    alias: @["die", "dice", "rolldie", "rolldice", "throw"],
    usage: @["[]", "[times: int], [sides: int]", "[times_d_sides: string]"],
    call: rollCommand
))



