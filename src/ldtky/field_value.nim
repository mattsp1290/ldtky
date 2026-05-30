import std/json
import std/strutils
import ldtky/primitives
import ldtky/errors
import ldtky/json_helpers
# Selective import to avoid conflict with local requireInt/requireStr/requireBool helpers
# (which take node+ctx for type-checking vs parse_utils' node+key for lookup)
from ldtky/parse_utils import parseTilesetRect, parseEntityReferenceInfos
# Re-export so code that imports field_value still sees EntityReferenceInfos
export EntityReferenceInfos

type
  FieldKind* = enum
    fkInt, fkFloat, fkBool, fkString, fkColor, fkPoint, fkTile,
    fkEntityRef, fkEnum,
    fkIntArray, fkFloatArray, fkBoolArray, fkStringArray, fkColorArray,
    fkPointArray, fkTileArray, fkEntityRefArray, fkEnumArray

  FieldValue* = object
    ## A parsed LDtk field value. The `kind` discriminant selects the active branch.
    ## Color values are hex strings ("#rrggbb"). Enum values carry the identifier string.
    ## FilePath fields are stored as fkString (no separate kind).
    case kind*: FieldKind
    of fkInt:       intVal*: int
    of fkFloat:     floatVal*: float
    of fkBool:      boolVal*: bool
    of fkString:    strVal*: string
    of fkColor:     colorVal*: string
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

proc requireInt(node: JsonNode, ctx: string): int =
  if node.kind != JInt:
    raise newException(LdtkParseError, ctx & ": expected int, got " & $node.kind)
  node.getInt

proc requireStr(node: JsonNode, ctx: string): string =
  if node.kind != JString:
    raise newException(LdtkParseError, ctx & ": expected string, got " & $node.kind)
  node.getStr

proc requireBool(node: JsonNode, ctx: string): bool =
  if node.kind != JBool:
    raise newException(LdtkParseError, ctx & ": expected bool, got " & $node.kind)
  node.getBool

proc parseGridPoint(node: JsonNode): GridPoint =
  if node.kind != JObject:
    raise newException(LdtkParseError, "Point value: expected object, got " & $node.kind)
  result.cx = getField[int](node, "cx")
  result.cy = getField[int](node, "cy")

proc jsonToFloat(node: JsonNode): float =
  # LDtk emits integer JSON for float fields (e.g. `"a": 1` not `"a": 1.0`)
  case node.kind
  of JFloat: node.getFloat
  of JInt:   node.getInt.float
  else: raise newException(LdtkParseError, "Float value: expected float/int, got " & $node.kind)

proc parseFieldValue*(node: JsonNode, fieldType: string): FieldValue =
  ## Parse a LDtk field `__value` node given its `__type` string.
  ## Raises LdtkParseError if the node is null or the value doesn't match the type.
  ## Callers should check for JNull before calling this when the field is optional.
  if node.kind == JNull:
    raise newException(LdtkParseError, "field value is null for type: " & fieldType)

  # Detect array wrapper: "Array<ElementType>"
  if fieldType.startsWith("Array<") and fieldType.endsWith(">"):
    let elemType = fieldType[6 .. ^2]  # strip "Array<" and ">"
    if node.kind != JArray:
      raise newException(LdtkParseError,
        "Array field: expected JSON array, got " & $node.kind)

    if elemType == "Int":
      result = FieldValue(kind: fkIntArray)
      for item in node:
        result.intArr.add(requireInt(item, "Array<Int> element"))
    elif elemType == "Float":
      result = FieldValue(kind: fkFloatArray)
      for item in node:
        result.floatArr.add(jsonToFloat(item))
    elif elemType == "Bool":
      result = FieldValue(kind: fkBoolArray)
      for item in node:
        result.boolArr.add(requireBool(item, "Array<Bool> element"))
    elif elemType == "String" or elemType == "FilePath":
      result = FieldValue(kind: fkStringArray)
      for item in node:
        result.strArr.add(requireStr(item, "Array<String> element"))
    elif elemType == "Color":
      result = FieldValue(kind: fkColorArray)
      for item in node:
        result.colorArr.add(requireStr(item, "Array<Color> element"))
    elif elemType == "Point":
      result = FieldValue(kind: fkPointArray)
      for item in node:
        result.pointArr.add(parseGridPoint(item))
    elif elemType == "Tile":
      result = FieldValue(kind: fkTileArray)
      for item in node:
        result.tileArr.add(parseTilesetRect(item))
    elif elemType == "EntityRef":
      result = FieldValue(kind: fkEntityRefArray)
      for item in node:
        result.entityRefArr.add(parseEntityReferenceInfos(item))
    elif elemType.startsWith("LocalEnum.") or elemType.startsWith("ExternEnum."):
      result = FieldValue(kind: fkEnumArray)
      for item in node:
        if item.kind == JNull:
          result.enumArr.add("")  # null enum element treated as empty string
        else:
          result.enumArr.add(requireStr(item, "Array<Enum> element"))
    else:
      raise newException(LdtkParseError, "unknown array element type: " & elemType)
    return

  # Scalar types
  case fieldType
  of "Int":
    result = FieldValue(kind: fkInt, intVal: requireInt(node, "Int field"))
  of "Float":
    result = FieldValue(kind: fkFloat, floatVal: jsonToFloat(node))
  of "Bool":
    result = FieldValue(kind: fkBool, boolVal: requireBool(node, "Bool field"))
  of "String", "FilePath":
    # FilePath is a string in the JSON value; no separate kind needed
    result = FieldValue(kind: fkString, strVal: requireStr(node, "String field"))
  of "Color":
    result = FieldValue(kind: fkColor, colorVal: requireStr(node, "Color field"))
  of "Point":
    result = FieldValue(kind: fkPoint, pointVal: parseGridPoint(node))
  of "Tile":
    result = FieldValue(kind: fkTile, tileVal: parseTilesetRect(node))
  of "EntityRef":
    result = FieldValue(kind: fkEntityRef, entityRefVal: parseEntityReferenceInfos(node))
  else:
    # LocalEnum.Foo or ExternEnum.Foo
    if fieldType.startsWith("LocalEnum.") or fieldType.startsWith("ExternEnum."):
      result = FieldValue(kind: fkEnum, enumVal: requireStr(node, "Enum field"))
    else:
      raise newException(LdtkParseError, "unknown field type: " & fieldType)
