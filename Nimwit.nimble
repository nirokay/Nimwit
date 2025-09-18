# Package

version       = "2.5.1"
author        = "nirokay"
description   = "A general-purpose discord bot written in Nim."
license       = "GPL-3.0-only"
srcDir        = "src"
bin           = @["Nimwit"]


# Tasks

task commanddocs, "Generates command docs":
    exec "nim r -d:ssl src/tasks/docs.nim"


# Dependencies

# - Nim:
requires "nim >= 2.0.6"
# - Nimble libraries:
requires "dimscord#head", "pixie", "nimcatapi", "db_connector"
