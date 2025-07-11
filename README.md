# Nimwit discord bot

## About

Nimwit is yet another general-purpose discord bot written in Nim. Most features are taken from my prior discord bot development ventures and also come from my friend group. If you have a feature request, feel free to open a GitHub issue! :)

You can of-course [invite the bot](https://discord.com/oauth2/authorize?client_id=1056828609265926145) to your server (should be online pretty much 24/7).

## Features

You can read up on all features in the [markdown wiki](docs/Wiki.md). It contains information about commands and their usages and information about some bot features, such as [economy](docs/wiki/Economy.md). However may be out of date!

## Compiling and Hosting

> [!WARNING] Hacks
> **2025-07-01:** There is a bug with Futures, that wasn't there before. Hack: remove line 389 in file
> `~/.choosenim/toolchains/nim-1.6.20/lib/pure/asyncfutures.nim` (content: `raise fut.error`), funnily everything
> works with this removed! (I write AMAZING code, the Nim standard library is trying to sabotage me!!!!)
>
> Another thing to do, change `ws` module (/`~/.nimble/pkgs/ws-0.5.0/ws.nim`, line 27) to the following:
> ```nim
> func newWebSocketClosedError(): auto =
>     result = newException(WebSocketClosedError, "Socket closed")
>     quit QuitFailure
> ```
> This actually makes the bot crash when the sockets close, otherwise it enters an infitie loop!

Compiling to an executable is very easy. Simply run `make build` or `nimble build -d:ssl` in your terminal. This will compile all nim source code into a single executable.

You will still need the `public` and `private` directories next to your executable though, as configuration and your token is stored inside there.

The `install.sh` script takes care of everything and sets up a systemd unit, that runs on system startup!

## Changes

See [here](docs/Changes.md) for a changelog and roadmap for this project.

## File structure

See [here](docs/FileStructure.md) for information about the projects file structure.

## Dependencies and Credits

System Dependencies:

- [nim](https://nim-lang.org/) (required to compile)

Nimble Dependencies:

* [dimscord](https://nimble.directory/pkg/dimscord) (Discord API library)

* [pixie](https://nimble.directory/pkg/pixie) (2D graphics library)

Optional:

- [GNU Make](https://www.gnu.org/software/make/) (Makefile build tool, see [Compiling and Hosting](#Compiling-and-Hosting))
