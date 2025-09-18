# Privacy Information

This document describes what information is collected by the bot.

## Data collection

Images created with the `/image` command are generated and stored on disk, however will be deleted regularly.

Messages sent in servers with the bot added or in the bots DM will increment the currency count by `1`,
as well as processed by substring analysis for [bot reactions (emoji reaction and text reaction)](./Commands.md#substring-reactions).
The content of your messages will not be stored in any way.

### 2023-02-07 - current

* **User data:**
  * Discord user ID
  * currency (gained by commands or `1` for every message the bot sees sent by you
  * date of last `/daily` command use and current streak

* **Server data:**
  * Discord server ID
  * server channel IDs, that have been set to perform a task:
    * join/leave messages
    * user edits
    * message edits and deletions

### 2022-12-14 - 2023-02-07

none
