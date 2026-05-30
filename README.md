# ldtky

Pure-Nim library for loading and parsing [LDtk](https://ldtk.io/) (Level Designer Toolkit) project files. Targets LDtk JSON format v1.5.3; older files (v1.0.0+) load with graceful defaults.

## Features

- Parse `.ldtk` project files into typed Nim objects
- Automatic external level (`.ldtkl`) loading
- Supports single-world and multi-world project layouts
- Zero external Nim dependencies
- Requires `--mm:orc` (enforced via `nim.cfg`)

## Installation

```bash
nimble install https://github.com/mattsp1290/ldtky
```

Or add to your `.nimble` file:

```nim
requires "ldtky >= 0.1.0"
```

## Quick Start

```nim
import ldtky/ldtky

let project = loadProject("my_game/world.ldtk")

echo "Loaded ", project.levels.len, " levels"

for level in project.levels:
  echo "Level: ", level.identifier, " (", level.pxWid, "x", level.pxHei, "px)"
  if level.layerInstances.isSome:
    for layer in level.layerInstances.get:
      echo "  Layer: ", layer.identifier, " (", layer.layerType, ")"
```

## Multi-World Projects

```nim
let project = loadProject("world.ldtk")
if project.worlds.len > 0:
  # Multi-world layout
  for world in project.worlds:
    echo "World: ", world.identifier
    for level in world.levels:
      echo "  Level: ", level.identifier
else:
  # Single-world layout (levels at root)
  for level in project.levels:
    echo "Level: ", level.identifier
```

## Entity Instances

```nim
for level in project.levels:
  if level.layerInstances.isNone: continue
  for layer in level.layerInstances.get:
    for entity in layer.entityInstances:
      echo "Entity: ", entity.identifier, " at ", entity.px
      for fi in entity.fieldInstances:
        if fi.value.isSome:
          let v = fi.value.get
          echo "  Field ", fi.identifier, " (", fi.fieldType, "): kind=", v.kind
```

## API Overview

### Loading

| Proc | Description |
|------|-------------|
| `loadProject(path)` | Load a `.ldtk` file (auto-loads external levels) |
| `loadExternalLevels(project, dir)` | Manually inject `.ldtkl` sidecar data |
| `parseProject(node)` | Parse a `JsonNode` into `LdtkJsonRoot` |

### Key Types

| Type | Description |
|------|-------------|
| `LdtkJsonRoot` | Top-level project (defs, levels, worlds) |
| `Definitions` | All entity/layer/tileset/enum definitions |
| `Level` | A single level (ref object) |
| `LayerInstance` | Layer data (tiles, entities, intgrid) |
| `EntityInstance` | A placed entity with field instances |
| `FieldValue` | A typed field value (18 discriminated variants) |
| `TilesetDef` | Tileset metadata (no image loading) |

## Compatibility

- Nim >= 2.0.0 with `--mm:orc`
- LDtk JSON format v1.0.0 to v1.5.3
- Files with `externalLevels: true` require `.ldtkl` sibling files

## License

MIT — see [LICENSE](LICENSE)
