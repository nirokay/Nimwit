# Package

version       = "2.3.0"
author        = "nirokay"
description   = "A general-purpose discord bot written in Nim."
license       = "GPL-3.0-only"
srcDir        = "src"
bin           = @["Nimwit"]


# Dependencies

# - Nim:
requires "nim == 1.6.20" # some dependencies do not work well with Nim 2.x versions :(
# - Nimble libraries:
requires "dimscord#head", "pixie", "nimcatapi"
# - Custom libraries:
requires "https://github.com/nirokay/db_connector"
