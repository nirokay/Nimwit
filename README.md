# Nimwit discord bot

## About

Nimwit is yet another general-purpose discord bot written in Nim. Most features are taken from my prior discord bot development ventures and also come from my friend group. If you have a feature request, feel free to open a GitHub issue! :)

You can of-course [invite the bot](https://discord.com/api/oauth2/authorize?client_id=1056828609265926145&permissions=277092625472&scope=bot) to your server (should be online pretty much 24/7).

## Features

Features include:

* typical system commands like `help` (lists all commands), `docs` (displays a short, in-depth documentation about a specific command) and `ping`!

* several math commands like rolling dice, flipping a coin or choosing a random word from a sentence.

* social commands that send gifs of hugs, head pats, slaps etc.

* the image command lets you create memes from templates and put your own text onto it (see `image list` for a list of all template images).

* chatting commands like `hello` (the bot will greet you back) and `truth-o-meter`, which tells you the truth-value of a specific statement.

Even more features will be added throughout development!

## Compiling and Hosting

Compiling to an executable is very easy. Simply run `make build` or `nimble build -d:ssl` in your terminal. This will compile all nim source code into a single executable.

You will still need the `public` and `private` directories next to your executable though, as configuration and your token is stored inside those, that get read on executable execution.

## File structure

See [here](docs/FileStructure.md) for information about the porjects file structure.

## Dependancies and Credits

Nimble Dependancies:

* [dimscord](https://nimble.directory/pkg/dimscord) (Discord API library)

* [pixie](https://nimble.directory/pkg/pixie) (2D graphics library)
