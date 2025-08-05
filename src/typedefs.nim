import os, asyncdispatch, strutils, strformat, options, tables, json
import dimscord, pixie

type
    # ---------------------------------------------------------------------------------------
    # Config and Files
    # ---------------------------------------------------------------------------------------

    DataLocationEnum* = enum
        fileServers, fileUsers,

        fileSocialGifs, fileYesNoMaybe, fileImgTemplate,
        fileHelloList, fileInfo, fileJoinLeaveText, fileCoinFlip,
        fileUnitConversions, fileDate,

        fontDefault, fontDefaultBold, fontDefaultSerif,
        fontDefaultSerifBold, fontPapyrus,

        dirImageTemplates, dirCache, dirLogs

    Config* = object
        prefix*: string
        moneyGainPerMessage*: int
        rollCommandLimit*: int


    # ---------------------------------------------------------------------------------------
    # Commands
    # ---------------------------------------------------------------------------------------

    EmbedColoursConfig* = object
        error*, warning*, success*, default*: int

    ErrorType* = enum
        SYNTAX, LOGICAL, VALUE, PERMISSION, USAGE, INTERNAL

    CommandCategory* = enum
        UNDEFINED, SYSTEM, SOCIAL, MATH, FUN, CHATTING, ECONOMY

    CommandTemplate = object of RootObj
        name*, desc*: string

        category*: CommandCategory
        examples*: seq[string]

        serverOnly*: bool

    Command* = object of CommandTemplate
        alias*, usage*: seq[string]
        hidden*: bool
        call*: proc(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.}

    SlashData* = ApplicationCommandInteractionData
    SlashResponse* = InteractionCallbackDataMessage
    SlashOption* = ApplicationCommandOption
    SlashChoice* = ApplicationCommandOptionChoice
    SlashCommand* = object of CommandTemplate
        permissions*: Option[seq[PermissionFlags]]
        kind*: ApplicationCommandType
        options*: seq[SlashOption]
        call*: proc(s: Shard, i: Interaction): Future[SlashResponse] {.async.}

    SubstringReaction* = object
        name*: string ## Used for docs
        trigger*: seq[string]
        probability*: float
        caseSensitive*: bool

        emoji*, response*: string


    # ---------------------------------------------------------------------------------------
    # Data Stuff
    # ---------------------------------------------------------------------------------------

    BotInfoObject = object
        name*, repository*, issues*: string

    ImageTemplate* = object
        name*, filename*: string
        alias*: seq[string]
        textbox*: array[2, array[2, float32]]
        fontsize*: float32
        rgb*: array[3, float32]
        font*: string

    CurrencyTransactionSource* = enum ## either a source from here or an user ID
        sourceDaily = "DAILY",
        sourceJob = "JOB",
        sourceLottery = "LOTTERY"
    CurrencyTransactionReason* = enum
        reasonPayment = "PAYMENT",
        reasonPurchase = "PURCHASE",
        reasonTaxation = "TAXATION",
        reasonTransfer = "TRANSFER"
    CurrencyTransaction* = object
        id*, source*, target*, reason*: string
        amount*: int

    UserDataObject* = object
        id*: string
        money*, lastDailyReward*, currentDailyStreak*: int

    ServerSettingChannelOption* = enum
        channelWelcomeMessages = "welcome-and-goodbye-messages"
        channelMessageLogging = "message-changes-and-deletions-logging"
        channelUserChanges = "user-profile-changes"

    ServerDataObject* = object
        id*: string
        channels*: Table[string, string]

    CoinFlipObject* = object
        headsUrl*, tailsUrl*: string

    Unit* = object
        name*: string
        default*: Option[bool]
        multiplicator*: float
        adder*: Option[float]
    UnitConversion* = OrderedTable[string, Unit]
    UnitConversionList* = OrderedTable[string, UnitConversion]

    DateIdeasObject* = object
        locations*, bonding*: seq[string]
        mood*, outcomes*: Table[string, seq[string]]

# Directories:
const dirs: seq[string] = @[
    "private",
        "private/logs", "private/data", "private/cache"
]
for dir in dirs:
    if not dirExists(dir):
        echo &"Creating directory: '{dir}'"
        createDir(dir)


# Discord:
import tokenhandler
setDiscordToken()
let discord* = newDiscordClient(getDiscordToken().strip())
export discord


# Init Global Lists from json files:
proc initListFromJson[T](filepath: string): T =
    try:
        return readFile(filepath).parseJson().to(T)
    except Exception as e:
        echo &"While loading from json at '{filepath}': *{e.name}*\n-----\n{e.msg}\n-----"


# Global Lists:
var
    CommandList* {.global.}: seq[Command]
    SlashCommandList* {.global.}: seq[SlashCommand]
    SubstringReactionList* {.global.}: seq[SubstringReaction]

let
    DataLocation* {.global.}: Table[DataLocationEnum, string] = toTable {
        fileServers: "private/data/servers.json",
        fileUsers:   "private/data/users.json",

        fileHelloList:       "public/helloList.json",
        fileSocialGifs:      "public/socialGifs.json",
        fileYesNoMaybe:      "public/yesNoMaybeResponses.json",
        fileJoinLeaveText:   "public/memberJoinLeave.json",
        fileInfo:            "public/info.json",
        fileImgTemplate:     "public/imageTemplateList.json",
        fileCoinFlip:        "public/coinFlip.json",
        fileUnitConversions: "public/unitConversion.json",
        fileDate:            "public/date.json",

        fontDefault:          "public/font/DejaVuSans.ttf",
        fontDefaultBold:      "public/font/DejaVuSans-Bold.ttf",
        fontDefaultSerif:     "public/font/DejaVuSerif.ttf",
        fontDefaultSerifBold: "public/font/DejaVuSerif-Bold.ttf",
        fontPapyrus:          "public/font/PAPYRUS.ttf",

        dirImageTemplates: "public/image_templates/",
        dirCache:          "private/cache/",
        dirLogs:           "private/logs/"
    }

    # Init from json files:
    BotInfo* {.global.} = initListFromJson[BotInfoObject](DataLocation[fileInfo])
    ImageTemplateList* {.global.} = initListFromJson[seq[ImageTemplate]](DataLocation[fileImgTemplate])
    MemberJoinLeaveText* {.global.} = initListFromJson[Table[string, seq[string]]](DataLocation[fileJoinLeaveText])
    CoinFlip* {.global.} = initListFromJson[CoinFlipObject](DataLocation[fileCoinFlip])
    UnitConversions* {.global.} = initListFromJson[UnitConversionList](DataLocation[fileUnitConversions])
    DateIdeas* {.global.} = initListFromJson[DateIdeasObject](DataLocation[fileDate])

const dateMoods*: array[3, string] = ["positive", "neutral", "negative"]

# Getter for file location:
proc getLocation*(file: DataLocationEnum): string =
    if not DataLocation.hasKey(file): return ""
    return DataLocation[file]

# Cheeky cheats for json:
proc getFontLocation*(file: DataLocationEnum | string): string =
    # I cheated around to make "string == enum", it's ugly but works :)
    for fontEnum, location in pairs(DataLocation):
        if $fontEnum == $file: return location
    return DataLocation[fontDefault]

proc newCurrencyTransaction*(source: CurrencyTransactionSource|string, target: string, reason: CurrencyTransactionReason, amount: int): CurrencyTransaction = CurrencyTransaction(
    id: "-1", # temporary id
    source: $source,
    target: target,
    reason: $reason,
    amount: amount
)
proc newCurrencyTransaction*(source, target: User, reason: CurrencyTransactionReason, amount: int): CurrencyTransaction = newCurrencyTransaction(source.id, target.id, reason, amount)
proc newCurrencyTransaction*(source: CurrencyTransactionSource, target: User, reason: CurrencyTransactionReason, amount: int): CurrencyTransaction = newCurrencyTransaction(source, target.id, reason, amount)

proc newCurrencyTransaction*(source, target: UserDataObject, reason: CurrencyTransactionReason, amount: int): CurrencyTransaction = newCurrencyTransaction(source.id, target.id, reason, amount)
proc newCurrencyTransaction*(source: CurrencyTransactionSource, target: UserDataObject, reason: CurrencyTransactionReason, amount: int): CurrencyTransaction = newCurrencyTransaction(source, target.id, reason, amount)

# Validate data:
var errors: seq[string]

for measurement, conversions in UnitConversions:
    block `validate`:
        for name, unit in conversions:
            if unit.default == some true: break validate
        errors.add "[Unit conversions] No default value in " & measurement


if errors.len() != 0:
    echo "Data errors encountered:"
    echo errors.join("\n").indent(4)
    quit 2
