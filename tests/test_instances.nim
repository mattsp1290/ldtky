import unittest
import std/json
import std/options
import ldtky/instances/field
import ldtky/instances/entity
import ldtky/instances/layer
import ldtky/field_value
import ldtky/errors

suite "parseFieldInstance":
  test "parses string field":
    let n = %* {
      "__identifier": "myStr",
      "__type": "String",
      "__value": "hello",
      "defUid": 1
    }
    let fi = parseFieldInstance(n)
    check fi.identifier == "myStr"
    check fi.fieldType == "String"
    check fi.defUid == 1
    check fi.value.isSome
    check fi.value.get.kind == fkString
    check fi.value.get.strVal == "hello"

  test "null __value yields none":
    let n = %* {
      "__identifier": "opt",
      "__type": "Int",
      "__value": nil,
      "defUid": 2
    }
    let fi = parseFieldInstance(n)
    check fi.value.isNone

  test "missing __identifier raises LdtkParseError":
    let n = %* {"__type": "Int", "__value": 1, "defUid": 1}
    expect(LdtkParseError):
      discard parseFieldInstance(n)

suite "parseEntityInstance":
  test "parses minimal entity instance":
    let n = %* {
      "__identifier": "Player",
      "iid": "abc-123",
      "defUid": 5,
      "height": 16,
      "width": 16,
      "__smartColor": "#FF0000",
      "__grid": [3, 4],
      "__pivot": [0.5, 1.0],
      "px": [48, 64],
      "__tags": [],
      "fieldInstances": []
    }
    let ei = parseEntityInstance(n)
    check ei.identifier == "Player"
    check ei.iid == "abc-123"
    check ei.defUid == 5
    check ei.height == 16
    check ei.width == 16
    check ei.smartColor == "#FF0000"
    check ei.grid == @[3, 4]
    check ei.pivot == @[0.5, 1.0]
    check ei.px == @[48, 64]
    check ei.tags.len == 0
    check ei.tile.isNone
    check ei.worldX.isNone
    check ei.worldY.isNone

  test "optional worldX/worldY parsed when present":
    let n = %* {
      "__identifier": "E",
      "iid": "x",
      "defUid": 1,
      "height": 8,
      "width": 8,
      "__smartColor": "#000000",
      "__grid": [0, 0],
      "__pivot": [0.0, 0.0],
      "px": [0, 0],
      "__tags": [],
      "fieldInstances": [],
      "__worldX": 100,
      "__worldY": 200
    }
    let ei = parseEntityInstance(n)
    check ei.worldX == some(100)
    check ei.worldY == some(200)

  test "missing required array raises LdtkParseError":
    let n = %* {
      "__identifier": "E",
      "iid": "x",
      "defUid": 1,
      "height": 8,
      "width": 8,
      "__smartColor": "#000000"
    }
    expect(LdtkParseError):
      discard parseEntityInstance(n)

suite "parseLayerInstance":
  test "parses a minimal IntGrid layer":
    let n = %* {
      "__identifier": "Ground",
      "iid": "layer-1",
      "__type": "IntGrid",
      "__cHei": 4,
      "__cWid": 4,
      "__gridSize": 16,
      "__opacity": 1.0,
      "__pxTotalOffsetX": 0,
      "__pxTotalOffsetY": 0,
      "layerDefUid": 10,
      "levelId": 0,
      "pxOffsetX": 0,
      "pxOffsetY": 0,
      "seed": 42,
      "visible": true,
      "intGridCsv": [1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0],
      "optionalRules": [],
      "autoLayerTiles": [],
      "gridTiles": [],
      "entityInstances": []
    }
    let li = parseLayerInstance(n)
    check li.identifier == "Ground"
    check li.layerType == "IntGrid"
    check li.cHei == 4
    check li.cWid == 4
    check li.gridSize == 16
    check li.seed == 42
    check li.visible == true
    check li.intGridCsv.len == 16
    check li.intGridCsv[0] == 1
    check li.tilesetRelPath.isNone
    check li.overrideTilesetUid.isNone
