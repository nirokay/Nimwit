import options, asyncdispatch, times
import dimscord
import typedefs

proc pingCommand*(s: Shard, m: Message, args: seq[string]) {.await.} =
    let
        then: float = epochTime() * 1000
        msg = await discord.api.sendMessage(m.channel_id, "pinging...")
        now: float = epochTime() * 1000

    discard await discord.api.editMessage(
        m.channel_id,
        msg.id,
        "Pong! Took " & $int(now - then) & "ms.\nLatency: " & $s.latency()
    )
    
