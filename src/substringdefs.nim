import random, strutils, sequtils, asyncdispatch, options
import dimscord
import typedefs


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
    var probability: float = substring.probability
    if probability == 0: probability = 1

    let ranNum: float = rand(1.0)
    if ranNum <= probability:
        discard substring.reactToMessage(s, m)

proc detectSubstringInMessage*(s: Shard, m: Message): bool =
    let messageString: string = " " & m.content & " "
    var varMessageString: string
    # Find substrings:
    var detectedSubstrings: seq[SubstringReaction]
    for substring in SubstringReactionList:
        # Convert to lower, if not case-sensitive:
        varMessageString = messageString
        if not substring.caseSensitive: varMessageString = messageString.toLower()

        # Loop through and check if triggers are in the message:
        for trigger in substring.trigger:
            if varMessageString.contains(trigger): detectedSubstrings.add(substring)
    
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

add(SubstringReaction(
    trigger: @["banana"],
    emoji: "🍌"
))

add(SubstringReaction(
    trigger: @[
        "fuck", "fick",
        "bitch", "b1tch", "whore", "wh0re", "loser",
        "sex", "secks", "suck", "rape", "lick",
        "dick", "d1ck", "pussy", "pu$$y", "pus$y", "pu$sy", "ass",
        "shit", "piss", "cum"
    ],
    emoji: "👀"
))

add(SubstringReaction(
    trigger: @["wholesome", "wholesum", "holesome", "holesum", "hole sum", "holsum"],
    emoji: "😇"
))

add(SubstringReaction(
    trigger: @["for the gold kind stranger", "for the gold, kind stranger"],
    emoji: "🏅"
))

add(SubstringReaction(
    trigger: @[" usa ", "u.s.a.", "united states of america", "the united states", "murica"],
    emoji: "🇺🇸"
))

add(SubstringReaction(
    trigger: @[" 69 ", " 420 ", "6969", "42069", "69420"],
    response: "haha funni number",
    emoji: "😏"
))

add(SubstringReaction(
    trigger: @["fr fr", "frfr"],
    emoji: "🤨"
))


