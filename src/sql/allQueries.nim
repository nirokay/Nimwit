import std/[strutils, strformat]

const queriesLocation: string = "src/sql/"
proc readInSql(f: static string): static string =
    let
        file: string = queriesLocation & f & (if not f.endsWith(".sql"): ".sql" else: "")
        content: string = file.readFile()
    result = content
    echo &"Read in sql from '{file}'"

const
    # Get server:
    sqlGetServer = readInSql("getServer")

    # Get user:
    sqlGetUser = readInSql("getUser")
    sqlGetUserCurrency = readInSql("getUserCurrency")
    sqlGetDailyLast = readInSql("getDailyLast")
    sqlGetDailyStreak = readInSql("getDailyStreak")

    # Create tables:
    sqlInitServers = readInSql("initServers")
    sqlInitUsers = readInSql("initUsers")
    sqlInitTransactions = readInSql("initTransactions")

    # Set server:

    # Set user:
    sqlSetUserAddCurrency = readInSql("setUserAddCurrency")
    sqlSetUserCurrency = readInSql("setUserCurrency")
    sqlSetUserDaily = readInSql("setUserDaily")
