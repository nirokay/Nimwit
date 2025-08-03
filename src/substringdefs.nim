import random, strutils, sequtils, asyncdispatch, options
import dimscord
import typedefs
#import fatherfigure

const toWhitespace: string = ",.;:-_–…\"'?!()[]{}&$€" ## each char gets replaced with ' '


# Main procs:

proc reactToMessage(substring: SubstringReaction, s: Shard, m: Message): Future[system.void] {.async.} =
    if substring.emoji != "":
        discard discord.api.addMessageReaction(
            m.channel_id,
            m.id,
            substring.emoji
        )
    if substring.response != "":
        discard await discord.api.sendMessage(
            m.channel_id,
            substring.response
        )

proc attemptSubstringResponse(substring: SubstringReaction,s: Shard, m: Message) =
    let
        probability: float = if substring.probability > 0.0: substring.probability else: 1.0
        ranNum: float = rand(1.0)

    if ranNum <= probability:
        discard substring.reactToMessage(s, m)

proc detectSubstringInMessage*(s: Shard, m: Message): bool =
    let messageString: string = block:
        var r: string = " " & m.content & " "
        for c in toWhitespace:
            r = r.replace(c, ' ')
        r
    var varMessageString: string
    # Find substrings:
    var detectedSubstrings: seq[SubstringReaction]
    for substring in SubstringReactionList:
        # Convert to lower, if not case-sensitive:
        varMessageString = messageString
        if not substring.caseSensitive: varMessageString = messageString.toLower()

        # Loop through and check if triggers are in the message:
        for trigger in substring.trigger:
            let t = if substring.caseSensitive: trigger else: trigger.toLower()
            if varMessageString.contains(t): detectedSubstrings.add(substring)

    # Call reaction procs:
    let substringsToCall: seq[SubstringReaction] = detectedSubstrings.deduplicate()
    for substring in substringsToCall:
        substring.attemptSubstringResponse(s, m)

    # Return bool depending, if substrings were found:
    if substringsToCall.len == 0: result = false
    else: result = true
    return result


# Add to list:
proc add(reaction: SubstringReaction) =
    SubstringReactionList.add(reaction)

add SubstringReaction(
    name: "Banana reaction",
    trigger: @["banana"],
    emoji: "🍌"
)

add SubstringReaction(
    name: "ACAB gets reacted with 'a cab'... get it????",
    trigger: @[" acab ", " a c a b ", " 1312 "],
    emoji: "🚕"
)

add SubstringReaction(
    name: "Profanity reactions",
    trigger: @[
        # English:
        "fuck", " pounding ", " piping ", " goon ", " gooning ",
        " bitch", " whore", " whoring ", " slut",
        "sex", "secks", "seggs",
        " suck", " lick", " jerk", " stroking ",
        " penis ", " dick", " cock", " balls ",
        " pussy ", " cunt",
        " ass", " arse",
        " shit", " piss", " pee", " cum", " smegma ", " poop", " poo ", " squirt",
        " slurp", " sloppy ", " swallow",
        " kys ", " kill yourself ",

        # German:
        " fick",
        " schlampe", " hure",
        " arsch",
        " seggs ", " leck",
        " schwanz ",
        " scheiße", " scheisze", " scheisse", " scheise"
    ],
    emoji: "👀"
)

add SubstringReaction(
    name: "Fascist shit",
    trigger: @[
        " AfD ", " AgD ",
        " NPD ",
        " CDU ", " CSU ", " CxU ",
        " Söder ", " Soeder ", " Weidel ", " Merz "
    ],
    emoji: "🤢"
)

add SubstringReaction(
    name: "Making fun of fascists",
    trigger: @[
        " die grünen ", " die grüne "
    ],
    emoji: "🤬"
)

add SubstringReaction(
    name: "Wholesome",
    trigger: @[" wholesome ", " wholesum ", " whole sum ", " holesome ", " holesum ", " hole sum ", " holsum "],
    emoji: "😇"
)

add SubstringReaction(
    name: "Reddit",
    trigger: @[" for the gold kind stranger "],
    emoji: "🏅"
)

add SubstringReaction(
    name: "USA",
    trigger: @[" usa ", " united states of america ", " the united states ", " murica", " america"],
    emoji: "🇺🇸"
)

add SubstringReaction(
    name: "Funny numbers",
    trigger: @[" 69 ", " 420 ", "6969", "42069", "69420"],
    response: "haha funni number",
    emoji: "😏"
)

add SubstringReaction(
    name: "frfr",
    trigger: @[" fr fr ", " frfr ", " for real for real "],
    emoji: "🤨"
)

add SubstringReaction(
    name: "Cat",
    trigger: @[
        # Spanish:
        " el gato ", " el gatitio ",
        # English:
        " the cat ", " the kitten ", " the kitty ",
        # German:
        " die Katze ", " der Kater ", " das Kätzchen "
    ],
    emoji: "🐈"
)

add SubstringReaction(
    name: "Linux copypasta",
    trigger: @[
        " linux "
    ],
    probability: 0.05,
    emoji: "‼️",
    response: """I'd just like to interject for a moment. What you're referring to as Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, GNU plus Linux. Linux is not an operating system unto itself, but rather another free component of a fully functioning GNU system made useful by the GNU corelibs, shell utilities and vital system components comprising a full OS as defined by POSIX.

Many computer users run a modified version of the GNU system every day, without realizing it. Through a peculiar turn of events, the version of GNU which is widely used today is often called Linux, and many of its users are not aware that it is basically the GNU system, developed by the GNU Project.

There really is a Linux, and these people are using it, but it is just a part of the system they use. Linux is the kernel: the program in the system that allocates the machine's resources to the other programs that you run. The kernel is an essential part of an operating system, but useless by itself; it can only function in the context of a complete operating system. Linux is normally used in combination with the GNU operating system: the whole system is basically GNU with Linux added, or GNU/Linux. All the so-called Linux distributions are really distributions of GNU/Linux!"""
)
