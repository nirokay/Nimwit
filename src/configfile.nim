import typedefs

const
    config* = Config(
        prefix: ".",
        rollCommandLimit: 500,

        # Money:
        moneyGainPerMessage: 1
    )
    EmbedColour* = EmbedColoursConfig(
        error:   0x990000,
        warning: 0xff9933,
        success: 0xaaff80,
        default: 0xe6ccff
    )

export config
