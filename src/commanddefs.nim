import dimscord
import typedefs, commandprocs

proc add(command: Command) =
    CommandList.add(command)

# -------------------------------------------------
# System:
# -------------------------------------------------

add(Command(
    name: "ping",
    desc: "Get the current ping of the bot.",

    category: SYSTEM,
    call: pingCommand
))

add(Command(
    name: "help",
    desc: "Displays all available, public commands.",

    category: SYSTEM,
    alias: @["commands"],
    call: helpCommand
))

# * Testing permissions, remove later:
add(Command(
    name: "admin",
    desc: "Admin Permission Testing",

    category: SYSTEM,
    permissions: @[permAdministrator],
    serverOnly: true,
    alias: @["adminhelp", "helpadmin"],
    call: helpCommand
))

add(Command(
    name: "docs",
    desc: "Displays in-depth documentation about any command.",

    category: SYSTEM,
    alias: @["doc", "documentation"],
    usage: @["[command_name: string]"],
    call: docCommand
))


# -------------------------------------------------
# Social stuff:
# -------------------------------------------------

add(Command(
    name: "hello",
    desc: "I will greet you back :)",

    category: SOCIAL,
    alias: @["hi", "hey", "howdy"],
    call: helloCommand
))


# -------------------------------------------------
# Social stuff:
# -------------------------------------------------

add(Command(
    name: "echo",
    desc: "Say something and I will say it back!",

    category: CHATTING,
    alias: @["print", "say", "repeat"],
    call: echoCommand
))

add(Command(
    name: "echodel",
    desc: "Same as `echo`, but deletes your command message.",

    category: CHATTING,
    alias: @["echorem", "printdel", "printrem", "saydel", "sayrem", "repeatdel", "repeatrem"],
    call: echodelCommand
))


# -------------------------------------------------
# Math stuff:
# -------------------------------------------------

add(Command(
    name: "roll",
    desc: "Rolls a die. Accepts custom side and throw amounts. Rolls a 6-sided die once, if no arguments declared.",

    category: MATH,
    alias: @["die", "dice", "rolldie", "rolldice", "throw"],
    usage: @["[]", "[times: int], [sides: int]", "[times_d_sides: string]"],
    call: rollCommand
))

add(Command(
    name: "flip",
    desc: "Flips a coin.",

    category: MATH,
    alias: @["flips", "coin", "coinflip"],
    call: flipCommand
))

add(Command(
    name: "flop",
    desc: "Flips... or i guess... flops an unfair coin.",

    category: MATH,
    hidden: true,
    call: flopCommand
))

add(Command(
    name: "randomword",
    desc: "Picks a random word from provided arguments (split by spaces).",
    
    category: MATH,
    alias: @["random-word", "pickrandom", "pick-random"],
    usage: @["[choice_1: string] ... [choice_n: string]"],
    call: pickRandomCommand
))

add(Command(
    name: "truth-o-meter",
    desc: "Evaluates the truth-percentage of a given statement.",

    category: MATH,
    alias: @["truthometer", "truth", "true"],
    usage: @["[statement: string]"],
    call: truthValueCommand
))


# -------------------------------------------------
# Fun stuff:
# -------------------------------------------------

add(Command(
    name: "acab",
    desc: "Prints **a cab** emoji... get it? Get it?????",

    category: FUN,
    hidden: true,
    call: acabCommand
))
