import typedefs, tables

const config* = Config(
    prefix: ".",
    rollCommandLimit: 500,

    # Locations of all data files:
    fileLocations: {
        fileHelloList: "public/hello_list.json",
        fileSocialGifs: "public/social_gifs.json",
        fileYesNoMaybe: "public/yes_no_maybe_responses.json"
    }.toTable
)

const EmbedColour* = EmbedColoursConfig(
    error:   0x990000,
    warning: 0xff9933,
    success: 0xaaff80,
    default: 0xe6ccff
)

export config
