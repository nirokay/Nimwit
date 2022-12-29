import os, times, strutils, asyncdispatch, options, sequtils, tables
import dimscord, pixie
import typedefs, configfile, commandprocs

proc sendImageList(m: Message) =
    var list: seq[string]
    for image in ImageTemplateList:
        list.add("* " & image.name & " (" & image.alias.join("/") & ")")

    discard discord.api.sendMessage(
        m.channel_id,
        embeds = @[Embed(
            title: "List of all available images:".some,
            description: list.join("\n").some
        )]
    )

proc newFont(typeface: Typeface, size: float32, color: Color): Font =
    result = newFont(typeface)
    result.size = size
    result.paint.color = color

proc createRequestedImage(requestedImage: ImageTemplate, text: string): string =
    let
        fileformat: string = requestedImage.filename.split(".")[^1]
        filename: string = config.fileLocations[dirCache] & requestedImage.name & $int(epochTime()) & "." & fileformat
        boxsize: array[2, float32] = requestedImage.textbox[1]
        boxpos: array[2, float32] = requestedImage.textbox[0]

    # Check if cache dir exists:
    if not config.fileLocations[dirCache].dirExists():
        config.fileLocations[dirCache].createDir()

    # Create Image:
    var image: Image = readImage(config.fileLocations[dirImageTemplates] & requestedImage.filename)

    let
        typeface: Typeface = readTypeface(config.fileLocations[requestedImage.font])
        c = requestedImage.rgb
        font: Font = newFont(typeface, requestedImage.fontsize, color(c[0], c[1], c[2], 1))

    image.fillText(font.typeset(text, vec2(boxsize[0], boxsize[1])), translate(vec2(boxpos[0], boxpos[1])))
    image.writeFile(filename)
    return filename

proc sendCreatedImage(m: Message, imagePath: string) =
    # If image went poof:
    if not imagePath.fileExists():
        discard sendErrorMessage(m, INTERNAL, "Image file was not found... :(\nPlease report this.")
        return

    # Send message:
    discard discord.api.sendMessage(
        m.channel_id,
        "<@" & m.author.id & "> created an image:",
        files = @[DiscordFile(
            name: imagePath
        )]
    )

proc removeCreatedImage(imagePath: string) =
    if imagePath.fileExists(): imagePath.removeFile()

proc evaluateImageCreationRequest*(s: Shard, m: Message, args: seq[string]): Future[system.void] {.async.} = 
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

    var imageText: string
    if args.len < 3: imageText = "<here would be text, if you would have done it right>"
    else:
        var temp: seq[string] = args
        temp.delete(0..1)
        imageText = temp.join(" ")

    # Create, Send and Remove Image:
    let finalImagePath: string = createRequestedImage(requestedImage, imageText)
    sendCreatedImage(m, finalImagePath)
    removeCreatedImage(finalImagePath)


