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
    except:
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

var currentTopic: CommandCategory


# -------------------------------------------------
# System:
# -------------------------------------------------
currentTopic = SYSTEM

add(Command(
    name: "ping",
    desc: "Gets the current ping/latency of the bot.",

    category: currentTopic,
    call: pingCommand
))

add(Command(
    name: "help",
    desc: "Displays all available, public commands in a list.",

    category: currentTopic,
    alias: @["commands"],
    call: helpCommand
))

# * Testing permissions, remove later:
add(Command(
    name: "admin",
    desc: "Admin Permission Testing",

    category: currentTopic,
    permissions: @[permAdministrator],
    hidden: true,
    serverOnly: true,
    alias: @["adminhelp", "helpadmin"],
    call: helpCommand
))

add(Command(
    name: "docs",
    desc: "Displays in-depth documentation about any command.",

    category: currentTopic,
    alias: @["doc", "documentation"],
    usage: @["[command_name: string]"],
    examples: @["help", "docs", "hug", "ping"],
    call: docCommand
))

add(Command(
    name: "info",
    desc: "Provides information about the bot.",

    category: currentTopic,
    alias: @["botinfo", "bot-info"],
    call: infoCommand
))


# -------------------------------------------------
# Chatting stuff:
# -------------------------------------------------
currentTopic = CHATTING

add(Command(
    name: "hello",
    desc: "I will greet you back :)",

    category: currentTopic,
    alias: @["hi", "hey", "howdy"],
    call: helloCommand
))

add(Command(
    name: "image",
    desc: "Creates an image from a template with custom text. For a list of all images see `imgage list`",

    category: currentTopic,
    alias: @["img", "imagecreate", "createimage", "memegenerator", "mememaker", "makememe"],
    usage: @["[list]", "[image_name: string] [image_text: string]"],
    examples: @["list", "gigachad", "gigachad me when i eat batteries", "nerd guyyyzz pls no tutorials on how to make bombs!"],
    call: evaluateImageCreationRequest
))

add(Command(
    name: "echo",
    desc: "Echoes back the users message content.",

    category: currentTopic,
    alias: @["print", "say", "repeat"],
    usage: @["[statement: string]"],
    examples: @["this will be repeated", "hello world"],
    call: echoCommand
))

add(Command(
    name: "echodel",
    desc: "Same as `echo`, but deletes your command message.",

    category: currentTopic,
    alias: @["echorem", "printdel", "printrem", "saydel", "sayrem", "repeatdel", "repeatrem"],
    usage: @["[statement: string]"],
    examples: @["this will be repeated and command message deleted", "hello world"],
    call: echodelCommand
))

add(Command(
    name: "truth-o-meter",
    desc: "Evaluates the truth-percentage of a given statement.",

    category: currentTopic,
    alias: @["truthometer", "truth", "true"],
    usage: @["[statement: string]"],
    examples: @["this statement will be evaluated", "cats are the best animal"],
    call: truthValueCommand
))

add(Command(
    name: "love-o-meter",
    desc: "Evaluates the amount of love between two users calculated based on their unique discord user IDs.",

    category: currentTopic,
    alias: @["love", "lovers", "luv", "ship", "shipping"],
    usage: @["[user1: @User] (you x them)", "[user1: @User] [user2: @User]"],
    examples: @["@User1 @User2", "@User"],
    call: loveValueCommand
))

add(Command(
    name: "yes-no-maybe",
    desc: "Responds to a question with yes, no or maybe randomly.",

    category: currentTopic,
    alias: @["yesnomaybe", "ynm", "question"],
    usage: @["[statement: string]"],
    examples: @["will i find love?", "are cats superior to dogs?"],
    call: yesnomaybeCommand
))


# -------------------------------------------------
# Social stuff:
# -------------------------------------------------
currentTopic = SOCIAL

add(Command(
    name: "hug",
    desc: "Sends a gif performing this action in a message.",

    category: currentTopic,
    alias: @["cuddle", "snuggle"],
    usage: @["[target_user: @User]"],
    examples: @["@User"],
    call: hugCommand
))

add(Command(
    name: "pat",
    desc: "Sends a gif performing this action in a message.",

    category: currentTopic,
    alias: @["pet", "headpat", "headpet"],
    usage: @["[target_user: @User]"],
    examples: @["@User"],
    call: patCommand
))

add(Command(
    name: "kiss",
    desc: "Sends a gif performing this action in a message.",

    category: currentTopic,
    alias: @["smooch"],
    usage: @["[target_user: @User]"],
    examples: @["@User"],
    call: kissCommand
))

add(Command(
    name: "boop",
    desc: "Sends a gif performing this action in a message.",

    category: currentTopic,
    alias: @["noseboop"],
    usage: @["[target_user: @User]"],
    examples: @["@User"],
    call: boopCommand
))

add(Command(
    name: "slap",
    desc: "Sends a gif performing this action in a message.",

    category: currentTopic,
    alias: @["punch", "beat"],
    usage: @["[target_user: @User]"],
    examples: @["@User"],
    call: slapCommand
))


# -------------------------------------------------
# Math stuff:
# -------------------------------------------------
currentTopic = MATH

add(Command(
    name: "roll",
    desc: "Rolls a die. Accepts custom side and throw amounts. Rolls a 6-sided die once, if no arguments declared.",

    category: currentTopic,
    alias: @["die", "dice", "rolldie", "rolldice", "throw"],
    usage: @["[]", "[times: int], [sides: int]", "[times_d_sides: string]"],
    examples: @["4 20", "4d20", "1d6"],
    call: rollCommand
))

add(Command(
    name: "flip",
    desc: "Flips a coin.",

    category: currentTopic,
    alias: @["flips", "coin", "coinflip"],
    call: flipCommand
))

add(Command(
    name: "flop",
    desc: "Flips... or i guess... flops an unfair coin.",

    category: currentTopic,
    hidden: true,
    call: flopCommand
))

add(Command(
    name: "randomword",
    desc: "Picks a random word from provided arguments (split by spaces).",
    
    category: currentTopic,
    alias: @["random-word", "pickrandomword", "pick-random-word"],
    usage: @["[choice_1: string] ... [choice_n: string]"],
    examples: @["option1 option2 long_option_3 option4"],
    call: pickRandomWordCommand
))

#[
add(Command(
    name: "randomnumber",
    desc: "Picks a random integer in a range of two given numbers. If only one is provided, a random value between it and 0 is chosen.",

    category: MATH,
    alias: @["random-number", "pickrandomnumber", "pick-random-number"],
    usage: @["[maximum: int]", "[minimum: int] [maximum: int]"],
    examples: @["1 100", "99"],
    call: pickRandomNumberCommand
))
]#


# -------------------------------------------------
# Fun stuff:
# -------------------------------------------------
currentTopic = FUN

add(Command(
    name: "acab",
    desc: "Prints **a cab** emoji... get it? Get it?????",

    category: currentTopic,
    hidden: true,
    call: acabCommand
))
