# Nimwit discord bot

## About

Nimwit is yet another general-purpose discord bot written in Nim. 

You can also [invite the bot](https://discord.com/api/oauth2/authorize?client_id=1056828609265926145&permissions=277092625472&scope=bot) to your server.

## Features

Nimwit has several features:

* math commands:
  
  * pick random word from string
  
  * rolling dice
  
  * flip coin

* social commands:
  
  * sending gifs of hugs, pats, kisses, slaps, nose-boops directed at another user

* chatting commands:
  
  * yes no maybe (randomly answers a question)
  
  * truth-o-meter (calculates the truth-value of a message)

Many more are planned for the future! :)

## Compiling and Hosting

Compiling to an executable is very easy. Simply run `make build` or `nimble build -d:ssl` in your terminal. This will compile all nim source code into a single executable.

You will still need the `public` and `private` directories next to your executable though, as configuration and your token is stored inside those, that get read on executable execution.

## File structure

See [here](docs/FileStructure.md) for information about the porjects file structure.


