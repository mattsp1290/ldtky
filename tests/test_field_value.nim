import unittest
import std/json
import std/options
import ldtky/field_value
import ldtky/primitives
import ldtky/errors

suite "parseFieldValue — scalar types":
  test "Int: parses integer value":
    let v = parseFieldValue(%* 42, "Int")
    check v.kind == fkInt
    check v.intVal == 42

  test "Float: parses float value":
    let v = parseFieldValue(%* 3.14, "Float")
    check v.kind == fkFloat
    check abs(v.floatVal - 3.14) < 0.0001

  test "Float: accepts integer JSON (LDtk int-as-float)":
    let v = parseFieldValue(%* 1, "Float")
    check v.kind == fkFloat
    check v.floatVal == 1.0

  test "Bool: parses bool value":
    let v = parseFieldValue(%* true, "Bool")
    check v.kind == fkBool
    check v.boolVal == true

  test "String: parses string value":
    let v = parseFieldValue(%* "hello", "String")
    check v.kind == fkString
    check v.strVal == "hello"

  test "FilePath: stored as fkString":
    let v = parseFieldValue(%* "scripts/foo.lua", "FilePath")
    check v.kind == fkString
    check v.strVal == "scripts/foo.lua"

  test "Color: parses hex color string":
    let v = parseFieldValue(%* "#FF0000", "Color")
    check v.kind == fkColor
    check v.colorVal == "#FF0000"

  test "Point: parses {cx, cy} object":
    let v = parseFieldValue(%* {"cx": 3, "cy": 7}, "Point")
    check v.kind == fkPoint
    check v.pointVal.cx == 3
    check v.pointVal.cy == 7

  test "Tile: parses TilesetRect object":
    let v = parseFieldValue(%* {"h": 16, "w": 16, "x": 0, "y": 32, "tilesetUid": 5}, "Tile")
    check v.kind == fkTile
    check v.tileVal.h == 16
    check v.tileVal.tilesetUid == some(5)

  test "EntityRef: parses reference object":
    let v = parseFieldValue(
      %* {"entityIid": "abc", "layerIid": "def", "levelIid": "ghi", "worldIid": "jkl"},
      "EntityRef")
    check v.kind == fkEntityRef
    check v.entityRefVal.entityIid == "abc"

  test "LocalEnum.Foo: stored as fkEnum":
    let v = parseFieldValue(%* "Necklace", "LocalEnum.Item")
    check v.kind == fkEnum
    check v.enumVal == "Necklace"

  test "ExternEnum.Bar: stored as fkEnum":
    let v = parseFieldValue(%* "Hello", "ExternEnum.MyCastleDbEnum")
    check v.kind == fkEnum
    check v.enumVal == "Hello"

  test "null value raises LdtkParseError":
    expect(LdtkParseError):
      discard parseFieldValue(newJNull(), "Int")

  test "unknown type raises LdtkParseError":
    expect(LdtkParseError):
      discard parseFieldValue(%* "x", "UnknownType")

suite "parseFieldValue — array types":
  test "Array<Int>: parses integer array":
    let v = parseFieldValue(%* [1, 2, 3], "Array<Int>")
    check v.kind == fkIntArray
    check v.intArr == @[1, 2, 3]

  test "Array<Float>: accepts integer elements":
    let v = parseFieldValue(%* [0, 1, 2], "Array<Float>")
    check v.kind == fkFloatArray
    check v.floatArr == @[0.0, 1.0, 2.0]

  test "Array<Bool>: parses bool array":
    let v = parseFieldValue(%* [true, false], "Array<Bool>")
    check v.kind == fkBoolArray
    check v.boolArr == @[true, false]

  test "Array<String>: parses string array":
    let v = parseFieldValue(%* ["a", "b"], "Array<String>")
    check v.kind == fkStringArray
    check v.strArr == @["a", "b"]

  test "Array<Point>: parses GridPoint array":
    let v = parseFieldValue(%* [{"cx": 1, "cy": 2}, {"cx": 3, "cy": 4}], "Array<Point>")
    check v.kind == fkPointArray
    check v.pointArr.len == 2
    check v.pointArr[0].cx == 1

  test "Array<EntityRef>: parses reference array":
    let v = parseFieldValue(
      %* [{"entityIid":"a","layerIid":"b","levelIid":"c","worldIid":"d"}],
      "Array<EntityRef>")
    check v.kind == fkEntityRefArray
    check v.entityRefArr.len == 1

  test "Array<LocalEnum.Item>: empty array is valid":
    let v = parseFieldValue(%* [], "Array<LocalEnum.Item>")
    check v.kind == fkEnumArray
    check v.enumArr.len == 0

  test "Array<ExternEnum.X>: null element stored as empty string":
    let arr = newJArray()
    arr.add(newJNull())
    let v = parseFieldValue(arr, "Array<ExternEnum.X>")
    check v.kind == fkEnumArray
    check v.enumArr == @[""]
