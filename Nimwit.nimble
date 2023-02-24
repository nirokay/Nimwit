# Package

version       = "1.0.0"
author        = "nirokay"
description   = "A general-purpose discord bot written in Nim."
license       = "GPL-3.0-only"
srcDir        = "src"
bin           = @["Nimwit"]


# Dependencies

requires "nim >= 1.6.6"
requires "dimscord >= 1.4.0", "pixie"
