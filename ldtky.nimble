# Package
version       = "0.1.0"
author        = "Matt Spurlin"
description   = "Nim library for loading and parsing LDtk project files"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["tests", "examples", "docs"]

requires "nim >= 2.0.0"

const sharedFlags = "--hints:off"  # --mm:orc comes from nim.cfg

task test, "Run unit tests":
  let testFiles = @[
    "tests/test_json_helpers.nim",
    "tests/test_field_value.nim",
    "tests/test_primitives.nim",
    "tests/test_instances.nim",
    "tests/test_defs.nim",
  ]
  for f in testFiles:
    exec "nim c " & sharedFlags & " -r " & f

task checkModules, "Check library modules compile":
  let modules = @[
    "src/ldtky/errors.nim",
    "src/ldtky/enums.nim",
    "src/ldtky/primitives.nim",
    "src/ldtky/json_helpers.nim",
    "src/ldtky/field_value.nim",
    "src/ldtky/instances/layer_utils.nim",
    "src/ldtky/defs/intgrid.nim",
    "src/ldtky/defs/enums.nim",
    "src/ldtky/defs/tileset.nim",
    "src/ldtky/defs/field.nim",
    "src/ldtky/defs/entity.nim",
    "src/ldtky/instances/field.nim",
    "src/ldtky/instances/toc.nim",
    "src/ldtky/parse_utils.nim",
    "src/ldtky/instances/entity.nim",
    "src/ldtky/defs/layer.nim",
    "src/ldtky/instances/layer.nim",
    "src/ldtky/instances/level.nim",
    "src/ldtky/defs/defs.nim",
    "src/ldtky/defs.nim",
    "src/ldtky/instances/world.nim",
  ]
  for m in modules:
    exec "nim check " & sharedFlags & " " & m
