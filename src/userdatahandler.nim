import os, options, json, tables, times, strutils, strformat, math
import dimscord
import typedefs, logger

var UserData: Table[string, UserDataObject]

# Create user data file:
proc createUserDataFile() =
    writeFile(getLocation(fileUsers), "{}")

# Fetch user data from file:
proc getUserData(): Table[string, UserDataObject] =
    let filepath: string = getLocation(fileUsers)
    if not filepath.fileExists(): createUserDataFile()
    result = readFile(filepath).parseJson().to(Table[string, UserDataObject])

    UserData = result
    return result

proc updateUserData*() =
    discard getUserData()


# -------------------------------------------------
# Writing changes to disk:
# -------------------------------------------------

proc writeUserData(): bool =
    let
        stringJson: string = $(%* UserData)
        filepath: string = getLocation(fileUsers)

    try:
        writeFile(filepath, stringJson)
    except IOError as e:
        logError.logger(e.msg)
        return false


# -------------------------------------------------
# Modifying data in memory:
# -------------------------------------------------

proc createUserData(id: string) =
    UserData[id] = UserDataObject(
        id: id
    )
    discard writeUserData()

proc overrideUser(id: string, user: UserDataObject) =
    UserData[id] = user
    discard writeUserData()


# -------------------------------------------------
# Checking for user existance:
# -------------------------------------------------

proc userExists(id: string): bool =
    return UserData.hasKey(id)

proc verifyUserExistance*(id: string) =
    if not userExists(id): createUserData(id)

proc getUserObject*(id: string): UserDataObject =
    verifyUserExistance(id)
    return UserData[id]


# -------------------------------------------------
# Money procs:
# -------------------------------------------------

proc setMoneyValue*(id: string, amount: int): UserDataObject =
    verifyUserExistance(id)
    var user = UserData[id]
    user.money = some(amount)
    overrideUser(id, user)
    return user

proc getUserBalance*(id: string): int =
    verifyUserExistance(id)
    
    if UserData[id].money.isSome(): return UserData[id].money.get()
    else: return 0

# Handles any money-gain:
proc handleMoneyTransaction*(id: string, amount: int): (bool, string) =
    # Prepare user object:
    verifyUserExistance(id)
    var user: UserDataObject = UserData[id]
    if user.money.isNone():
        user = id.setMoneyValue(0)
    
    # Perform checks:
    if user.money.get() + amount < 0:
        return (false, "Balance insufficient.")

    # Save changes:
    user.money = some(user.money.get() + amount)
    overrideUser(id, user)
    return (true, "Transaction successful!")

# Handles user-to-user money transfer:
proc handleUserMoneyTransfer*(idSender, idRecipiant: string, amount: int): (bool, string) =
    verifyUserExistance(idSender)
    verifyUserExistance(idRecipiant)

    var
        sender = UserData[idSender]
        recipiant = UserData[idRecipiant]

    # Prepare user objects:
    if sender.money.isNone(): sender.money = some(0)
    if recipiant.money.isNone(): recipiant.money = some(0)

    # Perform checks:
    if getUserBalance(idSender) - abs(amount) < 0:
        return (false, "The sender does not have the required balance.")
    if getUserBalance(idRecipiant) > getUserBalance(idRecipiant) + amount:
        return (false, "The sender would receive money.")

    # Transactions and save changes:
    let senderStatus = handleMoneyTransaction(idSender, - abs(amount))

    if senderStatus[0] == false:
        return (false, "The sender does not have the required balance.")

    discard handleMoneyTransaction(idRecipiant, abs(amount))
    return (true, "Money transfer was successful.")


# -------------------------------------------------
# Daily rewards:
# -------------------------------------------------
let dateFormat = initTimeFormat("yyyyMMdd")

proc getDailyRewardForDay(day: int): int =
    return 500 + int(ceil(3.5 * sqrt(10 * day.float)))

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

proc handleUserMoneyReward*(id: string): (bool, string) =
    var user = getUserObject(id)

    # Init, if required:
    if user.currentDailyStreak.isNone():
        user.currentDailyStreak = some 0
    if user.lastDailyReward.isNone():
        user.lastDailyReward = some 19700101

    # Check if already used todays daily:
    if user.alreadyGotTodaysReward():
        return (false, &"You already claimed your todays reward. Wait until you can perform this action again.")

    # Check if streak was broken:
    if user.dailyStreakIsBroken():
        user.currentDailyStreak = some 0

    # Give money to user:
    let rewardMoney: int = getDailyRewardForDay(user.currentDailyStreak.get())

    user.money = some(user.money.get() + rewardMoney)
    user.currentDailyStreak = some(user.currentDailyStreak.get() + 1)
    user.lastDailyReward = some now().format(dateFormat).parseInt()

    # Save changes to disk:
    overrideUser(id, user)
    let
        rewardTomorrow: int = getDailyRewardForDay(user.currentDailyStreak.get() + 1)
        response: seq[string] = @[
            &"Congratulations! You have claimed {rewardMoney} money!",
            &"Your current streak is {user.currentDailyStreak.get()} day(s). Keep it up! Tomorrows reward will be {rewardTomorrow} money."
        ]
    return (true, response.join("\n"))

proc handleUserMoneyReward*(user: User): (bool, string) =
    return handleUserMoneyReward(user.id)
