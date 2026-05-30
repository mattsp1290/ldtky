import std/json
import std/options
import ldtky/primitives
import ldtky/json_helpers
import ldtky/errors
import ldtky/parse_utils

type
  EnumDefValues* = object
    ## A single value within an enum definition.
    ## `tileRect` is the preferred tile reference (LDtk v1.3.2+, has tilesetUid).
    ## The legacy `__tileSrcRect` array is available in the raw JSON but not stored here.
    color*: int
    id*: string
    tileId*: Option[int]
    tileRect*: Option[TilesetRect]

  EnumDef* = object
    identifier*: string
    uid*: int
    values*: seq[EnumDefValues]
    tags*: seq[string]
    externalFileChecksum*, externalRelPath*: Option[string]
    iconTilesetUid*: Option[int]

  EnumTagValue* = object
    enumValueId*: string
    tileIds*: seq[int]

proc parseEnumDefValues(node: JsonNode): EnumDefValues =
  result.color  = getField[int](node, "color")
  result.id     = getField[string](node, "id")
  result.tileId = getOpt[int](node, "tileId")
  if node.hasKey("tileRect") and node["tileRect"].kind == JObject:
    result.tileRect = some(parseTilesetRect(node["tileRect"]))

proc parseEnumDef*(node: JsonNode): EnumDef =
  result.identifier           = getField[string](node, "identifier")
  result.uid                  = getField[int](node, "uid")
  result.externalFileChecksum = getOpt[string](node, "externalFileChecksum")
  result.externalRelPath      = getOpt[string](node, "externalRelPath")
  result.iconTilesetUid       = getOpt[int](node, "iconTilesetUid")
  if node.hasKey("tags") and node["tags"].kind == JArray:
    for tag in node["tags"]:
      if tag.kind != JString:
        raise newException(LdtkParseError, "EnumDef.tags: expected string element, got " & $tag.kind)
      result.tags.add(tag.getStr)
  if node.hasKey("values") and node["values"].kind == JArray:
    for v in node["values"]:
      result.values.add(parseEnumDefValues(v))

proc parseEnumTagValue*(node: JsonNode): EnumTagValue =
  result.enumValueId = getField[string](node, "enumValueId")
  if node.hasKey("tileIds") and node["tileIds"].kind == JArray:
    for id in node["tileIds"]:
      if id.kind != JInt:
        raise newException(LdtkParseError, "EnumTagValue.tileIds: expected int element, got " & $id.kind)
      result.tileIds.add(id.getInt)
