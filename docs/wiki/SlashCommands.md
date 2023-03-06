# Slash Commands

## Categories

### 🗨️ Chatting

#### echomessage

Similar to the [usual echo command](ClassicCommands.md#echo) this command echoes anything you say. The only difference is, how it looks at the end.

Usage:

/echomessage message:`This string will be echoed!`

### ⚙️ System

#### help

This command differs from the [usual help command](ClassicCommands.md#help), as it only provides basic usage information, as well as displays the prefix for [classic commands](ClassicCommands.md).

### settings

This command can only be executed on servers and required the "Manage Channels" permission!

It displays the current server settings in a json format.

#### setchannel

This command can only be executed on servers and required the "Manage Channels" permission!

You can tell the bot to send specific event messages (such as people joinging/leaving, message logging, member changes logging) to be sent in the current channel.

Usage:

/setchannel task:`settingWelcomeMessages`

/setchannel task:`settingMessageLogging`
