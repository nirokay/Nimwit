# Nimwit command reference

This is a list of all available commands for Nimwit.

## Slash Commands

### Command `/info`

**Category:** System

**Description:** Provides information about the bot.

### Command `/settings` (*server only*)

**Category:** System

**Description:** See the current server settings

**Required permissions:**
* `Manage Channels`

### Command `/setchannel` (*server only*)

**Category:** System

**Description:** Assign task to current channel

**Required permissions:**
* `Manage Channels`

**Options:**
  * `task` (*required*)
  
  **Description:** Choose task for this channel
  
  **Choices:**
    * `welcome-and-goodbye-messages`
    * `message-changes-and-deletions-logging`
    * `user-profile-changes`

### Command `/balance`

**Category:** Economy

**Description:** See a users balance.

**Options:**
  * `user` (*required*)
  
  **Description:** Target user to see balance of
  

### Command `/transfer`

**Category:** Economy

**Description:** Transfer currency to another user

**Options:**
  * `user` (*required*)
  
  **Description:** Target user to transfer currency to
  
  * `amount` (*required*)
  
  **Description:** Amount of currency to transfer
  

### Command `/daily`

**Category:** Economy

**Description:** Claim your daily currency; the amount grows with your daily streak.

### Command `/echomessage`

**Category:** Chatting

**Description:** Echoes back anything that you say!

**Options:**
  * `message` (*required*)
  
  **Description:** This string will be sent as a message
  

### Command `/image`

**Category:** Chatting

**Description:** Creates an image from a template with custom text.

**Options:**
  * `image` (*required*)
  
  **Description:** Choose an image template
  
  **Choices:**
    * `calendar-1984`
    * `big-brother`
    * `definition-based`
    * `definition-cringe`
    * `wake-up-america`
    * `no-step-on-snek`
    * `i-serve-the-soviet-union`
    * `monkey`
    * `undertale-deserving-mercy`
    * `nerd-emoji`
    * `gigachad`
    * `anime-shy`
    * `megamind-no-bitches`
    * `joker`
    * `hate-politics`
  * `text` (*required*)
  
  **Description:** Custom text to be put ontop of the image
  

### Command `/truth-o-meter`

**Category:** Chatting

**Description:** Evaluates the truth-percentage of a given statement.

**Options:**
  * `statement` (*required*)
  
  **Description:** Statement to evaluate
  

### Command `/love-o-meter`

**Category:** Chatting

**Description:** Evaluates the amount of love between two users calculated based on their unique discord user IDs.

**Options:**
  * `first` (*required*)
  
  **Description:** First user
  
  * `second` (*required*)
  
  **Description:** Second user
  

### Command `/ynm`

**Category:** Chatting

**Description:** Responds to a question with yes, no or maybe randomly.

**Options:**
  * `statement` (*required*)
  
  **Description:** Statement to evaluate
  

### Command `/profile`

**Category:** Social

**Description:** Displays the users profile and some additional information.

**Options:**
  * `user` (*required*)
  
  **Description:** Display this users profile
  

### Command `/hug`

**Category:** Social

**Description:** Sends a gif performing this action in a message.

**Options:**
  * `user` (*required*)
  
  **Description:** User to hug
  

### Command `/pat`

**Category:** Social

**Description:** Sends a gif performing this action in a message.

**Options:**
  * `user` (*required*)
  
  **Description:** User to pat
  

### Command `/kiss`

**Category:** Social

**Description:** Sends a gif performing this action in a message.

**Options:**
  * `user` (*required*)
  
  **Description:** User to kiss
  

### Command `/boop`

**Category:** Social

**Description:** Sends a gif performing this action in a message.

**Options:**
  * `user` (*required*)
  
  **Description:** User to nose boop
  

### Command `/slap`

**Category:** Social

**Description:** Sends a gif performing this action in a message.

**Options:**
  * `user` (*required*)
  
  **Description:** User to slap
  

### Command `/cat`

**Category:** Social

**Description:** Requests a random cat image from thecatapi.com!

### Command `/dog`

**Category:** Social

**Description:** Requests a random dog image from thedogapi.com!

### Command `/roll`

**Category:** Math

**Description:** Rolls a die. Accepts custom side and throw amounts.

**Options:**
  * `amount`
  
  **Description:** How many dice to roll (default: 1x)
  
  * `die`
  
  **Description:** What die to roll (default: 6-sided die)
  
  **Choices:**
    * `3-sided die`
    * `4-sided die`
    * `6-sided die`
    * `8-sided die`
    * `10-sided die`
    * `12-sided die`
    * `20-sided die`
    * `100-sided die`

### Command `/flip`

**Category:** Math

**Description:** Flips a coin.

### Command `/flop`

**Category:** Math

**Description:** Flips... or i guess... flops an unfair coin.

### Command `/randomword`

**Category:** Math

**Description:** Picks a random word from provided arguments (split by commas).

**Options:**
  * `list` (*required*)
  
  **Description:** List of words separated by commas
  

### Command `/convert-length`

**Category:** Undefined

**Description:** Converts between Length units.

**Options:**
  * `number` (*required*)
  
  **Description:** Number
  
  * `from` (*required*)
  
  **Description:** Convert from this unit
  
  **Choices:**
    * `km (kilometre)`
    * `m (metre)`
    * `cm (centimetre)`
    * `mm (millimetre)`
    * `μm (micrometre)`
    * `nm (nanometre)`
    * `pm (picometre)`
    * `mi (mile)`
    * `n-mi (nautical mile)`
    * `yd (yard)`
    * `ft (foot)`
    * `in (inch)`
    * `au (astronomical unit)`
    * `ly (light year)`
  * `to` (*required*)
  
  **Description:** Convert to this unit
  
  **Choices:**
    * `km (kilometre)`
    * `m (metre)`
    * `cm (centimetre)`
    * `mm (millimetre)`
    * `μm (micrometre)`
    * `nm (nanometre)`
    * `pm (picometre)`
    * `mi (mile)`
    * `n-mi (nautical mile)`
    * `yd (yard)`
    * `ft (foot)`
    * `in (inch)`
    * `au (astronomical unit)`
    * `ly (light year)`

### Command `/convert-area`

**Category:** Undefined

**Description:** Converts between Area units.

**Options:**
  * `number` (*required*)
  
  **Description:** Number
  
  * `from` (*required*)
  
  **Description:** Convert from this unit
  
  **Choices:**
    * `km² (square kilometre)`
    * `m² (square metre)`
    * `cm² (square centimetre)`
    * `mm² (square millimetre)`
    * `mi² (square mile)`
    * `yd² (square yard)`
    * `ft² (square foot)`
    * `in² (square inch)`
    * `ha (hectare)`
    * `ac (acre)`
  * `to` (*required*)
  
  **Description:** Convert to this unit
  
  **Choices:**
    * `km² (square kilometre)`
    * `m² (square metre)`
    * `cm² (square centimetre)`
    * `mm² (square millimetre)`
    * `mi² (square mile)`
    * `yd² (square yard)`
    * `ft² (square foot)`
    * `in² (square inch)`
    * `ha (hectare)`
    * `ac (acre)`

### Command `/convert-temperature`

**Category:** Undefined

**Description:** Converts between Temperature units.

**Options:**
  * `number` (*required*)
  
  **Description:** Number
  
  * `from` (*required*)
  
  **Description:** Convert from this unit
  
  **Choices:**
    * `°C (degrees celsius)`
    * `K (kelvin)`
    * `°F (degrees fahrenheit)`
    * `°R (degrees rankine)`
  * `to` (*required*)
  
  **Description:** Convert to this unit
  
  **Choices:**
    * `°C (degrees celsius)`
    * `K (kelvin)`
    * `°F (degrees fahrenheit)`
    * `°R (degrees rankine)`

### Command `/convert-mass`

**Category:** Undefined

**Description:** Converts between Mass units.

**Options:**
  * `number` (*required*)
  
  **Description:** Number
  
  * `from` (*required*)
  
  **Description:** Convert from this unit
  
  **Choices:**
    * `t (metric ton)`
    * `kg (kilogram)`
    * `g (gram)`
    * `mg (milligram)`
    * `st (short/us ton)`
    * `lt (long/british ton)`
    * `lb (pound)`
    * `oz (ounce)`
    * `ct (carat)`
  * `to` (*required*)
  
  **Description:** Convert to this unit
  
  **Choices:**
    * `t (metric ton)`
    * `kg (kilogram)`
    * `g (gram)`
    * `mg (milligram)`
    * `st (short/us ton)`
    * `lt (long/british ton)`
    * `lb (pound)`
    * `oz (ounce)`
    * `ct (carat)`

### Command `/convert-speed`

**Category:** Undefined

**Description:** Converts between Speed units.

**Options:**
  * `number` (*required*)
  
  **Description:** Number
  
  * `from` (*required*)
  
  **Description:** Convert from this unit
  
  **Choices:**
    * `m/s (metres per second)`
    * `km/s (kilometres per second)`
    * `km/h (kilometres per hour)`
    * `ftps (feet per second)`
    * `mph (miles per hour)`
    * `kn (knot)`
    * `Ma (mach/speed of sound)`
  * `to` (*required*)
  
  **Description:** Convert to this unit
  
  **Choices:**
    * `m/s (metres per second)`
    * `km/s (kilometres per second)`
    * `km/h (kilometres per hour)`
    * `ftps (feet per second)`
    * `mph (miles per hour)`
    * `kn (knot)`
    * `Ma (mach/speed of sound)`

### Command `/convert-volume`

**Category:** Undefined

**Description:** Converts between Volume units.

**Options:**
  * `number` (*required*)
  
  **Description:** Number
  
  * `from` (*required*)
  
  **Description:** Convert from this unit
  
  **Choices:**
    * `L (litre)`
    * `ml (millilitre)`
    * `cm³ (cubic centimetre)`
    * `m³ (cubic metre)`
    * `gal (us gallon)`
    * `i-gal (british/imperial gallon)`
    * `pt (us pint)`
    * `yd³ (cubic yard)`
    * `dp (drop)`
    * `in³ (cubic inch)`
    * `ft³ (cubic foot)`
    * `cup (us cup)`
    * `i-cup (british/imperial cup)`
    * `tbs (us tablespoon)`
    * `i-tbs (british/imperial tablespoon)`
    * `ts (us teaspoon)`
    * `i-ts (british/imerpial teaspoon)`
    * `fl-oz (us fluid ounce)`
    * `i-fl-oz (british/imerpial fluid ounce)`
    * `qt (us quart)`
    * `i-qt (british/imperial quart)`
    * `bb (beerbarrel)`
    * `ob (oilbarrel)`
  * `to` (*required*)
  
  **Description:** Convert to this unit
  
  **Choices:**
    * `L (litre)`
    * `ml (millilitre)`
    * `cm³ (cubic centimetre)`
    * `m³ (cubic metre)`
    * `gal (us gallon)`
    * `i-gal (british/imperial gallon)`
    * `pt (us pint)`
    * `yd³ (cubic yard)`
    * `dp (drop)`
    * `in³ (cubic inch)`
    * `ft³ (cubic foot)`
    * `cup (us cup)`
    * `i-cup (british/imperial cup)`
    * `tbs (us tablespoon)`
    * `i-tbs (british/imperial tablespoon)`
    * `ts (us teaspoon)`
    * `i-ts (british/imerpial teaspoon)`
    * `fl-oz (us fluid ounce)`
    * `i-fl-oz (british/imerpial fluid ounce)`
    * `qt (us quart)`
    * `i-qt (british/imperial quart)`
    * `bb (beerbarrel)`
    * `ob (oilbarrel)`

## Substring Reactions

### Banana reaction

**Trigger prerequisites:**

Any of the following substrings...

* `banana`

... will be reacted to with:

* Emoji: 🍌

### ACAB gets reacted with 'a cab'... get it????

**Trigger prerequisites:**

Any of the following substrings...

* `acab`
* `a c a b`
* `a.c.a.b.`
* ` 1312 `

... will be reacted to with:

* Emoji: 🚕

### Profanity reactions

**Trigger prerequisites:**

Any of the following substrings...

* `fuck`
* `bitch`
* `b1tch`
* `whore`
* `wh0re`
* `sex`
* `secks`
* `seggs`
* `suck`
* `lick`
* `penis`
* `dick`
* `d1ck`
* `pussy`
* `pu$$y`
* `pus$y`
* `pu$sy`
* `ass`
* `shit`
* `piss`
* `cum`
* `kys`
* `kill yourself`
* `fick`
* `schlampe`
* `hure`
* `arsch`
* `seggs`
* `leck`
* `schwanz`
* `scheiße`
* `scheisze`
* `scheisse`
* `scheise`

... will be reacted to with:

* Emoji: 👀

### Fascist shit

**Trigger prerequisites:**

Any of the following substrings...

* ` AfD `
* ` AgD `
* ` NPD `
* ` CDU `
* ` CSU `
* ` CxU `
* ` Söder `
* ` Soeder `
* ` Weidel `
* ` Merz `

... will be reacted to with:

* Emoji: 🤢

### Making fun of fascists

**Trigger prerequisites:**

Any of the following substrings...

* ` die grünen `
* ` die grüne `

... will be reacted to with:

* Emoji: 🤬

### Wholesome

**Trigger prerequisites:**

Any of the following substrings...

* `wholesome`
* `wholesum`
* `whole sum`
* `holesome`
* `holesum`
* `hole sum`
* `holsum`

... will be reacted to with:

* Emoji: 😇

### Reddit

**Trigger prerequisites:**

Any of the following substrings...

* `for the gold kind stranger`
* `for the gold, kind stranger`

... will be reacted to with:

* Emoji: 🏅

### USA

**Trigger prerequisites:**

Any of the following substrings...

* ` usa `
* `u.s.a.`
* `united states of america`
* `the united states`
* `murica`
* `america`
* `us.a`
* `u.sa`

... will be reacted to with:

* Emoji: 🇺🇸

### Funny numbers

**Trigger prerequisites:**

Any of the following substrings...

* ` 69 `
* ` 420 `
* `6969`
* `42069`
* `69420`

... will be reacted to with:

* Emoji: 😏
* Response:
  > haha funni number

### frfr

**Trigger prerequisites:**

Any of the following substrings...

* `fr fr`
* `frfr`
* `for real for real`

... will be reacted to with:

* Emoji: 🤨

### Cat

**Trigger prerequisites:**

Any of the following substrings...

* `el gato`
* `el gatitio`
* `the cat`
* `the kitten`
* `the kitty`
* `die Katze`
* `der Kater`
* `das Kätzchen`

... will be reacted to with:

* Emoji: 🐈

### Linux copypasta

**Trigger prerequisites:**

Any of the following substrings...

* ` linux `

... will be reacted to with:

* Emoji: ‼️
* Response:
  > I'd just like to interject for a moment. What you're referring to as Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, GNU plus Linux. Linux is not an operating system unto itself, but rather another free component of a fully functioning GNU system made useful by the GNU corelibs, shell utilities and vital system components comprising a full OS as defined by POSIX.
  > 
  > Many computer users run a modified version of the GNU system every day, without realizing it. Through a peculiar turn of events, the version of GNU which is widely used today is often called Linux, and many of its users are not aware that it is basically the GNU system, developed by the GNU Project.
  > 
  > There really is a Linux, and these people are using it, but it is just a part of the system they use. Linux is the kernel: the program in the system that allocates the machine's resources to the other programs that you run. The kernel is an essential part of an operating system, but useless by itself; it can only function in the context of a complete operating system. Linux is normally used in combination with the GNU operating system: the whole system is basically GNU with Linux added, or GNU/Linux. All the so-called Linux distributions are really distributions of GNU/Linux!

with a 5.0% chance!
