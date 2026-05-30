import std/json
import std/options
import ldtky/primitives
import ldtky/defs/enums
import ldtky/json_helpers
import ldtky/errors

type
  TilesetDef* = object
    ## Tileset definition. `cHei` and `cWid` are parsed from `__cHei`/`__cWid`.
    identifier*: string
    uid*: int
    cHei*, cWid*: int
    pxHei*, pxWid*: int
    tileGridSize*, padding*, spacing*: int
    relPath*: Option[string]
    tagsSourceEnumUid*: Option[int]
    embedAtlas*: Option[string]
    tags*: seq[string]
    customData*: seq[TileCustomMetadata]
    enumTags*: seq[EnumTagValue]

proc parseCustomData(node: JsonNode): TileCustomMetadata =
  if node.kind != JObject:
    raise newException(LdtkParseError, "TileCustomMetadata: expected object, got " & $node.kind)
  result.data   = getField[string](node, "data")
  result.tileId = getField[int](node, "tileId")

proc parseTilesetDef*(node: JsonNode): TilesetDef =
  result.identifier    = getField[string](node, "identifier")
  result.uid           = getField[int](node, "uid")
  result.cHei          = getField[int](node, "__cHei")
  result.cWid          = getField[int](node, "__cWid")
  result.pxHei         = getField[int](node, "pxHei")
  result.pxWid         = getField[int](node, "pxWid")
  result.tileGridSize  = getField[int](node, "tileGridSize")
  result.padding       = getField[int](node, "padding")
  result.spacing       = getField[int](node, "spacing")
  result.relPath       = getOpt[string](node, "relPath")
  result.tagsSourceEnumUid = getOpt[int](node, "tagsSourceEnumUid")
  if node.hasKey("embedAtlas") and node["embedAtlas"].kind == JString:
    result.embedAtlas = some(node["embedAtlas"].getStr)
  if node.hasKey("tags") and node["tags"].kind == JArray:
    for tag in node["tags"]:
      if tag.kind != JString:
        raise newException(LdtkParseError, "TilesetDef.tags: expected string element, got " & $tag.kind)
      result.tags.add(tag.getStr)
  if node.hasKey("customData") and node["customData"].kind == JArray:
    for item in node["customData"]:
      result.customData.add(parseCustomData(item))
  if node.hasKey("enumTags") and node["enumTags"].kind == JArray:
    for item in node["enumTags"]:
      result.enumTags.add(parseEnumTagValue(item))
