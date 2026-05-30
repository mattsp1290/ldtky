# Package
version       = "0.1.0"
author        = "Matt Spurlin"
description   = "Nim library for loading and parsing LDtk project files"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["tests", "examples", "docs"]

requires "nim >= 2.0.0"

task test, "Run unit tests":
  let flags = "--mm:orc --hints:off"
  let testFiles: seq[string] = @[]
  for f in testFiles:
    exec "nim c " & flags & " -r " & f

task check, "Check library modules compile":
  let flags = "--mm:orc --hints:off"
  let modules = @[
    "src/ldtky/errors.nim",
    "src/ldtky/enums.nim",
  ]
  for m in modules:
    exec "nim check " & flags & " " & m
