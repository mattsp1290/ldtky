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
