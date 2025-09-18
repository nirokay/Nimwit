# Privacy Information

This document describes what information is collected by the bot.

## Data collection

Images created with the `/image` command are generated and stored on disk, however will be deleted regularly.

Messages sent by you, in servers with the bot added or in the bots DM, will increment the currency count by `1`,
as well as [processed](../src/substringdefs.nim#L32) by substring analysis for
[bot reactions (emoji reaction and text reaction)](./Commands.md#substring-reactions).
The content of your messages will not be stored in any way.

### 2023-02-07 - current

* [**User data:**](../src/sql/users/initUsers.sql)
  * Discord user ID
  * currency (gained by commands, or `1` for every message the bot sees sent by you)
  * date of last `/daily` command use and current streak

* [**Server data:**](../src/sql/servers/initServers.sql)
  * Discord server ID
  * server channel IDs, that have been set to perform a task (the content is not stored by the bot):
    * join/leave messages
    * user profile edits
    * message edits and deletions

### 2022-12-14 - 2023-02-07

none
