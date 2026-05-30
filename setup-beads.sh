#!/usr/bin/env bash
# Project: ldtky — Nim library for loading LDtk project files
# Generated: 2026-05-30

set -e

# ──────────────────────────────────────────────────────────────────────────────
# Initialize beads
# ──────────────────────────────────────────────────────────────────────────────
if [ ! -d ".beads" ]; then
  bd init -p ldtky --non-interactive
fi

# ──────────────────────────────────────────────────────────────────────────────
# Write architecture context docs for agent reference
# ──────────────────────────────────────────────────────────────────────────────
mkdir -p docs/arch

cat > docs/arch/nim-conventions.md << 'NIMCONV'
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
NIMCONV

cat > docs/arch/schema-notes.md << 'SCHEMANOTES'
# LDtk JSON Schema Notes (v1.5.3)

## Module map
```
src/ldtky/errors.nim          # LdtkParseError
src/ldtky/enums.nim           # LayerKind, WorldLayout, ImageExportMode, etc.
src/ldtky/primitives.nim      # GridPoint, TilesetRect, Tile, TileCustomMetadata
src/ldtky/field_value.nim     # FieldValue object variant + FieldKind enum
src/ldtky/json_helpers.nim    # JsonNode helpers
src/ldtky/defs/enums.nim      # EnumDef, EnumDefValues, EnumTagValue
src/ldtky/defs/tileset.nim    # TilesetDef
src/ldtky/defs/intgrid.nim    # IntGridValueDef, IntGridValueGroupDef
src/ldtky/defs/field.nim      # FieldDef
src/ldtky/defs/entity.nim     # EntityDef
src/ldtky/defs/layer.nim      # LayerDef, AutoLayerRuleGroup, AutoRuleDef
src/ldtky/defs/defs.nim       # Definitions container
src/ldtky/instances/layer_utils.nim  # flip-bit decode, intGridCsv → 2D
src/ldtky/instances/field.nim        # FieldInstance
src/ldtky/instances/entity.nim       # EntityInstance, EntityReferenceInfos
src/ldtky/instances/layer.nim        # LayerInstance
src/ldtky/instances/level.nim        # Level, NeighbourLevel, LevelBgPosInfos
src/ldtky/instances/world.nim        # World
src/ldtky/instances/toc.nim          # TableOfContentEntry, TocInstanceData, CustomCommand
src/ldtky/project.nim                # LdtkJsonRoot + parseProject
src/ldtky/loader.nim                 # loadProject(path), external .ldtkl support
src/ldtky/ldtky.nim                  # public API re-exports
```

## __-prefixed fields — manual JsonNode access required
std/json's `to()` macro cannot handle fields named with `__` prefix.
Use `node["__cWid"].getInt()` directly. json_helpers.nim should wrap
these patterns with a safe `getField(node, "__cWid", int)` helper that
raises LdtkParseError on missing required fields.

Key __-prefixed fields by type:
- LayerInstance: __cHei, __cWid, __gridSize, __identifier, __opacity,
  __pxTotalOffsetX, __pxTotalOffsetY, __type, __tilesetRelPath (opt),
  __tilesetDefUid (opt)
- EntityInstance: __grid, __identifier, __pivot, __smartColor, __tags,
  __tile (opt), __worldX (opt), __worldY (opt)
- FieldInstance: __identifier, __type, __value, __tile (opt)
- FieldDef: __type
- LayerDef: __type
- EnumDefValues: __tileSrcRect (opt)
- Level: __bgColor, __neighbours, __smartColor, __bgPos (opt)
- TilesetDef: __cHei, __cWid

## Layer kinds (LayerKind enum)
IntGrid | Entities | Tiles | AutoLayer

## FieldValue object variant
```nim
type
  FieldKind* = enum
    fkInt, fkFloat, fkBool, fkString, fkColor, fkPoint, fkTile,
    fkEntityRef, fkEnum,
    fkIntArray, fkFloatArray, fkBoolArray, fkStringArray, fkColorArray,
    fkPointArray, fkTileArray, fkEntityRefArray, fkEnumArray
  FieldValue* = object
    case kind*: FieldKind
    of fkInt:       intVal*: int
    of fkFloat:     floatVal*: float
    of fkBool:      boolVal*: bool
    of fkString:    strVal*: string
    of fkColor:     colorVal*: string       # hex "#rrggbb"
    of fkPoint:     pointVal*: GridPoint
    of fkTile:      tileVal*: TilesetRect
    of fkEntityRef: entityRefVal*: EntityReferenceInfos
    of fkEnum:      enumVal*: string
    of fkIntArray:       intArr*: seq[int]
    of fkFloatArray:     floatArr*: seq[float]
    of fkBoolArray:      boolArr*: seq[bool]
    of fkStringArray:    strArr*: seq[string]
    of fkColorArray:     colorArr*: seq[string]
    of fkPointArray:     pointArr*: seq[GridPoint]
    of fkTileArray:      tileArr*: seq[TilesetRect]
    of fkEntityRefArray: entityRefArr*: seq[EntityReferenceInfos]
    of fkEnumArray:      enumArr*: seq[string]
```

## Tile flip bits
`Tile.f` is a 2-bit integer:
- bit 0 (f and 1 != 0): X flip
- bit 1 (f and 2 != 0): Y flip

## IntGrid CSV decoding
`intGridCsv` is a flat seq[int]. Map to 2D using __cWid and __cHei:
`grid[row][col] = intGridCsv[row * cWid + col]`

## Multi-world vs single-world
- Multi-world: `worlds[]` array is non-empty; levels are nested inside worlds
- Single-world: `worlds[]` is empty; `levels[]` at project root is the world
- Deprecated top-level fields (nullable): worldGridWidth, worldGridHeight,
  worldLayout — present in single-world files, absent/null in multi-world

## External levels
When `externalLevels` is true, each Level's `layerInstances` is null and
`externalRelPath` points to a `.ldtkl` file (sibling to the .ldtk file).
loader.nim must detect this and load .ldtkl files automatically.

## jsonVersion warning
Read `jsonVersion` from root; if != "1.5.3", emit a warning via stderr
but continue parsing. Do NOT raise an error — older files should load.

## Test fixtures (vendored from ~/git/ldtk/tests/, MIT license)
Key fixtures:
- _empty.ldtk          — minimal valid file
- grassAndDirt.ldtk    — basic tile layers
- lotsOfEntities.ldtk  — entity instances + field values
- multiWorldsTest.ldtk — multi-world layout
- manyRules.ldtk       — auto-layer rules
- largeGridVania.ldtk  — complex multi-level project
- labRefs.ldtk         — entity references
- lab1.ldtk / lab2.ldtk — external levels (paired)
SCHEMANOTES

echo "Context docs written to docs/arch/"

# ──────────────────────────────────────────────────────────────────────────────
# Phase 1: Setup & Infrastructure
# ──────────────────────────────────────────────────────────────────────────────
echo "Phase 1: Setup & Infrastructure..."

SETUP_DIRS=$(bd create "Create ldtky project directory structure" \
  -d "Create: src/ldtky/, src/ldtky/defs/, src/ldtky/instances/, tests/, tests/fixtures/, examples/. No .nim files yet — skeleton only. Reference: docs/arch/nim-conventions.md" \
  -p 0 -l prep -t chore --silent)

SETUP_NIMBLE=$(bd create "Write ldtky.nimble package file" \
  -d "Create ldtky.nimble at repo root. name=ldtky, version=0.1.0, author=Matt Spurlin, license=MIT, srcDir=src, skipDirs=[tests,examples,docs]. requires nim >= 2.0.0 (zero Nimble deps). Tasks: test (runs each tests/test_*.nim with nim c --mm:orc -r), check (nim check each src/ file). Model after /Users/punk1290/git/doggy/doggy.nimble." \
  -p 0 -l prep -t chore --silent)
bd dep add $SETUP_NIMBLE $SETUP_DIRS

SETUP_CONFIG=$(bd create "Write config.nims and nim.cfg compiler config" \
  -d "Create: (1) config.nims at root: switch(mm,orc) and switch(path, thisDir()&/src). (2) nim.cfg at root: --mm:orc. (3) examples/nim.cfg: --mm:orc and path=../src. Model after /Users/punk1290/git/observy/config.nims and /Users/punk1290/git/doggy/nim.cfg." \
  -p 0 -l prep -t chore --silent)
bd dep add $SETUP_CONFIG $SETUP_DIRS

# ──────────────────────────────────────────────────────────────────────────────
# Phase 2: Core Foundation
# ──────────────────────────────────────────────────────────────────────────────
echo "Phase 2: Core Foundation..."

CORE_ERRORS=$(bd create "Implement LdtkParseError exception type" \
  -d "Create src/ldtky/errors.nim. Define: type LdtkParseError* = object of ValueError. Add proc raiseParseError*(msg: string) that raises LdtkParseError. Add proc requireField*(node: JsonNode, field: string): JsonNode that raises LdtkParseError if field missing. Import std/json." \
  -p 0 -l prep -t feature --silent)
bd dep add $CORE_ERRORS $SETUP_DIRS

CORE_ENUMS=$(bd create "Define all LDtk enum types" \
  -d "Create src/ldtky/enums.nim. Define enums: LayerKind (lkIntGrid, lkEntities, lkTiles, lkAutoLayer), WorldLayout (wlFree, wlGridVania, wlLinearH, wlLinearV), ImageExportMode (iemNone, iemOneImagePerLayer, iemOneImagePerLevel, iemLayersAndLevels), IdentifierStyle (isUppercase, isMaintainCase), TileRenderMode (trmCover, trmFitInside, trmRepeat, trmStretch, trmFullSizeCropped, trmFullSizeUncropped, trmNineSlice), EntityRenderMode (ermRectangle, ermEllipse, ermTile, ermCross), EntityLimitBehavior, EntityLimitScope, CheckerMode, TileMode, CustomCommandWhen. Parse from string via case/of, raise LdtkParseError on unknown values." \
  -p 0 -l prep -t feature --silent)
bd dep add $CORE_ENUMS $SETUP_DIRS

CORE_JSON_HELPERS=$(bd create "Implement JsonNode helper utilities" \
  -d "Create src/ldtky/json_helpers.nim. Helpers for extracting fields from JsonNode including __-prefixed keys (std/json to() macro cannot handle these). Implement: getField[T](node: JsonNode, key: string): T (required field, raises LdtkParseError if missing/wrong type), getOpt[T](node: JsonNode, key: string): Option[T] (nullable/missing returns none(T)), getStr/getInt/getFloat/getBool wrappers. Import std/json, std/options, ldtky/errors. See docs/arch/schema-notes.md for list of __-prefixed fields." \
  -p 0 -l prep -t feature --silent)
bd dep add $CORE_JSON_HELPERS $CORE_ERRORS
bd dep add $CORE_JSON_HELPERS $SETUP_CONFIG

CORE_PRIMITIVES=$(bd create "Define primitive LDtk value types" \
  -d "Create src/ldtky/primitives.nim. Define types: GridPoint* = object (cx*, cy*: int), TilesetRect* = object (h*, w*, x*, y*, tilesetUid*: int), TileCustomMetadata* = object (data*: string, tileId*: int), Tile* = object (a*: float, f*, t*: int, px*, src*, d*: seq[int]). All public fields. No parsing yet — types only. Import std/options." \
  -p 1 -l prep -t feature --silent)
bd dep add $CORE_PRIMITIVES $CORE_ERRORS
bd dep add $CORE_PRIMITIVES $CORE_ENUMS

CORE_FIELD_VALUE=$(bd create "Design and implement FieldValue object variant" \
  -d "Create src/ldtky/field_value.nim. This is the key design task. Implement FieldKind enum (fkInt, fkFloat, fkBool, fkString, fkColor, fkPoint, fkTile, fkEntityRef, fkEnum, plus fkIntArray..fkEnumArray for array variants of each — 18 total) and FieldValue object variant with case kind: FieldKind. See docs/arch/schema-notes.md for the full type definition to implement. Also implement parseFieldValue(node: JsonNode, fieldType: string): FieldValue that dispatches on the __type string from FieldInstance. Import std/json, ldtky/primitives, ldtky/errors. EntityReferenceInfos type is needed here — define it as: EntityReferenceInfos* = object (entityIid*, layerIid*, levelIid*, worldIid*: string)." \
  -p 0 -l prep -t feature --silent)
bd dep add $CORE_FIELD_VALUE $CORE_PRIMITIVES
bd dep add $CORE_FIELD_VALUE $CORE_JSON_HELPERS

# ──────────────────────────────────────────────────────────────────────────────
# Phase 3: Definitions — Types & Parsing
# ──────────────────────────────────────────────────────────────────────────────
echo "Phase 3: Definitions..."

DEFS_ENUM=$(bd create "Implement EnumDef types and parsing" \
  -d "Create src/ldtky/defs/enums.nim. Types: EnumDefValues* = object (color*: int, id*: string, tileId*: Option[int], tileSrcRect*: Option[TilesetRect]), EnumDef* = object (identifier*, iid*: string, uid*: int, values*: seq[EnumDefValues], tags*: seq[string], externalFileChecksum*, externalRelPath*: Option[string], iconTilesetUid*: Option[int]), EnumTagValue* = object (enumValueId*: string, tileIds*: seq[int]). Implement parseEnumDef(node: JsonNode): EnumDef. Note: EnumDefValues has __tileSrcRect (double-underscore prefix) — use manual JsonNode access. Import ldtky/primitives, ldtky/json_helpers, ldtky/errors, std/options." \
  -p 1 -l impl -t feature --silent)
bd dep add $DEFS_ENUM $CORE_JSON_HELPERS
bd dep add $DEFS_ENUM $CORE_PRIMITIVES

DEFS_TILESET=$(bd create "Implement TilesetDef type and parsing" \
  -d "Create src/ldtky/defs/tileset.nim. Type: TilesetDef* = object (identifier*, iid*: string, uid*, tileGridSize*, padding*, spacing*, pxHei*, pxWid*, cHei*, cWid*: int, relPath*: Option[string], tagsSourceEnumUid*: Option[int], customData*: seq[TileCustomMetadata], enumTags*: seq[EnumTagValue], tags*: seq[string]). Fields __cHei and __cWid require manual JsonNode access. No image loading — metadata only. Implement parseTilesetDef(node: JsonNode): TilesetDef. Import ldtky/primitives, ldtky/defs/enums, ldtky/json_helpers, ldtky/errors, std/options." \
  -p 1 -l impl -t feature --silent)
bd dep add $DEFS_TILESET $DEFS_ENUM
bd dep add $DEFS_TILESET $CORE_JSON_HELPERS
bd dep add $DEFS_TILESET $CORE_PRIMITIVES

DEFS_INTGRID=$(bd create "Implement IntGrid value definition types and parsing" \
  -d "Create src/ldtky/defs/intgrid.nim. Types: IntGridValueDef* = object (color*: string, groupUid*, value*: int, identifier*: Option[string]), IntGridValueGroupDef* = object (uid*: int, color*, identifier*: Option[string]), IntGridValueInstance* = object (coordId*, v*: int). Implement parseIntGridValueDef, parseIntGridValueGroupDef, parseIntGridValueInstance. Import ldtky/json_helpers, ldtky/errors, std/options." \
  -p 1 -l impl -t feature --silent)
bd dep add $DEFS_INTGRID $CORE_JSON_HELPERS

DEFS_FIELD=$(bd create "Implement FieldDef type and parsing" \
  -d "Create src/ldtky/defs/field.nim. Type: FieldDef* = object — all fields from schema GROUP D FieldDef section in docs/arch/schema-notes.md. Key: identifier*, iid*, uid*: int or string as appropriate, fieldDefType*: string (maps from schema __type field — double-underscore, manual access), isArray*, canBeNull*: bool, min*, max*: Option[float], arrayMinLength*, arrayMaxLength*: Option[int], tilesetUid*: Option[int], doc*: Option[string], defaultOverride*: Option[JsonNode]. Implement parseFieldDef(node: JsonNode): FieldDef. Import ldtky/enums, ldtky/json_helpers, ldtky/errors, std/json, std/options." \
  -p 1 -l impl -t feature --silent)
bd dep add $DEFS_FIELD $CORE_ENUMS
bd dep add $DEFS_FIELD $CORE_JSON_HELPERS

DEFS_ENTITY_DEF=$(bd create "Implement EntityDef type and parsing" \
  -d "Create src/ldtky/defs/entity.nim. Type: EntityDef* = object with fields: identifier*, iid*: string, uid*, height*, width*: int, color*: string, pivotX*, pivotY*: float, renderMode*: EntityRenderMode, tileRenderMode*: TileRenderMode, fieldDefs*: seq[FieldDef], tags*: seq[string], tileId*, tilesetId*, maxHeight*, minHeight*, maxWidth*, minWidth*: Option[int], doc*: Option[string], and all remaining required fields from schema GROUP C. Implement parseEntityDef(node: JsonNode): EntityDef. Import ldtky/enums, ldtky/defs/field, ldtky/json_helpers, ldtky/errors, std/options." \
  -p 1 -l impl -t feature --silent)
bd dep add $DEFS_ENTITY_DEF $DEFS_FIELD
bd dep add $DEFS_ENTITY_DEF $CORE_ENUMS
bd dep add $DEFS_ENTITY_DEF $CORE_JSON_HELPERS

DEFS_LAYER_DEF=$(bd create "Implement LayerDef, AutoLayerRuleGroup, AutoRuleDef types and parsing" \
  -d "Create src/ldtky/defs/layer.nim. Three types: (1) AutoRuleDef* = object — all fields from schema GROUP H. (2) AutoLayerRuleGroup* = object (active*: bool, biomeRequirementMode*: int, name*: string, uid*: int, rules*: seq[AutoRuleDef], isOptional*: bool, usesWizard*: bool, requiredBiomeValues*: seq[string], collapsed*, color*: Option[string]). (3) LayerDef* = object — layerDefType* maps from schema __type (manual access), plus all fields from schema GROUP B. Implement parsers for all three. LayerDef.tilesetDefUid, autoSourceLayerDefUid, autoTilesetDefUid, uiColor, doc are nullable Option[int]/Option[string]. Import ldtky/enums, ldtky/defs/intgrid, ldtky/json_helpers, ldtky/errors, std/options." \
  -p 1 -l impl -t feature --silent)
bd dep add $DEFS_LAYER_DEF $DEFS_INTGRID
bd dep add $DEFS_LAYER_DEF $CORE_ENUMS
bd dep add $DEFS_LAYER_DEF $CORE_JSON_HELPERS

DEFS_CONTAINER=$(bd create "Implement Definitions container type and parsing" \
  -d "Create src/ldtky/defs/defs.nim. Type: Definitions* = object (entities*: seq[EntityDef], enums*: seq[EnumDef], externalEnums*: seq[EnumDef], layers*: seq[LayerDef], levelFields*: seq[FieldDef], tilesets*: seq[TilesetDef]). Implement parseDefinitions(node: JsonNode): Definitions. Import all defs submodules. Also create src/ldtky/defs.nim (aggregator) that imports and exports ldtky/defs/defs, ldtky/defs/enums, ldtky/defs/tileset, ldtky/defs/intgrid, ldtky/defs/field, ldtky/defs/entity, ldtky/defs/layer." \
  -p 1 -l impl -t feature --silent)
bd dep add $DEFS_CONTAINER $DEFS_ENUM
bd dep add $DEFS_CONTAINER $DEFS_TILESET
bd dep add $DEFS_CONTAINER $DEFS_INTGRID
bd dep add $DEFS_CONTAINER $DEFS_FIELD
bd dep add $DEFS_CONTAINER $DEFS_ENTITY_DEF
bd dep add $DEFS_CONTAINER $DEFS_LAYER_DEF

# ──────────────────────────────────────────────────────────────────────────────
# Phase 4: Instances — Types & Parsing
# ──────────────────────────────────────────────────────────────────────────────
echo "Phase 4: Instances..."

INST_LAYER_UTILS=$(bd create "Implement tile flip-bit and IntGrid CSV decode utilities" \
  -d "Create src/ldtky/instances/layer_utils.nim. Implement: (1) proc flipX*(f: int): bool = (f and 1) != 0, proc flipY*(f: int): bool = (f and 2) != 0. (2) proc decodeIntGridCsv*(csv: seq[int], cWid, cHei: int): seq[seq[int]] that maps flat intGridCsv array to 2D grid: grid[row][col] = csv[row * cWid + col]. (3) proc tileCoordId*(x, y, cWid: int): int = y * cWid + x. See docs/arch/schema-notes.md for flip-bit and CSV decode specs." \
  -p 1 -l impl -t feature --silent)
bd dep add $INST_LAYER_UTILS $CORE_PRIMITIVES

INST_FIELD=$(bd create "Implement FieldInstance type and parsing" \
  -d "Create src/ldtky/instances/field.nim. Type: FieldInstance* = object (identifier*: string, fieldType*: string, value*: Option[FieldValue], defUid*: int, tile*: Option[TilesetRect]). Fields __identifier, __type, __value, __tile all have double-underscore prefixes — use manual JsonNode access. __value can be JNull (returns none(FieldValue)). When non-null, parse using parseFieldValue from field_value.nim dispatching on __type string. Implement parseFieldInstance(node: JsonNode): FieldInstance. Import ldtky/field_value, ldtky/primitives, ldtky/json_helpers, ldtky/errors, std/options, std/json." \
  -p 1 -l impl -t feature --silent)
bd dep add $INST_FIELD $CORE_FIELD_VALUE
bd dep add $INST_FIELD $DEFS_FIELD
bd dep add $INST_FIELD $CORE_JSON_HELPERS

INST_ENTITY=$(bd create "Implement EntityInstance type and parsing" \
  -d "Create src/ldtky/instances/entity.nim. Type: EntityInstance* = object (identifier*: string, iid*: string, defUid*, height*, width*: int, grid*: seq[int], pivot*: seq[float], px*: seq[int], smartColor*: string, tags*: seq[string], fieldInstances*: seq[FieldInstance], tile*: Option[TilesetRect], worldX*, worldY*: Option[int]). Fields __grid, __identifier, __pivot, __smartColor, __tags, __tile, __worldX, __worldY all have double-underscore prefixes. Implement parseEntityInstance(node: JsonNode): EntityInstance. Import ldtky/instances/field, ldtky/primitives, ldtky/json_helpers, ldtky/errors, std/options." \
  -p 1 -l impl -t feature --silent)
bd dep add $INST_ENTITY $INST_FIELD
bd dep add $INST_ENTITY $CORE_JSON_HELPERS
bd dep add $INST_ENTITY $CORE_PRIMITIVES

INST_LAYER=$(bd create "Implement LayerInstance type and parsing for all 4 layer kinds" \
  -d "Create src/ldtky/instances/layer.nim. Type: LayerInstance* = ref object — use ref to avoid deep-copy cost. Fields: identifier*, iid*, layerType*: string (from __type), cHei*, cWid*, gridSize*, layerDefUid*, levelId*, pxOffsetX*, pxOffsetY*, seed*: int, opacity*: float, pxTotalOffsetX*, pxTotalOffsetY*: int, visible*: bool, autoLayerTiles*, gridTiles*: seq[Tile], entityInstances*: seq[EntityInstance], intGridCsv*: seq[int], optionalRules*: seq[int], tilesetRelPath*: Option[string], tilesetDefUid*, overrideTilesetUid*: Option[int]. All __ prefixes need manual access. intGrid field is deprecated — parse intGridCsv instead. Implement parseLayerInstance(node: JsonNode): LayerInstance. Import ldtky/enums, ldtky/instances/entity, ldtky/instances/layer_utils, ldtky/primitives, ldtky/json_helpers, ldtky/errors, std/options." \
  -p 1 -l impl -t feature --silent)
bd dep add $INST_LAYER $INST_ENTITY
bd dep add $INST_LAYER $INST_LAYER_UTILS
bd dep add $INST_LAYER $CORE_ENUMS

INST_LEVEL=$(bd create "Implement Level, NeighbourLevel, LevelBgPosInfos types and parsing" \
  -d "Create src/ldtky/instances/level.nim. Types: NeighbourLevel* = object (dir*, levelIid*: string, levelUid*: Option[int]), LevelBgPosInfos* = object (cropRect*, scale*, topLeftPx*: seq[float]), Level* = ref object (identifier*, iid*: string, uid*, pxHei*, pxWid*, worldDepth*, worldX*, worldY*: int, bgColor*: Option[string], bgPivotX*, bgPivotY*: float, smartColor*, computedBgColor*: string, neighbours*: seq[NeighbourLevel], layerInstances*: Option[seq[LayerInstance]], externalRelPath*: Option[string], bgRelPath*: Option[string], bgPos*: Option[LevelBgPosInfos], fieldInstances*: seq[FieldInstance], useAutoIdentifier*: bool). Level uses ref object (large nested type). Fields __bgColor, __neighbours, __smartColor, __bgPos use __-prefix (manual access). Implement parsers. Import ldtky/instances/layer, ldtky/instances/field, ldtky/json_helpers, ldtky/errors, std/options." \
  -p 1 -l impl -t feature --silent)
bd dep add $INST_LEVEL $INST_LAYER
bd dep add $INST_LEVEL $INST_FIELD

INST_WORLD=$(bd create "Implement World type and parsing" \
  -d "Create src/ldtky/instances/world.nim. Type: World* = object (identifier*, iid*: string, worldGridHeight*, worldGridWidth*, defaultLevelHeight*, defaultLevelWidth*: int, worldLayout*: WorldLayout, levels*: seq[Level]). Implement parseWorld(node: JsonNode): World. WorldLayout field: parse string value via enums.nim. Import ldtky/enums, ldtky/instances/level, ldtky/json_helpers, ldtky/errors." \
  -p 1 -l impl -t feature --silent)
bd dep add $INST_WORLD $INST_LEVEL
bd dep add $INST_WORLD $CORE_ENUMS

INST_TOC=$(bd create "Implement TableOfContentEntry, TocInstanceData, CustomCommand types" \
  -d "Create src/ldtky/instances/toc.nim. Types: TocInstanceData* = object (worldX*, worldY*, heiPx*, widPx*: int, iids*: EntityReferenceInfos, fields*: JsonNode), TableOfContentEntry* = object (identifier*: string, instancesData*: seq[TocInstanceData]), CustomCommand* = object (command*: string, when*: CustomCommandWhen). Implement parsers. CustomCommandWhen enum from enums.nim. EntityReferenceInfos defined in field_value.nim. Import ldtky/field_value, ldtky/json_helpers, ldtky/errors, ldtky/enums, std/json." \
  -p 2 -l impl -t feature --silent)
bd dep add $INST_TOC $CORE_FIELD_VALUE
bd dep add $INST_TOC $CORE_JSON_HELPERS
bd dep add $INST_TOC $CORE_ENUMS

# ──────────────────────────────────────────────────────────────────────────────
# Phase 5: Root, External Levels & Public API
# ──────────────────────────────────────────────────────────────────────────────
echo "Phase 5: Root & API..."

ROOT_PROJECT=$(bd create "Implement LdtkJsonRoot type and project parser" \
  -d "Create src/ldtky/project.nim. Type: LdtkJsonRoot* = object with all top-level fields per docs/arch/schema-notes.md section 2. Key: jsonVersion*: string, iid*: string, levels*: seq[Level], worlds*: seq[World], defs*: Definitions, toc*: seq[TableOfContentEntry], customCommands*: seq[CustomCommand], externalLevels*: bool, bgColor*: string, flags*: seq[string], and all remaining required + optional fields. Implement parseProject(node: JsonNode): LdtkJsonRoot. On jsonVersion mismatch from 1.5.3, emit warning via stderr, continue. Handle both single-world (worlds empty, levels at root) and multi-world (worlds non-empty) in the same type — no special branching needed at parse time. Import all instances/ and defs submodules." \
  -p 0 -l impl -t feature --silent)
bd dep add $ROOT_PROJECT $INST_LEVEL
bd dep add $ROOT_PROJECT $INST_WORLD
bd dep add $ROOT_PROJECT $DEFS_CONTAINER
bd dep add $ROOT_PROJECT $INST_TOC

EXTERNAL_LEVELS=$(bd create "Implement external .ldtkl level file loading" \
  -d "Create src/ldtky/loader.nim. When LdtkJsonRoot.externalLevels is true, each Level.layerInstances is null and Level.externalRelPath is set. Implement proc loadExternalLevels*(project: var LdtkJsonRoot, projectDir: string) that iterates project.levels (and worlds[].levels), reads each externalRelPath relative to projectDir, parses the .ldtkl JSON (same Level JSON but wrapped), and injects the layerInstances into the Level ref. Also implement proc loadProject*(path: string): LdtkJsonRoot — reads file, parses JSON, calls parseProject, then calls loadExternalLevels. Import std/json, std/os, ldtky/project, ldtky/instances/level, ldtky/errors." \
  -p 0 -l impl -t feature --silent)
bd dep add $EXTERNAL_LEVELS $ROOT_PROJECT

API_MAIN=$(bd create "Write ldtky.nim public API module with re-exports" \
  -d "Create src/ldtky/ldtky.nim (the main entry point). Re-export all submodules following observy pattern: import ldtky/errors; export errors, etc. for all modules: errors, enums, primitives, field_value, json_helpers, defs (aggregator), instances/layer_utils, instances/field, instances/entity, instances/layer, instances/level, instances/world, instances/toc, project, loader. The convenience API is loadProject(path) from loader.nim — already public. Add brief doc comments on the module describing the library. Check /Users/punk1290/git/observy/src/observy/observy.nim for re-export style." \
  -p 0 -l impl -t feature --silent)
bd dep add $API_MAIN $EXTERNAL_LEVELS
bd dep add $API_MAIN $INST_WORLD
bd dep add $API_MAIN $DEFS_CONTAINER

# ──────────────────────────────────────────────────────────────────────────────
# Phase 6: Tests
# ──────────────────────────────────────────────────────────────────────────────
echo "Phase 6: Tests..."

TEST_FIXTURES=$(bd create "Vendor LDtk test fixtures into tests/fixtures/" \
  -d "Copy LDtk test fixture files (MIT licensed, from ~/git/ldtk/tests/) into tests/fixtures/. Copy: _empty.ldtk, grassAndDirt.ldtk, lotsOfEntities.ldtk, multiWorldsTest.ldtk, manyRules.ldtk, largeGridVania.ldtk, labRefs.ldtk, lab1.ldtk, lab2.ldtk, levelBgs.ldtk, parallax1.ldtk. Create tests/fixtures/ATTRIBUTION.md with: Source: https://github.com/deepnight/ldtk — MIT License, Copyright (c) 2020 Sebastien Benard." \
  -p 0 -l testing -t task --silent)
bd dep add $TEST_FIXTURES $SETUP_DIRS

TEST_PRIMITIVES=$(bd create "Write unit tests for primitives, enums, and layer utils" \
  -d "Create tests/test_primitives.nim. Use unittest module with suites. Test: (1) GridPoint construction and field access. (2) TilesetRect construction. (3) Tile flip-bit decoding: flipX(0)=false, flipX(1)=true, flipY(2)=true, flipY(3)=true, flipY(1)=false. (4) decodeIntGridCsv: given [1,2,3,4] with cWid=2, result[0][0]=1, result[0][1]=2, result[1][0]=3, result[1][1]=4. (5) All LayerKind enum values can be compared. Follow observy test style in /Users/punk1290/git/observy/tests/." \
  -p 1 -l testing -t task --silent)
bd dep add $TEST_PRIMITIVES $INST_LAYER_UTILS
bd dep add $TEST_PRIMITIVES $SETUP_NIMBLE

TEST_FIELD_VALUE=$(bd create "Write unit tests for FieldValue object variant" \
  -d "Create tests/test_field_value.nim. Use unittest module. Test all 18 FieldKind variants: (1) Scalar construction for fkInt, fkFloat, fkBool, fkString, fkColor, fkPoint, fkTile, fkEntityRef, fkEnum. (2) Array variants: fkIntArray, fkFloatArray, fkBoolArray, fkStringArray, fkColorArray, fkPointArray, fkTileArray, fkEntityRefArray, fkEnumArray. (3) parseFieldValue with crafted JsonNode inputs for each __type string. (4) Null __value yields none(FieldValue) in parseFieldInstance. Verify kind discrimination works correctly." \
  -p 1 -l testing -t task --silent)
bd dep add $TEST_FIELD_VALUE $CORE_FIELD_VALUE
bd dep add $TEST_FIELD_VALUE $SETUP_NIMBLE

TEST_JSON_HELPERS=$(bd create "Write unit tests for json_helpers utilities" \
  -d "Create tests/test_json_helpers.nim. Use unittest module. Test: (1) getField[string] on a JsonNode with a regular key returns the value. (2) getField[int] on a __-prefixed key works correctly. (3) getField on missing required key raises LdtkParseError. (4) getOpt[string] on present key returns some(value). (5) getOpt[int] on missing key returns none(int). (6) getOpt[string] on JNull value returns none(string)." \
  -p 1 -l testing -t task --silent)
bd dep add $TEST_JSON_HELPERS $CORE_JSON_HELPERS
bd dep add $TEST_JSON_HELPERS $SETUP_NIMBLE

TEST_DEFS=$(bd create "Write unit tests for Definitions parsing" \
  -d "Create tests/test_defs.nim. Use unittest module. Parse hand-crafted JsonNode literals for each def type. Test: (1) parseEnumDef round-trips identifier, values, tags. (2) parseTilesetDef handles __cHei/__cWid correctly. (3) parseIntGridValueDef handles optional identifier. (4) parseEntityDef parses renderMode and tileRenderMode enums correctly. (5) parseLayerDef handles __type to LayerKind mapping for all 4 kinds. (6) parseDefinitions combines all sub-parsers. Missing required field raises LdtkParseError." \
  -p 1 -l testing -t task --silent)
bd dep add $TEST_DEFS $DEFS_CONTAINER
bd dep add $TEST_DEFS $SETUP_NIMBLE

TEST_INSTANCES=$(bd create "Write unit tests for FieldInstance, EntityInstance, LayerInstance parsing" \
  -d "Create tests/test_instances.nim. Use unittest module. Test: (1) parseFieldInstance with __identifier, __type, __value for each scalar field kind. (2) parseFieldInstance where __value is null yields none(FieldValue). (3) parseEntityInstance handles __grid, __pivot arrays and optional __worldX/__worldY. (4) parseLayerInstance with a Tiles layer: gridTiles populated, intGridCsv empty. (5) parseLayerInstance with IntGrid layer: intGridCsv populated, gridTiles empty. (6) parseLayerInstance with Entities layer: entityInstances populated. All tests use crafted JsonNode, not file fixtures." \
  -p 1 -l testing -t task --silent)
bd dep add $TEST_INSTANCES $INST_LAYER
bd dep add $TEST_INSTANCES $SETUP_NIMBLE

TEST_LEVEL_WORLD=$(bd create "Write unit tests for Level and World parsing" \
  -d "Create tests/test_level_world.nim. Use unittest module. Test: (1) parseLevel with __bgColor, __neighbours, __smartColor — all __-prefixed. (2) NeighbourLevel with optional levelUid. (3) parseWorld with worldLayout string to enum. (4) Level with null layerInstances (external levels case) returns none. (5) Deprecated top-level nullable fields (worldGridWidth etc.) return none when null. Use crafted JsonNode." \
  -p 1 -l testing -t task --silent)
bd dep add $TEST_LEVEL_WORLD $INST_WORLD
bd dep add $TEST_LEVEL_WORLD $SETUP_NIMBLE

TEST_INTEGRATION=$(bd create "Write integration tests loading full .ldtk fixture files" \
  -d "Create tests/test_integration.nim. Use unittest module. Load real .ldtk files from tests/fixtures/ via loadProject(). Test: (1) _empty.ldtk loads without error. (2) grassAndDirt.ldtk: project has levels, at least one layer instance of kind Tiles. (3) lotsOfEntities.ldtk: entity instances present, field instances parseable. (4) multiWorldsTest.ldtk: worlds seq is non-empty. (5) lab1.ldtk or lab2.ldtk: externalLevels=true, after loadProject layerInstances are populated (not none). (6) manyRules.ldtk: autoLayerTiles present in at least one layer. (7) jsonVersion mismatch test: manually craft a root JSON with wrong version, confirm warning emitted but no exception." \
  -p 0 -l testing -t task --silent)
bd dep add $TEST_INTEGRATION $API_MAIN
bd dep add $TEST_INTEGRATION $TEST_FIXTURES

# ──────────────────────────────────────────────────────────────────────────────
# Phase 7: Examples
# ──────────────────────────────────────────────────────────────────────────────
echo "Phase 7: Examples..."

EXAMPLE_BASIC=$(bd create "Write basic.nim example: load project, iterate levels and layers" \
  -d "Create examples/basic.nim. Show: import ldtky, load a project file with loadProject(path from argv), print project jsonVersion and level count, iterate levels and print each level identifier and its layer count and layer types. Include compile command in header comment: nim c --mm:orc -r examples/basic.nim path/to/file.ldtk. Show both single-world and multi-world path by checking worlds.len. Model after /Users/punk1290/git/observy/examples/traces.nim style." \
  -p 2 -l impl -t task --silent)
bd dep add $EXAMPLE_BASIC $API_MAIN
bd dep add $EXAMPLE_BASIC $SETUP_CONFIG

EXAMPLE_ENTITIES=$(bd create "Write entities.nim example: entity instances and field values" \
  -d "Create examples/entities.nim. Show: load a project, iterate all levels and entity layers, print entity instance identifier/position/tags, iterate fieldInstances and print identifier and value (switch on kind for FieldValue). Demonstrate FieldValue variant dispatch. Include compile command header. Use lotsOfEntities.ldtk or similar as the suggested input." \
  -p 2 -l impl -t task --silent)
bd dep add $EXAMPLE_ENTITIES $API_MAIN
bd dep add $EXAMPLE_ENTITIES $SETUP_CONFIG

EXAMPLE_TILESET=$(bd create "Write tileset.nim example: tileset metadata and tile access" \
  -d "Create examples/tileset.nim. Show: load a project, print all TilesetDef entries (identifier, uid, gridSize, padding, spacing, relPath), for each Tiles layer print its tilesetRelPath and first 5 gridTile entries (px, src, flip bits). Demonstrate flipX/flipY helpers. Include compile command header." \
  -p 2 -l impl -t task --silent)
bd dep add $EXAMPLE_TILESET $API_MAIN
bd dep add $EXAMPLE_TILESET $SETUP_CONFIG

# ──────────────────────────────────────────────────────────────────────────────
# Phase 8: Documentation & CI
# ──────────────────────────────────────────────────────────────────────────────
echo "Phase 8: Documentation & CI..."

DOCS_API=$(bd create "Add doc comments to all public types and procs" \
  -d "Add Nim doc comments (## style) to public-facing types and procs across all src/ldtky/ modules. Priority: LdtkJsonRoot, LayerInstance, EntityInstance, FieldValue (document all 18 FieldKind variants), loadProject, FieldInstance, Definitions. Comments should describe the LDtk schema field being represented, not restate the type. For FieldValue, document which __type string maps to which FieldKind. Do NOT add comments to private/internal helpers." \
  -p 2 -l docs -t task --silent)
bd dep add $DOCS_API $API_MAIN

DOCS_README=$(bd create "Write README.md for ldtky library" \
  -d "Rewrite (or fill in) README.md at repo root. Include: (1) Short description: Nim library for loading LDtk level designer project files. Pure Nim, no external deps, supports LDtk v1.5.3. (2) Installation: nimble install ldtky or git clone + nimble develop. Requires nim >= 2.0.0, compile with --mm:orc. (3) Quick start code block: import ldtky, var project = loadProject(path), iterate levels. (4) API overview: key types (LdtkJsonRoot, Level, LayerInstance, EntityInstance, FieldValue), key procs (loadProject, flipX, flipY, decodeIntGridCsv). (5) Layer kinds table. (6) FieldValue variants table. (7) License." \
  -p 2 -l docs -t task --silent)
bd dep add $DOCS_README $API_MAIN

CI_WORKFLOW=$(bd create "Write GitHub Actions CI workflow for nim test" \
  -d "Create .github/workflows/test.yml. Workflow triggers on push and pull_request to main. Jobs: test (runs on ubuntu-latest and macos-latest). Steps: checkout, install Nim via setup-nim-action (jiro4989/setup-nim-action@v2 or similar), run nimble test. Compiler flags already in config.nims so no extra flags needed. Also add a check job that runs nimble check. Set Nim version to stable (>= 2.0)." \
  -p 2 -l docs -t chore --silent)
bd dep add $CI_WORKFLOW $SETUP_NIMBLE

# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "Task graph created successfully!"
echo ""
echo "Next steps:"
echo "  bd ready              # Show unblocked tasks to start on"
echo "  bd graph              # Visualize dependency graph"
echo "  bd list               # List all tasks"
