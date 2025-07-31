## Almost automated JSON -> SQLite transfer script
## ===============================================
##
## Some changes to JSON need to be done, for example renaming the channel task keys in servers.json and replacing `null` with `{}`.
##
## Similarly users.json needs replacement to new default values `null` to `0` and `19700101`.

import std/[json, tables, strformat, strutils]
import ../src/[typedefs]

let
    servers: Table[string, ServerDataObject] = readFile(DataLocation[fileServers]).parseJson().to(Table[string, ServerDataObject])
    users: Table[string, UserDataObject] = readFile(DataLocation[fileUsers]).parseJson().to(Table[string, UserDataObject])

var sqlCommands: tuple[users: seq[string], servers: seq[string]]


for id, user in users:
    sqlCommands.users.add &"INSERT INTO users (id, currency, dailyLast, dailyStreak) VALUES({id}, {user.money}, {user.lastDailyReward}, {user.currentDailyStreak});"

for id, server in servers:
    let channels: string = $ % server.channels
    sqlCommands.servers.add &"INSERT INTO servers (id, channels) VALUES({id}, '{channels}');"

echo "SQL users:"
echo sqlCommands.users.join("\n")
echo "SQL servers:"
echo sqlCommands.servers.join("\n")
