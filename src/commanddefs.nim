import options, strutils
import dimscord
import typedefs, commandprocs, imagegeneration, configfile

proc callCommand(command: Command, s: Shard, m: Message, args: seq[string]): bool =
    # Check for server-only commands being run outside servers:
    if not m.member.isSome and command.serverOnly:
        discard sendErrorMessage(m, USAGE, "You have to use this command on a server.")
        return false

    # TODO Implement this correctly (currently disabled)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Check for permissions when send on servers:
    if m.member.isSome and false:
        for needsPerm in command.permissions:
            echo "Checking " & $needsPerm & " on " & $command.permissions & "\nUser has: " & $m.member.get.permissions
            if contains(m.member.get.permissions, needsPerm): continue
            discard sendErrorMessage(m, PERMISSION, "You need permission `" & $needsPerm & "` to use this command.")
            return false

    # Call command and return success:
    try:
        discard command.call(s, m, args)
    except Exception:
        echo "An error occured!\n" & getCurrentExceptionMsg()
        discard sendErrorMessage(m, INTERNAL, "An error occured whilst performing this request. Please report this issue to the bot maintainer!\nThank you :)")
        return false
    return true

proc attemptCommandExecution(s: Shard, m: Message, args: seq[string]): bool =
    let request = args[0]
    # echo request

    # Search for matching command:
    for command in CommandList:
        # Check for command name:
        if command.name == request:
            return command.callCommand(s, m, args)

        # Check for command alias name:
        for alias in command.alias:
            if alias == request:
                return command.callCommand(s, m, args)
    return false

proc checkForMessageCommand*(s: Shard, m: Message): bool =
    if m.author.bot: return false
    if m.content.len < config.prefix.len: return false

    # Check for prefix:
    if not m.content.startsWith(config.prefix): return false

    # Clean up args:
    let rawArgs: seq[string] = m.content.strip().split(" ")
    var tempArgs: seq[string] = rawArgs
    tempArgs[0] = tempArgs[0].toLower()
    tempArgs[0].delete(0..(len(config.prefix)-1))
    let args = tempArgs

    # Attempt command execution:
    return attemptCommandExecution(s, m, args)

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
    hidden: true,
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
    name: "image",
    desc: "Creates an image from a template with custom text.",

    category: CHATTING,
    alias: @["img", "imagecreate", "createimage", "memegenerator", "mememaker", "makememe"],
    usage: @["[list]", "[image_name: string] [image_text: string]"],
    call: evaluateImageCreationRequest
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
    name: "love-o-meter",
    desc: "Evaluates the amount of love between two users.",

    category: CHATTING,
    alias: @["love", "lovers", "luv", "ship", "shipping"],
    usage: @["[user1: @User] (you x them)", "[user1: @User] [user2: @User]"],
    call: loveValueCommand
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
