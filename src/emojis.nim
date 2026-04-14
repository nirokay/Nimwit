import std/[strformat]

proc newEmoji(name: string, id: int): string =
    result = &"<:{name}:{$id}>"

const
    emojiHypeBrilliance*: string = newEmoji("hype_brilliance", 1493512938164584448)
    emojiHypeBravery*: string = newEmoji("hype_bravery", 1493512923639840811)
    emojiHypeBalance*: string = newEmoji("hype_balance", 1493512888508223579)
