# Nimwit discord bot

## About

Nimwit is yet another general-purpose discord bot written in Nim. Most features are taken from my prior discord bot development ventures and also come from my friend group. If you have a feature request, feel free to open a GitHub issue! :)

You can of-course [invite the bot](https://discord.com/api/oauth2/authorize?client_id=1056828609265926145&permissions=277092625472&scope=bot) to your server (should be online pretty much 24/7).

## Features

You can read up on all features in the [markdown wiki](docs/Wiki.md). It contains information about commands and their usages and information about some bot features, such as [economy](docs/wiki/Economy.md).

## Compiling and Hosting

Compiling to an executable is very easy. Simply run `make build` or `nimble build -d:ssl` in your terminal. This will compile all nim source code into a single executable.

You will still need the `public` and `private` directories next to your executable though, as configuration and your token is stored inside there.

## Changes

See [here](docs/Changes.md) for a changelog and roadmap for this project.

## File structure

See [here](docs/FileStructure.md) for information about the porjects file structure.

## Dependancies and Credits

System Dependancies:

- [nim](https://nim-lang.org/) (required to compile)

Nimble Dependancies:

* [dimscord](https://nimble.directory/pkg/dimscord) (Discord API library)

* [pixie](https://nimble.directory/pkg/pixie) (2D graphics library)

Optional:

- [GNU Make](https://www.gnu.org/software/make/) (Makefile build tool, see [Compiling and Hosting](#Compiling-and-Hosting))
