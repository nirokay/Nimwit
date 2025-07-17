# Nimwit discord bot

![Nimwit logo](.github/nimwit.png)

## About

Nimwit is yet another general-purpose discord bot written in Nim. Most features are taken from my
prior discord bot development ventures and also come from my friend group. If you have a feature
request, feel free to open a GitHub issue! :)

Of course you can [invite the bot](https://www.nirokay.com/discord/invite/nimwit)
to your server or add it to your apps (should be online pretty much 24/7).

<small>If the link above did not work: [try this one](https://discord.com/oauth2/authorize?client_id=1056828609265926145)</small>

## Features

This bot features some silly/social stuff, like patting, booping, hugging, slapping other users,
a basic currency system and basic logging things (users joining/leaving, message deletions/edits).

## Compiling and Hosting

Compiling to an executable is very easy. Simply run `make build` or `nimble build -d:ssl` in your
terminal. This will compile all nim source code into a single executable.

You will still need the `public` and `private` directories next to your executable though, as
configuration and your token is stored inside there.

The `install.sh` script takes care of everything and sets up a systemd unit, that runs on system
startup!

## Changes

See [here](docs/Changes.md) for a changelog and roadmap for this project.

## File structure

See [here](docs/FileStructure.md) for information about the projects file structure.

## Dependencies and Credits

System Dependencies:

* [nim](https://nim-lang.org/) (required to compile)

Nimble Dependencies:

* [dimscord](https://nimble.directory/pkg/dimscord) (Discord API library)
* [pixie](https://nimble.directory/pkg/pixie) (2D graphics library)

Optional:

* [GNU Make](https://www.gnu.org/software/make/) (Makefile build tool, see
[Compiling and Hosting](#Compiling-and-Hosting))
