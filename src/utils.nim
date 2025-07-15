import std/[strutils, strformat, options, asyncdispatch]
from unicode import capitalize
import dimscord
import typedefs, configfile

export capitalize

using
    s: Shard
    i: Interaction


# Error messages:
proc getErrorEmbed*(error: ErrorType, message: string = "An unknown error occurred."): Embed = Embed(
    title: some &"{($error).toLower().capitalize()} Error",
    description: some message,
    color: some EmbedColour.error
)
proc getErrorEmbed*(error: ErrorType, message, footerMessage: string): Embed =
    result = getErrorEmbed(error, message)
    result.footer = some EmbedFooter(
        text: footerMessage
    )
    return result

proc sendErrorMessage*(s, i; error: ErrorType, message: string = "An unknown error occurred."): Future[SlashResponse] {.async.} =
    return SlashResponse(
        embeds: @[getErrorEmbed(error, message)]
    )
proc sendErrorMessage*(s, i; error: ErrorType, message, footerMessage: string): Future[SlashResponse] {.async.} =
    return SlashResponse(
        embeds: @[getErrorEmbed(error, message, footerMessage)]
    )


# User templates:
template getUser*(): User = ## Gets user, does not care if in DMs or on server
    # WTF discord, i spent around an hour debugging and then learned it is a "feature"
    # that `i.user.get()` is `none User` on servers, but `.isSome() == true` in DMs...
    if i.user.isSome(): i.user.get()
    else: i.member.get().user

template getUser*(id: string): User =
    waitFor discord.api.getUser(id)

template getBot*(): User = s.user

# Mentions and names stuff:
proc mentionUser*[T: string|int](id: T): string =
    return "<@" & $id & ">"
proc mentionUser*(user: User): string =
    return mentionUser(user.id)

proc mentionRole*[T: string|int](id: T): string =
    return "<@&" & $id & ">"
proc mentionRole*(role: Role): string =
    return "<@&" & role.id & ">"

proc fullUsername*(user: User): string =
    result = user.username
    if user.discriminator notin ["0", "0000"]:
        result.add "#" & user.discriminator


# Pfp and Banners:
proc getAnimatedImage(userId, imageType, imageId: string): string =
    let format: string = if imageId.startsWith("a_"): "gif" else: "png"
    result = &"https://cdn.discordapp.com/{imageType}/{userId}/{imageId}.{format}"

proc getAnimatedBanner*(user: User): string =
    let bannerId: string = user.banner.get()
    result = getAnimatedImage(user.id, "banner", bannerId)

proc getAnimatedAvatar*(user: User): string =
    if user.avatar.isNone(): return user.defaultAvatarUrl
    let pfpId: string = get user.avatar
    result = getAnimatedImage(user.id, "avatars", pfpId)


# Sanitization:
const escapeChars: string = "_*~#[]()"
proc sanitize*(input: string): string =
    ## Escapes Markdown characters
    result = input
    for c in escapeChars:
        result = result.replace($c, "\\" & $c)
