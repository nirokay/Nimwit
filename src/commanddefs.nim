import dimscord
import typedefs, commandprocs

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
    desc: "Displays all available, public commands.",

    category: SYSTEM,
    alias: @["commands"],
    call: helpCommand
))

# * Testing permissions:
CommandList.add(Command(
    name: "admin",
    desc: "Admin Permission Testing",

    category: SYSTEM,
    permissions: @[permAdministrator],
    serverOnly: true,
    alias: @["adminhelp", "helpadmin"],
    call: helpCommand
))

CommandList.add(Command(
    name: "docs",
    desc: "Displays in-depth documentation about any command.",

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

CommandList.add(Command(
    name: "flip",
    desc: "Flips a coin.",

    category: MATH,
    alias: @["flips", "coin", "coinflip"],
    call: flipCommand
))

CommandList.add(Command(
    name: "flop",
    desc: "Flips... or i guess... flops an unfair coin.",

    category: MATH,
    hidden: true,
    call: flopCommand
))

CommandList.add(Command(
    name: "pickrandom",
    desc: "Picks a random word from provided arguments (split by spaces).",
    
    category: MATH,
    alias: @["pick-random", "randomword", "random-word"],
    usage: @["[choice_1: string] ... [choice_n: string]"],
    call: pickRandomCommand
))


# -------------------------------------------------
# Fun stuff:
# -------------------------------------------------

CommandList.add(Command(
    name: "acab",
    desc: "Prints **a cab** emoji... get it? Get it?????",

    category: FUN,
    hidden: true,
    call: acabCommand
))
