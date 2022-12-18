import typedefs, asyncdispatch
import commandprocs

CommandList.add(Command(
    name: "ping",
    desc: "Get the current ping of the bot.",
    call: proc(s: Shard, m: Message, args: seq[string]) = pingCommand(s, m, args)
))
