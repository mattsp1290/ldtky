# Project Planning with Beads

## Agent Instructions

You are an expert software architect creating a comprehensive task breakdown. This task graph will be executed by AI agents working in parallel, coordinated through MCP Agent Mail with file reservations to prevent conflicts.

<quality_expectations>
Create a thorough, production-ready task graph. Include all necessary setup, implementation, testing, and documentation tasks. Go beyond the basics - consider edge cases, error handling, security considerations, and integration points. Each task should be specific enough for an agent to execute independently without ambiguity.
</quality_expectations>

## Project Information

### Links to Relevant Documentation
- https://ldtk.io/json — Interactive JSON format reference (v1.5.3)
- https://ldtk.io/docs/game-dev/json/ — Game-dev integration overview
- https://github.com/deepnight/ldtk/blob/master/docs/JSON_DOC.md — Full JSON format docs (Markdown)
- https://github.com/deepnight/ldtk/blob/master/docs/JSON_SCHEMA.json — Machine-readable JSON Schema
- https://github.com/deepnight/ldtk/blob/master/docs/MINIMAL_JSON_SCHEMA.json — Minimal JSON Schema for importers
- ~/git/ldtk/docs/JSON_SCHEMA.json — Local copy of JSON Schema
- ~/git/ldtk/docs/MINIMAL_JSON_SCHEMA.json — Local copy of minimal schema
- https://github.com/AnomalousUnderdog/ldtkimport — C++ reference importer
- https://github.com/IrishBruse/LDtkMonogame — C# / MonoGame reference importer
- https://github.com/SolarLune/ldtkgo — Go importer (closest structural analog to Nim)
- https://github.com/desttinghim/zig-ldtk — Zig single-file parser (most analogous to Nim)
- https://nim-lang.org/docs/json.html — Nim std/json module
- ~/git/doggy — Reference Nim library (follow its conventions for nimble, src layout, tests, examples)
- ~/git/observy — Reference Nim library (follow its conventions)

### Project Description
A Nim library for loading and parsing LDtk (Level Designer Toolkit) `.ldtk` project files — modeled after `ldtkimport` and `LDtkMonogame`, following the same library conventions as `doggy` and `observy` in this workspace. The library parses the LDtk JSON format into idiomatic Nim types and provides a clean public API for game developers to load worlds, levels, layers (Tile, IntGrid, Entity, Auto-layer), tilesets, and entity instances.

### Technical Stack
- Nim (>= 2.0.0)
- Pure Nim libraries only — no external C/native dependencies
- std/json for JSON parsing
- std/os for file I/O
- Nimble for packaging

### Specific Requirements
- **Scope**: Pure loader only — parse pre-computed LDtk JSON output (including `autoLayerTiles`). Auto-layer rule evaluation is explicitly out of scope.
- **Schema version**: Target LDtk JSON format v1.5.3. Emit a warning (not a hard error) for mismatched `jsonVersion`; ignore unknown fields gracefully.
- **Tileset support**: Metadata only (uid, relPath, gridSize, tags). No image/pixel loading — the pure-Nim constraint rules out PNG decoding.
- **Nullable fields**: Use `Option[T]` for all nullable schema fields (following the `--mm:orc` house convention). Never use sentinel/zero-value defaults for nullable types.
- **Memory model**: Compile with `--mm:orc`. Public types are value objects where practical; use `ref object` only for large nested types (Level, LayerInstance) to avoid deep copying.
- **Error handling**: Raise a custom `LdtkParseError` exception on malformed/missing required fields. Optional/nullable fields use `Option[T]`.
- **FieldInstance value type**: Represent `__value` as a Nim `object variant` (`FieldValue` with `case kind: FieldKind`) covering `Int`, `Float`, `Bool`, `String`, `Color` (hex string), `Point` (GridPoint), `Tile` (TilesetRect), `EntityRef`, `Enum` (string), and `Array` variants of each. This is a single named design task, not scattered across per-type tasks.

---

## Your Task

Analyze this project and create a comprehensive **Beads task graph** using the `bd` CLI. Beads provides dependency-aware, conflict-free task management for multi-agent execution.

---

<critical_constraint>
Your ONLY output is a bash shell script. Do NOT use `bd add` — the correct command to create a bead is `bd create`. Use `bd dep add` for dependencies. Do not implement anything yourself.
</critical_constraint>

## Output Format

Generate a shell script that creates the full task graph. The script should:

1. **Initialize Beads** (if not already initialized)
2. **Create all beads** with appropriate priorities
3. **Establish dependencies** between beads
4. **Add labels** for phase grouping

### Example Output

```bash
#!/bin/bash
# Project: ldtky
# Generated: 2026-05-29

set -e

# Initialize beads if needed
if [ ! -d ".beads" ]; then
    bd init
fi

echo "Creating project beads..."

# ========================================
# Phase 1: Project Setup & Infrastructure
# ========================================

SETUP_VITE=$(bd create "Initialize project with Vite + React + TypeScript" -p 0 --label setup --silent)

SETUP_LINT=$(bd create "Configure ESLint, Prettier, and TypeScript strict mode" -p 1 --label setup --silent)
bd dep add $SETUP_LINT $SETUP_VITE

SETUP_TAILWIND=$(bd create "Set up Tailwind CSS with design system tokens" -p 1 --label setup --silent)
bd dep add $SETUP_TAILWIND $SETUP_VITE

SETUP_TESTING=$(bd create "Configure testing framework (Vitest + Testing Library)" -p 1 --label setup --silent)
bd dep add $SETUP_TESTING $SETUP_LINT

# ========================================
# Phase 2: Core Architecture
# ========================================

API_CLIENT=$(bd create "Implement API client with error handling and retries" -p 0 --label core --silent)
bd dep add $API_CLIENT $SETUP_VITE

STATE_MGMT=$(bd create "Set up global state management (Zustand/Jotai)" -p 0 --label core --silent)
bd dep add $STATE_MGMT $SETUP_VITE

AUTH_CONTEXT=$(bd create "Create authentication context and hooks" -p 0 --label core --silent)
bd dep add $AUTH_CONTEXT $STATE_MGMT
bd dep add $AUTH_CONTEXT $API_CLIENT

# ... continue for all phases ...

echo ""
echo "Bead graph created! View with:"
echo "  bd ready              # List unblocked tasks"
```

---

## Bead Creation Guidelines

### Priority Levels
- `-p 0` = Critical (blocking other work)
- `-p 1` = High (important but not blocking)
- `-p 2` = Medium (standard work)
- `-p 3` = Low (nice to have)

### Labels (Phase Grouping)
Use `--label` to group beads by phase:
- `setup` - Project initialization
- `core` - Core architecture
- `auth` - Authentication/authorization
- `ui` - UI components
- `feature-{name}` - Feature-specific work
- `testing` - Test coverage
- `docs` - Documentation
- `deploy` - Deployment/CI

### Dependency Rules
1. Never create cycles
2. Every bead should have a clear dependency chain back to setup tasks
3. Use `bd dep add CHILD PARENT` (child depends on parent completing first)
4. Parallel work should share a common ancestor, not depend on each other

### Task Granularity
- Each bead should be completable in **under 750 lines of code**
- Tasks should be atomic enough for one agent to complete without coordination
- If a task requires multiple file areas, consider splitting by file area

---

## File Reservation Planning

For each major work area, note the file patterns that will need exclusive reservation:

```bash
# Example reservation notes (add as bead descriptions)
# Core types: src/ldtky/types.nim
# JSON parsing: src/ldtky/parser.nim, src/ldtky/json_helpers.nim
# Layer loaders: src/ldtky/layers/*.nim
# Public API: src/ldtky.nim
# Tests: tests/test_*.nim
# Examples: examples/*.nim
```

This helps agents claim appropriate file surfaces when they start work.

---

## Context Documentation

Place any important context in `docs/` for agents to reference. This includes:
- Architecture decisions
- LDtk JSON schema notes
- Design conventions from doggy/observy

---

## Verification Steps

After generating the script:

1. **Run it**: `chmod +x setup-beads.sh && ./setup-beads.sh`
2. **Check ready work**: `bd ready` should show initial setup tasks

---

## Completeness Checklist

Ensure your task graph includes:

- [ ] All setup and configuration tasks (nimble file, config.nims, directory structure)
- [ ] Core type definitions for all LDtk JSON types (World, Level, Layer, Entity, Tileset, etc.)
- [ ] JSON parsing / deserialization for each type
- [ ] Support for all layer kinds: Tile, IntGrid, Entity, Auto-layer
- [ ] External level file support (`.ldtkl` files, `externalRelPath`)
- [ ] Multi-world support
- [ ] Public API surface (ldtky.nim re-exports)
- [ ] Type definitions and parsing for the full `defs` block: `LayerDef`, `EntityDef`, `EnumDef`/`EnumDefValues`, `TilesetDef`, `IntGridValueDef`, `IntGridValueGroupDef`, `TileCustomMetadata`, `EnumTagValue`
- [ ] Hand-written JSON field mapping for all `__`-prefixed keys (e.g. `__type`, `__identifier`, `__cWid`, `__grid`) — `std/json`'s `to()` macro cannot handle these; use manual `JsonNode` field access
- [ ] Error handling for malformed / missing fields
- [ ] Unit tests for each type and parser
- [ ] Integration test fixtures vendored from `~/git/ldtk/tests/*.ldtk` (MIT-licensed, include attribution); covers multi-world, external levels, auto-layers, old schema versions
- [ ] `IntGrid` CSV decoding: map flat `intGridCsv` array to 2D grid using `__cWid`/`__cHei`
- [ ] Tile flip-bit decoding: parse `Tile.f` as 2-bit field (bit 0 = X flip, bit 1 = Y flip)
- [ ] Both world layouts: single-world (levels at project root) and multi-world (`worlds[]` array); handle deprecated nullable top-level fields (`worldGridWidth`, `worldLayout`, etc.)
- [ ] Example programs showing library usage
- [ ] README and API documentation
- [ ] CI task (nimble test)
- [ ] Clear dependency chains with no cycles
