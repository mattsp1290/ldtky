import unittest
import std/json
import std/options
import ldtky/instances/level
import ldtky/instances/world
import ldtky/project
import ldtky/enums
import std/os
import ldtky/errors

suite "parseLevel":
  test "parses required fields":
    let n = %* {
      "identifier": "Level_0",
      "iid": "level-iid-1",
      "uid": 1,
      "pxHei": 256,
      "pxWid": 512,
      "worldDepth": 0,
      "worldX": 0,
      "worldY": 0,
      "bgPivotX": 0.5,
      "bgPivotY": 0.5,
      "__smartColor": "#FF0000",
      "__neighbours": [],
      "layerInstances": [],
      "fieldInstances": []
    }
    let lv = parseLevel(n)
    check lv.identifier == "Level_0"
    check lv.iid == "level-iid-1"
    check lv.uid == 1
    check lv.pxHei == 256
    check lv.pxWid == 512
    check lv.smartColor == "#FF0000"
    check lv.layerInstances.isSome
    check lv.layerInstances.get.len == 0
    check lv.bgColor.isNone
    check lv.computedBgColor.isNone

  test "null layerInstances (external levels) yields none":
    let n = %* {
      "identifier": "L", "iid": "x", "uid": 1,
      "pxHei": 128, "pxWid": 128, "worldDepth": 0, "worldX": 0, "worldY": 0,
      "bgPivotX": 0.0, "bgPivotY": 0.0,
      "__smartColor": "#000000",
      "layerInstances": nil,
      "__neighbours": [], "fieldInstances": []
    }
    let lv = parseLevel(n)
    check lv.layerInstances.isNone

  test "missing required field raises LdtkParseError":
    let n = %* {"identifier": "L", "iid": "x", "uid": 1}
    expect(LdtkParseError):
      discard parseLevel(n)

suite "parseWorld":
  test "parses multi-world fixture data":
    let data = parseFile("tests/fixtures/multiWorldsTest.ldtk")
    let worlds = data["worlds"]
    check worlds.len == 3
    let w = parseWorld(worlds[0])
    check w.identifier.len > 0
    check w.worldLayout.isSome

  test "parses single-world project (worlds array empty)":
    let data = parseFile("tests/fixtures/grassAndDirt.ldtk")
    check data["worlds"].len == 0
    check data["levels"].len > 0

suite "parseProject":
  test "parses all 11 real fixtures without raising":
    var count = 0
    for fname in walkFiles("tests/fixtures/*.ldtk"):
      let data = parseFile(fname)
      let proj = parseProject(data)
      check proj.jsonVersion.len > 0
      count += 1
    check count == 11

  test "single-world: levels at root, worlds empty":
    let data = parseFile("tests/fixtures/grassAndDirt.ldtk")
    let proj = parseProject(data)
    check proj.worlds.len == 0
    check proj.levels.len > 0

  test "multi-world: worlds non-empty, levels at root empty":
    let data = parseFile("tests/fixtures/multiWorldsTest.ldtk")
    let proj = parseProject(data)
    check proj.worlds.len == 3
    check proj.levels.len == 0
