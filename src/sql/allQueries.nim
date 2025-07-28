import std/[strutils, strformat, os]

const
    queriesLocation: string = "src" / "sql"
    subdirs: seq[string] = block:
        var r: seq[string]
        for kind, path in walkDir(queriesLocation):
            if kind in [pcFile, pcLinkToFile]: continue
            r.add path
        r
proc readInSql(f: string): string =
    let filename: string = f & (if not f.endsWith(".sql"): ".sql" else: "")

    var content: string
    for subdir in subdirs:
        let filepath: string = subdir / filename
        if filepath.fileExists(): content = filepath.readFile()

    if content == "": raise ValueError.newException(&"Could not find file '{filename}' in subdirectories in '{queriesLocation}'.")
    result = content
    echo &"Read in sql from '{filename}'"

const
    # Get server:
    sqlGetServer* = readInSql("getServer")

    # Get transaction:
    sqlGetTransaction* = readInSql("getTransaction")
    sqlGetTransactionsAll* = readInSql("getTransactionsAll")

    # Get user:
    sqlGetUser* = readInSql("getUser")

    # Create tables:
    sqlInitServers* = readInSql("initServers")
    sqlInitUsers* = readInSql("initUsers")
    sqlInitTransactions* = readInSql("initTransactions")

    # New server:
    sqlNewServer* = readInSql("newServer")

    # New transaction:
    sqlNewTransaction* = readInSql("newTransaction")

    # New user:
    sqlNewUser* = readInSql("newUser")

    # Set server:
    sqlSetServerChannels* = readInSql("setServerChannels")

    # Set user:
    sqlSetUserCurrency* = readInSql("setUserCurrency")
    sqlSetUserCurrencyAdd* = readInSql("setUserCurrencyAdd")
    sqlSetUserCurrencySub* = readInSql("setUserCurrencySub")
    sqlSetUserDaily* = readInSql("setUserDaily")
