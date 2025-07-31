import os, times, strutils, asyncdispatch
import pixie
import typedefs

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

proc removeCreatedImage*(imagePath: string) =
    if imagePath.fileExists(): imagePath.removeFile()
