import std/json
import std/options
import ldtky/primitives
import ldtky/field_value
import ldtky/json_helpers
import ldtky/errors

type
  FieldInstance* = object
    ## A field value instance on an entity or level.
    ## All four keys (__identifier, __type, __value, __tile) have double-underscore prefixes.
    identifier*: string     ## from __identifier
    fieldType*: string      ## from __type (human-readable, e.g. "Int", "LocalEnum.Foo")
    defUid*: int
    value*: Option[FieldValue]   ## none when __value is null
    tile*: Option[TilesetRect]   ## from __tile (opt)

proc requireDoubleUnderscoreStr(node: JsonNode, key: string): string =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "missing required field: " & key)
  let v = node[key]
  if v.kind != JString:
    raise newException(LdtkParseError, "field " & key & ": expected string, got " & $v.kind)
  v.getStr

proc parseTilesetRect(node: JsonNode): TilesetRect =
  if node.kind != JObject:
    raise newException(LdtkParseError, "TilesetRect: expected object, got " & $node.kind)
  result.h          = getField[int](node, "h")
  result.w          = getField[int](node, "w")
  result.x          = getField[int](node, "x")
  result.y          = getField[int](node, "y")
  result.tilesetUid = getField[int](node, "tilesetUid")

proc parseFieldInstance*(node: JsonNode): FieldInstance =
  result.identifier = requireDoubleUnderscoreStr(node, "__identifier")
  result.fieldType  = requireDoubleUnderscoreStr(node, "__type")
  result.defUid     = getField[int](node, "defUid")
  if node.hasKey("__value") and node["__value"].kind != JNull:
    result.value = some(parseFieldValue(node["__value"], result.fieldType))
  if node.hasKey("__tile") and node["__tile"].kind == JObject:
    result.tile = some(parseTilesetRect(node["__tile"]))
