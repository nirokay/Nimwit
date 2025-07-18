# Privacy Information

This document describes what information is collected by the bot.

## Data collection

### 2022 - current

The images created with the `/image` command are stored on disk, however will be deleted regularly.

* **User data:**
    ```json
    {
        "DISCORD_ID": {
            "id" :"DISCORD_ID",       // your Discord ID
            "money": 0,               // Currency (based on how many messages you have written)
            "lastDailyReward":null,   // timestamp of last usage of `/daily`
            "currentDailyStreak":null // streak of `/daily`
        }
    }
    ```

* **Server data:**
    ```json
    {
        "SERVER_ID": {
            "id" :"SERVER_ID",                          // Discord server ID
            "channels": {                               // all are manually set by a member with "Manage Channels" permissions
                "settingWelcomeMessages": "CHANNEL_ID",
                "settingUserChanges": "CHANNEL_ID",
                "settingMessageLogging": "CHANNEL_ID"
            }
        }
    }
    ```
