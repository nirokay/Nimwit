import std/[json]
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
    for transaction in transactions:
        transaction.dbSaveTransaction()


# Server channels:
proc dbServerSaveChannels*(server: ServerDataObject): DbResult =
    let channels: JsonNode = % server.channels
    withDatabase db:
        db.exec(sql sqlSetServerChannels, $channels, server.id)


# User:
proc dbUserAddCurrency*(id: string, amount: Natural): DbResult =
    withDatabase db:
        db.exec(sql sqlUserCurrencyAdd, amount, id)
proc dbUserAddCurrency*(user: User, amount: Natural): DbResult =
    result = dbUserAddCurrency(user.id, amount)

proc dbUserSubCurrency*(id: string, amount: Natural): DbResult =
    withDatabase db:
        db.exec(sql sqlUserCurrencySub, amount, id)
proc dbUserSubCurrency*(user: User, amount: Natural): DbResult =
    result = dbUserSubCurrency(user.id, amount)

proc dbUserSetDaily*(id: string, dailyLast, dailyStreak: int): DbResult =
    withDatabase db:
        db.exec(sql sqlSetUserDaily, dailyLast, dailyStreak, id)
proc dbUserSetDaily*(user: User, dailyLast, dailyStreak: int): DbResult =
    result = dbUserSetDaily(user.id, dailyLast, dailyStreak)
