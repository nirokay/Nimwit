import typedefs
import commandprocs

CommandList.add(Command(
    name: "ping",
    desc: "Get the current ping of the bot.",

    category: SYSTEM,
    call: pingCommand
))

CommandList.add(Command(
    name: "help",
    desc: "Displays a help message.",

    category: SYSTEM,
    alias: @["commands"],
    call: helpCommand
))

CommandList.add(Command(
    name: "docs",
    desc: "Displays a more in-depth documentation about any command.",

    category: SYSTEM,
    alias: @["doc", "documentation"],
    usage: @["[command_name: string]"],
    call: docCommand
))


