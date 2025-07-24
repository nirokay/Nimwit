import std/[strutils, json]
import db_connector/db_sqlite, dimscord
import typedefs, utils, logger

import sql/allQueries
export allQueries

const
    dbPath: string = "private/data/database.db"

proc getDatabase(): DbConn =
    result = open(dbPath, "", "", "")

template withDatabase*(db: untyped, body: untyped): untyped =
    ## Template to avoid writing repetitive code
    let db: DbConn = getDatabase()
    db.exec(sql"BEGIN TRANSACTION")
    var success: bool = true
    try:
        body
        success = true
    except CatchableError as e:
        success = false
        errorLogger e
    finally:
        try:
            if success: db.exec(sql"COMMIT")
        except CatchableError as e:
            errorLogger e, "Failed to commit"
        db.close()

proc initDatabaseTables*() =
    withDatabase db:
        db.exec(sql sqlInitServers)
        db.exec(sql sqlInitUsers)
        db.exec(sql sqlInitTransactions)


# --- Users -------------------------------------------------------------------

proc toUser(row: Row): UserDataObject =
    result = UserDataObject(
        id: row[0],
        money: row[1].readInt(),
        lastDailyReward: row[2].readInt(),
        currentDailyStreak: row[3].readInt()
    )

proc dbGetUser*(id: string): UserDataObject =
    ## Gets an user by its ID or returns new object
    var rows: seq[Row]
    withDatabase db:
        rows = db.getAllRows(sql sqlGetUser, id)
        if rows.len() == 0:
            db.exec(sql sqlNewUser, id)

    if rows.len() == 0: return UserDataObject(id: id) # Return new/empty user object
    result = rows[0].toUser()
proc dbGetUser*(user: User): UserDataObject =
    ## Gets an user by its ID or returns new object
    result = user.id.dbGetUser()


# --- Servers -----------------------------------------------------------------

proc toServer(row: Row): ServerDataObject =
    let
        channels: string = row[1]
        channelsJson: Table[string, string] = channels.parseJson().to(Table[string, string])
    result = ServerDataObject(
        id: row[0],
        channels: channelsTable
    )

proc dbGetServer*(id: string): ServerDataObject =
    ## Gets a server by its ID or returns new object
    var rows: seq[Row]
    withDatabase db:
        rows = db.getAllRows(sql sqlGetServer, id)
        if rows.len() == 0:
            db.exec(sql sqlNewServer, id)

    if rows.len() == 0: return ServerDataObject(id: id) # Return new/empty server object
    result = rows[0].toServer()
proc dbGetServer*(guild: Guild): ServerDataObject =
    ## Gets a server by its ID or returns new object
    result = guild.id.dbGetServer()


# --- Transactions ------------------------------------------------------------

proc toTransaction*(row: Row): CurrencyTransaction =
    result = CurrencyTransaction(
        id: row[0],
        source: row[1],
        target: row[2],
        reason: row[3],
        amount: row[4].readInt()
    )
proc toTransactions*(rows: seq[Row]): seq[CurrencyTransaction] =
    for row in rows:
        result.add row.toTransaction()

proc dbGetTransaction*(id: string): Option[CurrencyTransaction] =
    ## Tries to get a transaction by its ID
    var rows: seq[Row]
    withDatabase db:
        rows = db.getAllRows(sql sqlGetTransaction, id)
    result = block:
        if rows.len() == 0: none CurrencyTransaction
        else: some rows[0].toTransaction()
proc dbGetAllTransactions*(): seq[CurrencyTransaction] =
    ## Gets all transactions
    var rows: seq[Row]
    withDatabase db:
        rows = db.getAllRows(sql sqlGetTransactionsAll)
    result = rows.toTransactions()
