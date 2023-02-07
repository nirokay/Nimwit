import os, options, json, tables
import dimscord
import typedefs, configfile, logger

var UserData: Table[string, UserDataObject]

# Fetch user data from file:
proc getUserData(): Table[string, UserDataObject] =
    let filepath: string = config.fileLocations[fileUsers]
    result = readFile(filepath).parseJson().to(Table[string, UserDataObject])

    UserData = result
    return result

proc updateUserData*() =
    discard getUserData()

# Write user data to file:
proc writeUserData(): bool =
    let
        stringJson: string = $(%* UserData)
        filepath: string = config.fileLocations[fileUsers]

    try:
        writeFile(filepath, stringJson)
    except IOError as e:
        logError.logger(e.msg)
        return false


# User Writing:
proc createUserData(id: string) =
    UserData[id] = UserDataObject(
        id: id
    )
    discard writeUserData()

proc overrideUser(id: string, user: UserDataObject) =
    UserData[id] = user

# User Existance:
proc userExists(id: string): bool =
    return UserData.hasKey(id)

proc verifyUserExistance*(id: string) =
    if not userExists(id): createUserData(id)

proc getUserObject*(id: string): UserDataObject =
    verifyUserExistance(id)
    return UserData[id]

# Money procs:
proc setMoneyValue*(id: string, amount: int): UserDataObject =
    verifyUserExistance(id)
    var user = UserData[id]
    user.money = some(amount)
    overrideUser(id, user)
    discard writeUserData()
    return user

proc getUserBalance*(id: string): int =
    verifyUserExistance(id)
    
    if UserData[id].money.isSome(): return UserData[id].money.get()
    else: return 0

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
    discard writeUserData()
    return (true, "Transaction successful!")

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


