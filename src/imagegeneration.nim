import os, times, strutils, asyncdispatch, options, sequtils
import dimscord, pixie
import typedefs, configfile, commandprocs, logger

proc sendImageList(m: Message) =
    var list: seq[string]
    for image in ImageTemplateList:
        list.add("* **" & image.name & "** (" & image.alias.join(", ") & ")")

    discard discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            title: "List of all available images:".some,
            description: list.join("\n").some,
            color: EmbedColour.default.some
        )]
    )

proc newFont(typeface: Typeface, size: float32, color: Color): Font =
    result = newFont(typeface)
    result.size = size
    result.paint.color = color

proc createImageFile*(requestedImage: ImageTemplate, filename, content: string): Future[system.void] {.async.} =
    let
        boxsize: array[2, float32] = requestedImage.textbox[1]
        boxpos: array[2, float32] = requestedImage.textbox[0]
        text: string = if content == "": "[there would be text here, if you had done it correctly]" else: content

    # Check if cache dir exists:
    if not dirExists(getLocation(dirCache)):
       createDir(getLocation(dirCache))

    # Create Image:
    var image: Image = readImage(getLocation(dirImageTemplates) & requestedImage.filename)

    let
        fontpath: string = getFontLocation(requestedImage.font)
        typeface: Typeface = readTypeface(fontpath)
        c = requestedImage.rgb
        font: Font = newFont(typeface, requestedImage.fontsize, color(c[0], c[1], c[2], 1))

    image.fillText(font.typeset(text, vec2(boxsize[0], boxsize[1])), translate(vec2(boxpos[0], boxpos[1])))
    image.writeFile(filename)
    return

proc createImageFile(requestedImage: ImageTemplate, filename: string, args: seq[string]): Future[system.void] {.async.} =
    var list: seq[string] = args
    while list.len() < 3:
        list.add ""
    return createImageFile(requestedImage, filename, list[2 .. ^1].join(" "))

proc getNewImageFileName*(requestedImage: ImageTemplate): string =
    let
        fileformat: string = requestedImage.filename.split(".")[^1]
        filename: string = getLocation(dirCache) & requestedImage.name & $int(epochTime()) & "." & fileformat
    return filename

proc sendCreatedImage(m: Message, imagePath: string) =
    # If image went poof:
    if not imagePath.fileExists():
        discard sendErrorMessage(m, INTERNAL, "Image file could not be sent. File was not found... :(\nPlease report this.")
        logError.logger("Image could not be located in cache!")
        return

    # Send message:
    discard discord.api.sendMessage(
        m.channel_id,
        "<@" & m.author.id & "> created an image:",
        files = @[DiscordFile(
            name: imagePath
        )]
    )

proc removeCreatedImage*(imagePath: string) =
    if imagePath.fileExists(): imagePath.removeFile()

proc evaluateImageCreationRequest*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} =
    let beginTime: float = epochTime()*1000

    if args.len == 1:
        discard sendErrorMessage(m, SYNTAX, "You have to provide an image name as argument. See `list` argument for all available images.")
        return
    let imageName: string = args[1].toLower()

    # List of available images:
    if imageName == "list":
        sendImageList(m)
        return

    # Continue to image selection:
    var requestedImage: ImageTemplate
    for image in ImageTemplateList:
        # Matching name:
        if image.name == imageName: requestedImage = image; break
        # Matching one of alias:
        for alias in image.alias:
            if alias == imageName: requestedImage = image; break

    # Check if image was found:
    if requestedImage notin ImageTemplateList:
        discard sendErrorMessage(m, VALUE, "The requested image `" & imageName & "` could not be found. See `list` for a list of all available images.")
        return

    # Create, Send and Remove Image:
    let imageFilePath: string = getNewImageFileName(requestedImage)
    discard createImageFile(requestedImage, imageFilePath, args)
    sendCreatedImage(m, imageFilePath)
    removeCreatedImage(imageFilePath)

    # Debug "Benchmarking":
    let endTime: float = epochTime()*1000
    echo "Created and sent image from template '" & requestedImage.name & "'\n\tTook " & $(endTime - beginTime) & "ms."
