import unittest
import std/json
import std/options
import ldtky/defs/defs
import ldtky/defs/enums
import ldtky/defs/tileset
import ldtky/defs/intgrid
import ldtky/defs/entity
import ldtky/defs/layer
import ldtky/instances/world
import ldtky/enums
import ldtky/primitives
import ldtky/errors

suite "parseEnumDef":
  test "round-trips identifier, uid, tags":
    let n = %* {
      "identifier": "ItemType",
      "uid": 10,
      "values": [],
      "tags": ["weapon", "tool"],
      "externalRelPath": nil,
      "externalFileChecksum": nil,
      "iconTilesetUid": nil
    }
    let e = parseEnumDef(n)
    check e.identifier == "ItemType"
    check e.uid == 10
    check e.tags == @["weapon", "tool"]
    check e.values.len == 0

  test "parses enum values with tileRect":
    let n = %* {
      "identifier": "E",
      "uid": 1,
      "values": [{"color": 255, "id": "Red", "tileId": nil}],
      "tags": [],
      "externalRelPath": nil,
      "externalFileChecksum": nil,
      "iconTilesetUid": nil
    }
    let e = parseEnumDef(n)
    check e.values.len == 1
    check e.values[0].id == "Red"
    check e.values[0].tileRect.isNone

suite "parseTilesetDef":
  test "handles __cHei/__cWid correctly":
    let n = newJObject()
    n["identifier"] = newJString("tiles")
    n["uid"] = newJInt(5)
    n["__cHei"] = newJInt(10)
    n["__cWid"] = newJInt(8)
    n["pxHei"] = newJInt(160)
    n["pxWid"] = newJInt(128)
    n["tileGridSize"] = newJInt(16)
    n["padding"] = newJInt(0)
    n["spacing"] = newJInt(0)
    let t = parseTilesetDef(n)
    check t.cHei == 10
    check t.cWid == 8
    check t.uid == 5

  test "missing __cHei raises LdtkParseError":
    let n = %* {"identifier": "x", "uid": 1, "__cWid": 4,
                "pxHei": 64, "pxWid": 64, "tileGridSize": 16, "padding": 0, "spacing": 0}
    expect(LdtkParseError):
      discard parseTilesetDef(n)

suite "parseIntGridValueDef":
  test "optional identifier returns none when missing":
    let n = %* {"color": "#FF0000", "value": 1}
    let v = parseIntGridValueDef(n)
    check v.color == "#FF0000"
    check v.value == 1
    check v.identifier.isNone
    check v.groupUid == 0  # default when absent

  test "groupUid present":
    let n = %* {"color": "#00FF00", "value": 2, "groupUid": 3, "identifier": "Grass"}
    let v = parseIntGridValueDef(n)
    check v.groupUid == 3
    check v.identifier == some("Grass")

suite "parseEntityDef":
  test "parses renderMode and tileRenderMode enums":
    let n = %* {
      "identifier": "Player",
      "uid": 1,
      "width": 16,
      "height": 16,
      "color": "#FF0000",
      "pivotX": 0.5,
      "pivotY": 1.0,
      "fillOpacity": 1.0,
      "lineOpacity": 0.0,
      "tileOpacity": 1.0,
      "maxCount": 1,
      "resizableX": false,
      "resizableY": false,
      "keepAspectRatio": false,
      "hollow": false,
      "showName": true,
      "exportToToc": false,
      "renderMode": "Tile",
      "tileRenderMode": "FitInside",
      "limitBehavior": "MoveLastOne",
      "limitScope": "PerLevel",
      "tags": [],
      "nineSliceBorders": [],
      "fieldDefs": []
    }
    let e = parseEntityDef(n)
    check e.identifier == "Player"
    check e.renderMode == EntityRenderMode.Tile
    check e.tileRenderMode == TileRenderMode.FitInside

suite "parseLayerDef":
  test "maps __type to LayerKind for all 4 kinds":
    for (typeStr, expected) in [("IntGrid", LayerKind.IntGrid), ("Entities", LayerKind.Entities),
                                 ("Tiles", LayerKind.Tiles), ("AutoLayer", LayerKind.AutoLayer)]:
      let n = newJObject()
      n["identifier"] = newJString("layer")
      n["uid"] = newJInt(1)
      n["__type"] = newJString(typeStr)
      n["type"] = newJString(typeStr)
      n["gridSize"] = newJInt(16)
      n["displayOpacity"] = newJFloat(1.0)
      n["inactiveOpacity"] = newJFloat(0.6)
      n["pxOffsetX"] = newJInt(0)
      n["pxOffsetY"] = newJInt(0)
      n["guideGridHei"] = newJInt(0)
      n["guideGridWid"] = newJInt(0)
      n["parallaxFactorX"] = newJFloat(0.0)
      n["parallaxFactorY"] = newJFloat(0.0)
      n["parallaxScaling"] = newJBool(false)
      n["hideInList"] = newJBool(false)
      n["tilePivotX"] = newJFloat(0.0)
      n["tilePivotY"] = newJFloat(0.0)
      n["autoRuleGroups"] = newJArray()
      n["intGridValues"] = newJArray()
      n["excludedTags"] = newJArray()
      n["requiredTags"] = newJArray()
      let ld = parseLayerDef(n)
      check ld.layerKind == expected

suite "parseDefinitions":
  test "parses empty definition containers":
    let n = %* {
      "entities": [],
      "enums": [],
      "externalEnums": [],
      "layers": [],
      "levelFields": [],
      "tilesets": []
    }
    let d = parseDefinitions(n)
    check d.entities.len == 0
    check d.enums.len == 0
    check d.tilesets.len == 0

  test "missing required field in sub-parser raises LdtkParseError":
    let n = %* {
      "entities": [{"uid": 1}],  # Missing required 'identifier'
      "enums": [], "externalEnums": [], "layers": [],
      "levelFields": [], "tilesets": []
    }
    expect(LdtkParseError):
      discard parseDefinitions(n)

suite "parseWorld":
  test "parses world with worldLayout enum":
    let n = %* {
      "identifier": "Horizontal",
      "iid": "abc-123",
      "worldGridHeight": 256,
      "worldGridWidth": 256,
      "defaultLevelHeight": 256,
      "defaultLevelWidth": 256,
      "worldLayout": "LinearHorizontal",
      "levels": []
    }
    let w = parseWorld(n)
    check w.identifier == "Horizontal"
    check w.worldLayout == some(WorldLayout.LinearHorizontal)
    check w.levels.len == 0

  test "null worldLayout yields none":
    let n = newJObject()
    n["identifier"] = newJString("W")
    n["iid"] = newJString("x")
    n["worldGridHeight"] = newJInt(0)
    n["worldGridWidth"] = newJInt(0)
    n["defaultLevelHeight"] = newJInt(256)
    n["defaultLevelWidth"] = newJInt(256)
    n["worldLayout"] = newJNull()
    let w = parseWorld(n)
    check w.worldLayout.isNone
