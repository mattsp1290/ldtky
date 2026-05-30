import unittest
import std/json
import std/options
import ldtky/json_helpers
import ldtky/errors

suite "getField":
  test "string: returns value for present key":
    let n = %* {"name": "hello"}
    check getField[string](n, "name") == "hello"

  test "int: returns value for present key":
    let n = %* {"x": 42}
    check getField[int](n, "x") == 42

  test "float: returns value for JFloat key":
    let n = %* {"v": 3.14}
    check abs(getField[float](n, "v") - 3.14) < 0.0001

  test "float: accepts JInt value (LDtk emits integer for float fields)":
    let n = %* {"a": 1}
    check getField[float](n, "a") == 1.0

  test "bool: returns value for present key":
    let n = %* {"flag": true}
    check getField[bool](n, "flag") == true

  test "string: raises LdtkParseError on missing key":
    let n = %* {"other": "val"}
    expect(LdtkParseError):
      discard getField[string](n, "name")

  test "int: raises LdtkParseError on wrong type":
    let n = %* {"x": "not-an-int"}
    expect(LdtkParseError):
      discard getField[int](n, "x")

  test "works on __-prefixed key":
    let n = newJObject()
    n["__cWid"] = newJInt(10)
    check getField[int](n, "__cWid") == 10

suite "getOpt":
  test "string: returns some(value) for present non-null key":
    let n = %* {"name": "hello"}
    check getOpt[string](n, "name") == some("hello")

  test "int: returns some(value) for present non-null key":
    let n = %* {"x": 7}
    check getOpt[int](n, "x") == some(7)

  test "float: returns some(value) for present non-null key":
    let n = %* {"v": 2.5}
    check getOpt[float](n, "v").isSome

  test "bool: returns some(value) for present non-null key":
    let n = %* {"flag": false}
    check getOpt[bool](n, "flag") == some(false)

  test "string: returns none for missing key":
    let n = %* {"other": "x"}
    check getOpt[string](n, "name") == none(string)

  test "int: returns none for missing key":
    let n = newJObject()
    check getOpt[int](n, "x") == none(int)

  test "string: returns none for JNull value":
    let n = newJObject()
    n["name"] = newJNull()
    check getOpt[string](n, "name") == none(string)

  test "int: returns none for JNull value":
    let n = newJObject()
    n["x"] = newJNull()
    check getOpt[int](n, "x") == none(int)

  test "float: accepts JInt value (LDtk int-as-float)":
    let n = %* {"v": 0}
    check getOpt[float](n, "v") == some(0.0)

  test "string: raises LdtkParseError on wrong type":
    let n = %* {"name": 123}
    expect(LdtkParseError):
      discard getOpt[string](n, "name")
