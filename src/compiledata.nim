import std/[times, math, strutils, strformat]

const
    versionMajor: int = 2 ## major code changes, rewrites, etc.
    versionMinor: int = 5 ## new command or functionality impacting user behaviour
    versionPatch: int = 1 ## patches and background stuff, which is small in size
    BotVersion*: string = &"{versionMajor}.{versionMinor}.{versionPatch}"
let ExecuteUnixTime: int = epochTime().int


# Bot upkeep timer:

proc addPretty(str: var string, value: int, unit: string) =
    if value <= 0: return
    str.add($value & unit & " ")

proc botRunningTimeSeconds*(): int =
    let now: int = epochTime().int
    return now - ExecuteUnixTime

proc botRunningTimePretty*(): string =
    let s: int = botRunningTimeSeconds()
    let
        secs:  int = s mod 60
        mins:  int = floor(s / 60).int mod 60
        hours: int = floor(s / 3600).int mod 24
        days:  int = floor(s / 86400).int

    var str: string
    str.addPretty(days,  "d")
    str.addPretty(hours, "h")
    str.addPretty(mins,  "m")
    str.addPretty(secs,  "s")
    return str.strip()
