import strutils, strformat, asyncdispatch, options, random, sequtils, random
import dimscord
import typedefs, configfile, userdatahandler, serverdatahandler, logchannelhandler, utils

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

proc messageUpdate(s: Shard; m: Message; o: Option[Message], exists: bool) {.event(discord).} =
    if m.member.isNone() or m.author.bot: return
    var
        message: LogMessage
        fields: seq[EmbedField]

    if o.isSome():
        let old = get o
        if m.content == old.content: return # most likely an embed appeared (links and stuff)
        fields.add(getFieldFromObject(old, "Before edit:"))
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
    let user: User = m.user
    var message: LogMessage

    proc getEmbedFromMemberObject(member: Member, title: string): Embed =
        result = Embed(
            title: some title,
            thumbnail: some EmbedThumbnail(url: user.getAnimatedAvatar()),
            footer: some EmbedFooter(text: &"User ID: {user.id}"),
            color: some EmbedColour.default
        )
        var descLines: seq[string] = @[
            &"**Ping:** {user.id.mentionUser()}",
            &"**Username:** {user.username.sanitize()}"
        ]
        if member.nick.isSome(): descLines.add &"**Nickname:** {member.nick.get().sanitize()}"
        if user.global_name.isSome(): descLines.add &"**Global name:** {user.global_name.get().sanitize()}"
        if user.display_name.isSome(): descLines.add &"**Display name:** {user.display_name.get().sanitize()}"
        result.description = some descLines.join("\n")

    message.content = &"**{user.fullUsername()}** has changed their profile!"

    if o.isSome(): message.embeds.add(getEmbedFromMemberObject(o.get(), "Prior Profile"))
    message.embeds.add(getEmbedFromMemberObject(m, "Current Profile"))

    sendLogMessage(g.id, memberUpdate, message)



# -------------------------------------------------
# Connect to discord:
# -------------------------------------------------

debuglogger "Started session"
try:
    waitFor discord.startSession(
        gateway_intents = {giDirectMessages, giGuildMessages, giGuilds, giGuildMembers, giMessageContent},
        autoreconnect = true
    )
except CatchableError as e:
    debugLogger "Fatal error encountered"
    errorLogger e
except Defect as d:
    debugLogger "Fatal error encountered"
    errorLogger d
finally:
    debugLogger "Session ended"
    quit QuitFailure
