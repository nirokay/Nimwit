import os, strutils

var token: string
let token_locations: seq[string] = @[
    "./token.txt", "./private/token.txt", "./src/private/token.txt"
]

proc setDiscordToken*() =
    for file in token_locations:
        if not file.fileExists(): continue
        token = readFile(file)
        break

    # Catch not-set token:
    if token == "":
        echo "Discord token file not found. Please create one in any of these locations:\n" & token_locations.join(" , ")
        quit(1)        


proc getDiscordToken*(): string =
    let tokenCopy: string = token
    token = ""
    return tokenCopy
