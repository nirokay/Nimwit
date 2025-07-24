# Package

version       = "2.2.0"
author        = "nirokay"
description   = "A general-purpose discord bot written in Nim."
license       = "GPL-3.0-only"
srcDir        = "src"
bin           = @["Nimwit"]


# Dependencies

requires "nim == 1.6.20" # some dependencies do not work well with Nim 2.x versions :(
requires "dimscord#head", "pixie", "nimcatapi", "db_connector"
