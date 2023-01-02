import random, strutils, sequtils
import dimscord
import typedefs


# Main procs:

proc attemptSubstringResponse(substring: SubstringReaction,s: Shard, m: Message) =
    var probability: float = substring.probability
    if probability == 0: probability = 1

    let ranNum: float = rand(1.0)
    if ranNum <= probability:
        discard substring.reactToMessage(s, m)

proc detectSubstringInMessage*(s: Shard, m: Message): bool =
    let messageString: string = m.content
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

SubstringReactionList.add(SubstringReaction(
    trigger: @["banana"],
    emoji: "🍌"
))

SubstringReactionList.add(SubstringReaction(
    trigger: @[
        "fuck", "fick",
        "bitch", "b1tch", "whore", "wh0re", "loser",
        "sex", "secks", "suck", "rape", "lick",
        "dick", "d1ck", "pussy", "pu$$y", "pus$y", "pu$sy", "ass",
        "shit", "piss", "cum"
    ],
    emoji: "👀"
))

SubstringReactionList.add(SubstringReaction(
    trigger: @["wholesome", "wholesum", "holesome", "holesum", "hole sum", "holsum"],
    emoji: "😇"
))

SubstringReactionList.add(SubstringReaction(
    trigger: @["for the gold kind stranger", "for the gold, kind stranger"],
    emoji: "🏅"
))

SubstringReactionList.add(SubstringReaction(
    trigger: @["usa", "u.s.a.", "united states of america", "the united states", "murica"],
    emoji: "🇺🇸"
))

#[
SubstringReactionList.add(SubstringReaction(
    trigger: @["69", "420"],
    emoji: "😏",
    response: "haha funni number"
))
]#

SubstringReactionList.add(SubstringReaction(
    trigger: @["fr fr", "frfr"],
    emoji: "🤨"
))


