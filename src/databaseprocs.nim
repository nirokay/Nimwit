import std/[strutils, json]
import db_connector/db_sqlite, dimscord
import typedefs, squeal

export squeal

type DbResult* = object
    error*: bool
    reason*: string
proc dbError*(reason: string): DbResult = DbResult(
    error: true,
    reason: reason
)
proc dbSuccess*(reason: string = ""): DbResult = DbResult(
    error: false,
    reason: reason
)
proc unify*(results: seq[DbResult]): DbResult =
    result.error = false
    var lines: seq[string]
    for r in results:
        if not r.error: continue
        result.error = true
        lines.add r.reason
    result.reason = lines.join("\n")


# Init:
proc dbInit*(): DbResult =
    withDatabase db:
        db.exec(sql sqlInitServers)
        db.exec(sql sqlInitTransactions)
        db.exec(sql sqlInitUsers)
        result = dbSuccess()

# Transactions:
proc dbTransactionNew*(transaction: CurrencyTransaction): DbResult =
    let t = transaction
    withDatabase db:
        db.exec(sql sqlNewTransaction,
            t.source,
            t.target,
            t.reason,
            t.amount
        )
proc dbTransactionsNew*(transactions: seq[CurrencyTransaction]): DbResult =
    var results: seq[DbResult]
    for transaction in transactions:
        results.add transaction.dbTransactionNew()
    result = results.unify()

# Server channels:
proc dbServerSaveChannels*(server: ServerDataObject): DbResult =
    let channels: JsonNode = % server.channels
    withDatabase db:
        db.exec(sql sqlSetServerChannels, $channels, server.id)


# User:
proc dbUserAddCurrency*(id: string, amount: Natural): DbResult =
    withDatabase db:
        db.exec(sql sqlSetUserCurrencyAdd, amount, id)
proc dbUserAddCurrency*(user: User, amount: Natural): DbResult =
    result = dbUserAddCurrency(user.id, amount)
proc dbUserAddCurrency*(user: UserDataObject, amount: Natural): DbResult =
    result = dbUserAddCurrency(user.id, amount)

proc dbUserSubCurrency*(id: string, amount: Natural): DbResult =
    withDatabase db:
        db.exec(sql sqlSetUserCurrencySub, amount, id)
proc dbUserSubCurrency*(user: User, amount: Natural): DbResult =
    result = dbUserSubCurrency(user.id, amount)
proc dbUserSubCurrency*(user: UserDataObject, amount: Natural): DbResult =
    result = dbUserSubCurrency(user.id, amount)

proc dbUserSetDaily*(id: string, dailyLast, dailyStreak: int): DbResult =
    withDatabase db:
        db.exec(sql sqlSetUserDaily, dailyLast, dailyStreak, id)
proc dbUserSetDaily*(user: User, dailyLast, dailyStreak: int): DbResult =
    result = dbUserSetDaily(user.id, dailyLast, dailyStreak)
proc dbUserSetDaily*(user: UserDataObject, dailyLast, dailyStreak: int): DbResult =
    result = dbUserSetDaily(user.id, dailyLast, dailyStreak)
