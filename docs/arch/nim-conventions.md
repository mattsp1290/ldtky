# Nim Library Conventions (doggy/observy)

## Directory layout
```
ldtky.nimble          # package metadata
config.nims           # switch("mm","orc") + switch("path", thisDir() & "/src")
nim.cfg               # --mm:orc
src/ldtky/            # library modules (flat + subsystem dirs)
  ldtky.nim           # main entry: re-exports all submodules
  errors.nim          # LdtkParseError exception
  enums.nim           # all pure enum types
  primitives.nim      # GridPoint, TilesetRect, Tile, TileCustomMetadata
  field_value.nim     # FieldValue object variant
  json_helpers.nim    # JsonNode helpers for __-prefixed keys + Option[T]
  defs/               # definition types (LayerDef, EntityDef, EnumDef, etc.)
  instances/          # instance types (LayerInstance, EntityInstance, etc.)
tests/
  test_*.nim          # mirrors module name (e.g. test_primitives.nim)
  fixtures/           # vendored .ldtk files from ~/git/ldtk/tests/
examples/
  nim.cfg             # --mm:orc + path="../src"
  basic.nim
  entities.nim
  tileset.nim
```

## Nimble file
- `srcDir = "src"`, `skipDirs = @["tests","examples","docs"]`
- `requires "nim >= 2.0.0"` only — zero Nimble deps
- `task test`: list each tests/test_*.nim explicitly; run with `nim c --mm:orc -r <file>`
- `task check`: `nim check` each src/ module

## Compiler flags (required everywhere)
- `--mm:orc` — ARC-based memory, required
- No `--threads:on` needed (pure parser, no threading)

## Test style (follow observy)
- Use `unittest` module with `suite` / `test` / `check`
- Import the module being tested directly
- One test file per source module

## Re-exports (follow observy)
```nim
import ldtky/errors;         export errors
import ldtky/enums;          export enums
import ldtky/primitives;     export primitives
import ldtky/field_value;    export field_value
# ... etc
```

## Nullable fields
- Use `Option[T]` for all nullable JSON fields (type arrays containing "null")
- Never use sentinel/zero-value defaults for optional types
- Import std/options in every module that uses Option[T]
