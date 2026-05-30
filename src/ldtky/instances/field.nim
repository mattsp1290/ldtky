import std/json
import std/options
import ldtky/primitives
import ldtky/field_value
import ldtky/json_helpers
import ldtky/parse_utils

type
  FieldInstance* = object
    ## A field value instance on an entity or level.
    ## All four keys (__identifier, __type, __value, __tile) have double-underscore prefixes.
    identifier*: string     ## from __identifier
    fieldType*: string      ## from __type (human-readable, e.g. "Int", "LocalEnum.Foo")
    defUid*: int
    value*: Option[FieldValue]   ## none when __value is null
    tile*: Option[TilesetRect]   ## from __tile (opt)

proc parseFieldInstance*(node: JsonNode): FieldInstance =
  result.identifier = requireStr(node, "__identifier")
  result.fieldType  = requireStr(node, "__type")
  result.defUid     = getField[int](node, "defUid")
  if node.hasKey("__value") and node["__value"].kind != JNull:
    result.value = some(parseFieldValue(node["__value"], result.fieldType))
  if node.hasKey("__tile") and node["__tile"].kind == JObject:
    result.tile = some(parseTilesetRect(node["__tile"]))
