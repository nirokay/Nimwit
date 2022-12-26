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
# Chatting stuff:
# -------------------------------------------------

add(Command(
    name: "hello",
    desc: "I will greet you back :)",

    category: CHATTING,
    alias: @["hi", "hey", "howdy"],
    call: helloCommand
))

add(Command(
    name: "echo",
    desc: "Say something and I will say it back!",

    category: CHATTING,
    alias: @["print", "say", "repeat"],
    usage: @["[statement: string]"],
    call: echoCommand
))

add(Command(
    name: "echodel",
    desc: "Same as `echo`, but deletes your command message.",

    category: CHATTING,
    alias: @["echorem", "printdel", "printrem", "saydel", "sayrem", "repeatdel", "repeatrem"],
    usage: @["[statement: string]"],
    call: echodelCommand
))

add(Command(
    name: "truth-o-meter",
    desc: "Evaluates the truth-percentage of a given statement.",

    category: CHATTING,
    alias: @["truthometer", "truth", "true"],
    usage: @["[statement: string]"],
    call: truthValueCommand
))

add(Command(
    name: "yes-no-maybe",
    desc: "Ask me a question and I will answer with yes, no or maybe.",

    category: CHATTING,
    alias: @["yesnomaybe", "ynm", "question"],
    usage: @["[statement: string]"],
    call: yesnomaybeCommand
))


# -------------------------------------------------
# Social stuff:
# -------------------------------------------------

add(Command(
    name: "hug",
    desc: "Sends a gif performing this action in a message.",

    category: SOCIAL,
    alias: @["cuddle", "snuggle"],
    usage: @["[target_user: @User]"],
    call: hugCommand
))

add(Command(
    name: "pat",
    desc: "Sends a gif performing this action in a message.",

    category: SOCIAL,
    alias: @["pet", "headpat", "headpet"],
    usage: @["[target_user: @User]"],
    call: patCommand
))

add(Command(
    name: "kiss",
    desc: "Sends a gif performing this action in a message.",

    category: SOCIAL,
    alias: @["smooch"],
    usage: @["[target_user: @User]"],
    call: kissCommand
))

add(Command(
    name: "boop",
    desc: "Sends a gif performing this action in a message.",

    category: SOCIAL,
    alias: @["noseboop"],
    usage: @["[target_user: @User]"],
    call: boopCommand
))

add(Command(
    name: "slap",
    desc: "Sends a gif performing this action in a message.",

    category: SOCIAL,
    alias: @["punch", "beat"],
    usage: @["[target_user: @User]"],
    call: slapCommand
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
