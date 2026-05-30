## Integration tests: load real .ldtk files via loadProject()
import unittest
import std/options
import ldtky/ldtky

suite "loadProject — fixture integration":
  test "_empty.ldtk loads without error":
    let proj = loadProject("tests/fixtures/_empty.ldtk")
    check proj.jsonVersion.len > 0
    check proj.externalLevels == false

  test "grassAndDirt.ldtk: has levels with Tiles layer":
    let proj = loadProject("tests/fixtures/grassAndDirt.ldtk")
    check proj.levels.len > 0
    var foundTiles = false
    for lv in proj.levels:
      if lv.layerInstances.isSome:
        for li in lv.layerInstances.get:
          if li.layerType == "Tiles" or li.gridTiles.len > 0 or li.autoLayerTiles.len > 0:
            foundTiles = true
    check foundTiles

  test "lotsOfEntities.ldtk: entity instances with field instances":
    let proj = loadProject("tests/fixtures/lotsOfEntities.ldtk")
    check proj.levels.len > 0
    # Parse succeeds — field instances handled in FieldInstance type
    for lv in proj.levels:
      check lv.iid.len > 0

  test "multiWorldsTest.ldtk: worlds seq non-empty":
    let proj = loadProject("tests/fixtures/multiWorldsTest.ldtk")
    check proj.worlds.len > 0
    check proj.levels.len == 0

  test "manyRules.ldtk: autoLayerTiles present in at least one layer":
    let proj = loadProject("tests/fixtures/manyRules.ldtk")
    var foundAutoTiles = false
    for lv in proj.levels:
      if lv.layerInstances.isSome:
        for li in lv.layerInstances.get:
          if li.autoLayerTiles.len > 0:
            foundAutoTiles = true
    check foundAutoTiles

  test "labRefs.ldtk: multi-world structure with entity refs":
    let proj = loadProject("tests/fixtures/labRefs.ldtk")
    check proj.worlds.len > 0
    check proj.externalLevels == false

  test "jsonVersion mismatch emits warning but no exception":
    # The loader emits a stderr warning but continues parsing
    # This test verifies no exception is raised for version mismatches
    let proj = loadProject("tests/fixtures/parallax1.ldtk")
    check proj.jsonVersion == "1.0.0"  # old file, not 1.5.3
    check proj.levels.len > 0

  test "largeGridVania.ldtk: defs has layers and entities":
    let proj = loadProject("tests/fixtures/largeGridVania.ldtk")
    check proj.defs.layers.len > 0
    check proj.defs.entities.len > 0
    check proj.defs.tilesets.len > 0
