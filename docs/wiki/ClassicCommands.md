# Classic Commands

Classic commands are commands that are sent into the regular chat with the bot prefix.

These commands often have aliases. You can see those, and some additional information, by running the [documentation command](#docs) (example: `docs [command-name]`).

## Categories

### 🗨️ Chatting

#### hello

Bot responds with a range of greetings.

#### image

See `image list` for a list of images. This command allows you to put custom text on-top of a collection of images (mostly shitposts and meme-templates).

Usage:

`image gigachad People who use Nim`

`image nerdemoji "Heyyy YouTube, welcome to another prank video!!!!"`

#### echo / echodel

Echoes back anything you say to the bot. Echodel removes your command-message afterwards.

Usage:

`echo Hello World`

`echodel Uhhh spooky, where did my initial message go??`

#### truth-o-meter

This command evaluates a given statement depending on its characters. Upper- and Lowercase letters make a difference in evaluation, as this makes it more funny. The same statement will be evaluated the same, not depending on time or user, who executes it.

Usage:

`truth-o-meter Are cats worse than dogs?` (9%, totally unbiased pick)

`truth-o-meter Will tomorrow be a good day?` (55%, it is up to you :3)

#### love-o-meter

Evaluation of love between two users. The value is calculated based on their user IDs and remains constant.

Usage:

`love-o-meter @User1 @User2`

`love-o-meter @AnotherUser` (@AnotherUser and you are evaluated)

#### yes-no-maybe

Randomly respons with yes, no or maybe to a question. This is purely random, and does not stay constant with the question.

Usage:

`yes-no-maybe Do you like art?`

`yes-no-maybe Are cats the best?` (obvious answer is yes)

### 🧮 Math

#### roll

Rolls one or multiple dice. Supports DnD notation and seperated notation. This command also calculates the sum of all rolls and the average of all throws.

Usage:

`roll` (throws a 6-sided die, once)

`roll 2 6` (throws a 6-sided die, twice)

`roll 4d20` (throws a 20-sided die, four times)

#### flip

Flips a coin and randomly lands on Heads or Tails.

#### randomword

Returns a random word from a given sentence or collection of words. Words are devided by spaces.

Usage:

`randomword Option1 Option2 Long_Option_Three Option4`

`randomword Hey how are you?` -> (randomly choses between: "Hey", "how", "are", or "you?")

### 🫂 Social

#### profile-display

Displays your or another users profile information. This information is publicly available and nothing sensitive (for example ID, profile picture, name and discriminator, etc.)

Usage:

`profile-display` (displays your profile)

`profile-display @User` (displays profile of @User)

#### hug / pat / kiss / boop / slap

Sends a gif performing one of those actions. This is meant to be aimed at another user.

Usage:

`hug @FriendlyUser`

`slap @AngryUser`

### 💰 Economy

#### balance

This command checks your or another persons current money balance.

Usage:

`balance` (checks your balance)

`balance @User` (checks @User's balance)

#### transfer-money

This command allows you to transfer money to another user.

Usage:

`transfer-money 200 @Recipient`

#### daily

You can collect your daily money reward using this command. It starts of at being 500/day but the higher your daily streak rises, the more daily money you will earn.

### ⚙️ System

#### ping

Pong! Sends the current ping and the API response time.

#### help

This command displays all available commands (including slash commands).

#### docs

Using the documentation command you can get in-depth information about a command, for example its correct usage, description and aliases.

Usage:

`docs docs`

`docs help`

`docs transfer-money`

#### info

Get general information about this bot as well as some links. These include bot-invite, source-code and the github issue page.
