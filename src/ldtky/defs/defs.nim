import std/json
import ldtky/defs/entity
import ldtky/defs/enums
import ldtky/defs/field
import ldtky/defs/layer
import ldtky/defs/tileset
import ldtky/errors

type
  Definitions* = object
    entities*: seq[EntityDef]
    enums*: seq[EnumDef]
    externalEnums*: seq[EnumDef]
    layers*: seq[LayerDef]
    levelFields*: seq[FieldDef]
    tilesets*: seq[TilesetDef]

proc parseDefinitions*(node: JsonNode): Definitions =
  if node.kind != JObject:
    raise newException(LdtkParseError, "Definitions: expected object, got " & $node.kind)
  if node.hasKey("entities") and node["entities"].kind == JArray:
    for e in node["entities"]:
      result.entities.add(parseEntityDef(e))
  if node.hasKey("enums") and node["enums"].kind == JArray:
    for e in node["enums"]:
      result.enums.add(parseEnumDef(e))
  if node.hasKey("externalEnums") and node["externalEnums"].kind == JArray:
    for e in node["externalEnums"]:
      result.externalEnums.add(parseEnumDef(e))
  if node.hasKey("layers") and node["layers"].kind == JArray:
    for l in node["layers"]:
      result.layers.add(parseLayerDef(l))
  if node.hasKey("levelFields") and node["levelFields"].kind == JArray:
    for f in node["levelFields"]:
      result.levelFields.add(parseFieldDef(f))
  if node.hasKey("tilesets") and node["tilesets"].kind == JArray:
    for t in node["tilesets"]:
      result.tilesets.add(parseTilesetDef(t))
