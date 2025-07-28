import os, options, json, tables, times, strutils, strformat, math
import dimscord
import typedefs, databaseprocs


# -------------------------------------------------
# Money procs:
# -------------------------------------------------

proc getUserBalance*(id: string): int =
    ## Reads the users balance from the database
    let user: UserDataObject = dbGetUser(id)
    result = user.money
proc getUserBalance*(user: User): int =
    ## Reads the users balance from the database
    result = getUserBalance(user.id)


# Handles chat message currency gain:
proc handleMessageCurrencyGain*(id: string, amount: int = 1: DbResult =
    ## Adds to the users balance in the database
    if amount < 1: dbError(&"Currency gain of '{amount}' is not a positive integer.")
    dbUserAddCurrency(id, Natural amount)
proc handleMessageCurrencyGain*(user: User, amount: int = 1: DbResult =
    ## Adds to the users balance in the database
    result = dbUserAddCurrency(user.id, amount)


# Handles user-to-user money transfer:
proc handleUserToUserTransfer*(sourceId, targetId: string, amount: int): DbResult =
    if amount < 1: return dbError("The amount to send has to be a positive integer.")

    var
        source: UserDataObject = dbGetUser(sourceId)
        target: UserDataObject = dbGetUser(targetId)

    if source.money < amount: return dbError("You do not have enough currency to perform this action.")

    let tSub = dbUserAddCurrency(source.id, Natural amount)
    if tSub.error: return dbError("An error occurred whilst subtracting from the senders money.")

    let tAdd = dbUserAddCurrency(target.id, Natural amount)
    if tAdd.error:
        dbUserAddCurrency(target.id, Natural amount) # hopefully give money back, this is very optimistic # TODO: debug this
        return dbError("An error occurred whilst adding to the receiver. Currency will be refunded to the sender.")

    let transaction: CurrencyTransaction = newCurrencyTransaction(source, target, reasonTransfer, amount)
    discard dbTransactionNew(transaction)

    return dbSuccess("The transaction was successful.")


# -------------------------------------------------
# Daily rewards:
# -------------------------------------------------
let dateFormat = initTimeFormat("yyyyMMdd")

proc getDailyRewardForDay(day: int): int =
    return 250 + int(ceil(5 * sqrt(10 * day.float)))

proc lastRewardDate(user: UserDataObject): string =
    return parse($user.lastDailyReward.get(), dateFormat).format(dateFormat)

proc dailyStreakIsBroken(user: UserDataObject): bool =
    let yesterdayDate = format(now() - 24.hours, dateFormat)

    if lastRewardDate(user) != yesterdayDate: return true
    else: return false

proc alreadyGotTodaysReward(user: UserDataObject): bool =
    let today = now().format(dateFormat)
    if lastRewardDate(user) == today:
        return true

    # Claim available:
    return false

proc handleUserDailyCurrency*(id: string): DbResult =
    var user: UserDataObject = dbGetUser(id)

    # Calculate how long until next day:
    let nextDay: string = block:
        let
            today: DateTime = now()
            tomorrow: DateTime = format(today + 24.hours, dateFormat).parse(dateFormat)
        # Set string:
        let interval: TimeInterval = today.between(tomorrow)
        &"{interval.hours}h {interval.minutes}m {interval.seconds}s"

    # Check if already used todays daily:
    if user.alreadyGotTodaysReward():
        return dbError(&"You already claimed your todays reward. Wait for **{nextDay}** you can perform this action again.")

    # Check if streak was broken:
    if user.dailyStreakIsBroken():
        user.currentDailyStreak = 0

    # Give money to user:
    let todaysCurrency: int = getDailyRewardForDay(user.currentDailyStreak)

    user.currentDailyStreak = some(user.currentDailyStreak + 1)
    user.lastDailyReward = some now().format(dateFormat).parseInt()

    # Save to database:
    let tAdd = dbUserAddCurrency(user.id, Natural todaysCurrency)
    if tAdd.error: return dbError("An error occurred while adding to balance.")

    discard dbUserSetDaily(user.id, user.lastDailyReward, user.currentDailyStreak)

    discard dbTransactionNew(newCurrencyTransaction(
        sourceDaily, user, reasonPayment, todaysCurrency
    ))

    # Response message:
    let
        tomorrowsCurrency: int = getDailyRewardForDay(user.currentDailyStreak) # already increased before, sends tomorrows reward
        response: seq[string] = @[
            &"Congratulations! You have claimed **{todaysCurrency}** currency!",
            &"Your current streak is **{user.currentDailyStreak} day(s)**. Keep it up! Tomorrows reward will be **{tomorrowsCurrency}** currency.\nYou can claim tomorrows reward in **{nextDay}**!"
        ]
    return dbSuccess(response.join("\n"))

proc handleUserDailyCurrency*(user: User): DbResult =
    return handleUserDailyCurrency(user.id)
