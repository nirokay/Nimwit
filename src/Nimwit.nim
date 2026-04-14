import strutils, strformat, asyncdispatch, options, random, sequtils, random
import dimscord
import typedefs, configfile, databaseuser, databaseprocs, logchannelhandler, utils

randomize()

# -------------------------------------------------
# Initialize commands:
# -------------------------------------------------

include substringdefs, slashdefs


# -------------------------------------------------
# Discord events:
# -------------------------------------------------

# Connected to discord: ---------------------------

proc onReady(s: Shard, r: Ready) {.event(discord).} =
    # Init database:
    discard dbInit()

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
            name: "you closely",
            kind: atWatching,
            url: some "https://github.com/nirokay/Nimwit/blob/master/docs/Commands.md"
        )],
        status = "online",
        afk = false
    )


# User Interaction incoming: ----------------------

proc interactionCreate(s: Shard, i: Interaction) {.event(discord).} =
    discard handleSlashInteraction(s, i)


# Incoming Message: -------------------------------

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
    # From here on only user commands:
    if m.author.bot: return

    discard detectSubstringInMessage(s, m)
    discard handleMessageCurrencyGain(m.author.id)


# Logger events: ----------------------------------

# Message events:

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

proc messageUpdate(s: Shard, m: Message, o: Option[Message], exists: bool) {.event(discord).} =
    if m.member.isNone() or m.author.bot: return
    if o.isNone(): return # most likely discord embedding an image or gif, skip that shit
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


# Threads:

proc threadCreate(s: Shard, g: Guild, c: GuildChannel) {.event(discord).} =
    await discord.api.joinThread(c.id)

proc threadListSync(s: Shard, e: ThreadListSync) {.event(discord).} =
    echo "Joining " & $e.threads.len() & " threads!"
    for thread in e.threads:
        await discord.api.joinThread(thread.id)


# Member events:

proc guildMemberAdd(s: Shard, g: Guild, m: Member) {.event(discord).} =
    var message: LogMessage
    let text: string = MemberJoinLeaveText["join"][rand(MemberJoinLeaveText["join"].len() - 1)]
    message.content = text.replace("%s", &"<@{m.user.id}>")
    sendLogMessage(g.id, memberJoin, message)

proc guildMemberRemove(s: Shard, g: Guild, m: Member) {.event(discord).} =
    var message: LogMessage
    let text: string = MemberJoinLeaveText["leave"][rand(MemberJoinLeaveText["leave"].len() - 1)]
    message.content = text.replace("%s", &"**{m.user.fullUsername()}**")
    sendLogMessage(g.id, memberLeave, message)

proc guildMemberUpdate(s: Shard, g: Guild, m: Member, o: Option[Member]) {.event(discord).} =
    let user: User = m.user
    var message: LogMessage

    proc getEmbedFromMemberObject(member: Member, title: string): Embed =
        result = Embed(
            title: some title,
            thumbnail: some EmbedThumbnail(url: user.getAnimatedAvatar()),
            footer: some EmbedFooter(text: &"User ID: {user.id}"),
            color: some EmbedColour.default
        )
        var
            descLines: seq[string] = @[
                &"**Ping:** {user.id.mentionUser()}",
                &"**Username:** {user.username.sanitize()}"
            ]
            fields: seq[EmbedField]
        if member.nick.isSome(): descLines.add &"**Nickname:** {member.nick.get().sanitize()}"
        if user.global_name.isSome(): descLines.add &"**Global name:** {user.global_name.get().sanitize()}"
        if user.display_name.isSome(): descLines.add &"**Display name:** {user.display_name.get().sanitize()}"
        if member.roles.len() != 0:
            var
                field: EmbedField = EmbedField(name: "Roles", inline: some true)
                value: seq[string]
            for role in member.roles:
                value.add "<@&" & role & ">"
            field.value = value.join(" ")
            fields.add field

        result.description = some descLines.join("\n")
        if fields.len() != 0: result.fields = some fields

    message.content = &"**{user.fullUsername()}**'s profile has changed!"

    if o.isSome(): message.embeds.add(getEmbedFromMemberObject(o.get(), "Prior Profile"))
    message.embeds.add(getEmbedFromMemberObject(m, "Current Profile"))

    # Skip sending, if embeds are the same (does not show a difference):
    if message.embeds.len() >= 2:
        var
            before: Embed = message.embeds[0]
            after: Embed = message.embeds[1]
        before.title = some "a"
        after.title = some "a"
        if $before == $after: return

    sendLogMessage(g.id, memberUpdate, message)



# -------------------------------------------------
# Connect to discord:
# -------------------------------------------------

proc ctrlc() {.noconv.} =
    echo "Disconnecting and exiting gracefully..."
    waitFor discord.endSession()
    quit QuitSuccess
setControlCHook(ctrlc)


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
