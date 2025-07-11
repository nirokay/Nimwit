import strutils, strformat, asyncdispatch, options, random, sequtils, random
import dimscord
import typedefs, configfile, userdatahandler, serverdatahandler, logchannelhandler

randomize()

# -------------------------------------------------
# Initialize commands:
# -------------------------------------------------

include commanddefs, substringdefs, slashdefs, slashprocs


# -------------------------------------------------
# Discord events:
# -------------------------------------------------

# Connected to discord: ---------------------------

proc onReady(s: Shard, r: Ready) {.event(discord).} =
    # Errors:
    if config.prefix.len() == 0:
        echo "Prefix cannot be empty! Set a valid prefix in configfile."
        quit(1)

    # Ready message and begin loading/setup:
    echo &"Ready as {$r.user} in {r.guilds.len()} guilds!"

    # Init slash commands:
    discard await discord.api.bulkOverwriteApplicationCommands(
        s.user.id,
        getApplicationCommandList()
    )

    # Update Status:
    discard s.updateStatus(
        activities = @[ActivityStatus(
            name: ".help",
            kind: atPlaying
        )],
        status = "online",
        afk = false
    )

    # User data:
    loadUserData()
    loadServerData()

# User Interaction incoming: ----------------------

proc interactionCreate(s: Shard, i: Interaction) {.event(discord).} =
    discard handleSlashInteraction(s, i)


# Incoming Message: -------------------------------

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
    # User and bot commands:
    # wow so empty

    # From here on only user commands:
    if m.author.bot: return

    if not checkForMessageCommand(s, m):
        # Only gain money if it was not a command:
        discard handleMoneyTransaction(m.author.id, config.moneyGainPerMessage)
    discard detectSubstringInMessage(s, m)


# Logger events: ----------------------------------

# Message events:

# TODO: FIX: Broken logging if attachments are there:
proc getAttachmentUrls(attachments: seq[Attachment]): string =
        if attachments == @[]: return "none"
        var temp: seq[string]
        for i in attachments:
            temp.add(i.url)
        return temp.join(" ,  ")
proc getFieldFromObject(m: Message, title: string): EmbedField = EmbedField(
        name: title,
        value: &"__Content:__\n{m.content}\n\n__Attachments__:\n{getAttachmentUrls(m.attachments)}"
    )
proc getMessageLinkFiled(m: Message): EmbedField = EmbedField(
    name: "Message Link",
    value: "https://discord.com/channels/" & m.guild_id.get("0") & &"/{m.channel_id}/{m.id}"
)

proc messageDelete(s: Shard, m: Message, exists: bool) {.event(discord).} =
    if m.member.isNone(): return
    var message: LogMessage
    message.embeds = @[Embed(
        description: some &"A message from <@{m.author.id}> was deleted in <#{m.channel_id}>",
        fields: some @[
            getFieldFromObject(m, "Deleted message:"),
            getMessageLinkFiled(m)
        ],
        color: some EmbedColour.error
    )]

    sendLogMessage(m.guild_id.get(), messageUpdate, message)


#! Kinda broken (idk why :/):
proc messageUpdate(s: Shard; m: Message; o: Option[Message], exists: bool) {.event(discord).} =
    if m.member.isNone() or m.author.bot: return
    var
        message: LogMessage
        fields: seq[EmbedField]

    if o.isSome():
        fields.add(getFieldFromObject(o.get(), "Before edit:"))
    fields.add(getFieldFromObject(m, "Current message:"))
    fields.add(getMessageLinkFiled(m))
    message.embeds = @[Embed(
        description: some &"A message from <@{m.author.id}> was edited in <#{m.channel_id}>",
        fields: some fields,
        color: some EmbedColour.warning
    )]
    sendLogMessage(m.guild_id.get(), messageUpdate, message)


# Member events:

proc guildMemberAdd(s: Shard; g: Guild; m: Member) {.event(discord).} =
    var message: LogMessage
    let text: string = MemberJoinLeaveText["join"][rand(MemberJoinLeaveText["join"].len() - 1)]
    message.content = text.replace("%s", &"<@{m.user.id}>")
    sendLogMessage(g.id, memberJoin, message)

proc guildMemberRemove(s: Shard; g: Guild; m: Member) {.event(discord).} =
    var message: LogMessage
    let text: string = MemberJoinLeaveText["leave"][rand(MemberJoinLeaveText["leave"].len() - 1)]
    message.content = text.replace("%s", &"**{m.user.fullUsername()}**")
    sendLogMessage(g.id, memberLeave, message)

proc guildMemberUpdate(s: Shard; g: Guild; m: Member, o: Option[Member]) {.event(discord).} =
    var message: LogMessage
    proc getEmbedFromMemberObject(member: Member, title: string): Embed = return Embed(
        title: some title,
        description: some @[
            &"Username: {member.user.username}",
            &"Nickname: {member.nick}",
            &"Ping: <@{member.user.id}>"
        ].join("\n"),
        thumbnail: some EmbedThumbnail(url: member.user.avatarUrl),
        footer: some EmbedFooter(text: &"User ID: {member.user.id}"),
        color: some EmbedColour.default
    )
    message.content = &"**{m.user.fullUsername()}** has changed their profile!"
    message.embeds.add(getEmbedFromMemberObject(m, "Current Profile"))
    if o.isSome():
        #! Kinda almost never works, idk why :(
        message.embeds.add(getEmbedFromMemberObject(o.get(), "Prior Profile"))
    sendLogMessage(g.id, memberUpdate, message)


# -------------------------------------------------
# Connect to discord:
# -------------------------------------------------

debuglogger "Started session"
try:
    waitFor discord.startSession(
        gateway_intents = {giDirectMessages, giGuildMessages, giGuilds, giGuildMembers, giMessageContent},
        autoreconnect = false
    )
except CatchableError as e:
    errorLogger e
except Defect as d:
    errorLogger d
finally:
    debugLogger "Session ended"
    quit QuitFailure

debugLogger "FUCK"
quit QuitFailure
