import std/json
import std/options
import std/strutils
import ldtky/enums
import ldtky/primitives
import ldtky/defs/field
import ldtky/json_helpers
import ldtky/errors

type
  EntityDef* = object
    identifier*: string
    uid*: int
    width*, height*: int
    color*: string
    pivotX*, pivotY*: float
    fillOpacity*, lineOpacity*, tileOpacity*: float
    renderMode*: EntityRenderMode
    tileRenderMode*: TileRenderMode
    limitBehavior*: LimitBehavior
    limitScope*: LimitScope
    maxCount*: int
    resizableX*, resizableY*: bool
    keepAspectRatio*: bool
    hollow*: bool
    showName*: bool
    exportToToc*: bool
    allowOutOfBounds*: Option[bool]
    fieldDefs*: seq[FieldDef]
    tags*: seq[string]
    nineSliceBorders*: seq[int]
    tileRect*: Option[TilesetRect]
    tileId*, tilesetId*: Option[int]
    maxHeight*, minHeight*, maxWidth*, minWidth*: Option[int]
    doc*: Option[string]

proc parseEnumField[T: enum](s, ctx: string): T =
  try: parseEnum[T](s)
  except ValueError:
    raise newException(LdtkParseError, ctx & ": unknown enum value: " & s)

proc parseTilesetRect(node: JsonNode): TilesetRect =
  if node.kind != JObject:
    raise newException(LdtkParseError, "TilesetRect: expected object, got " & $node.kind)
  result.h          = getField[int](node, "h")
  result.w          = getField[int](node, "w")
  result.x          = getField[int](node, "x")
  result.y          = getField[int](node, "y")
  result.tilesetUid = getField[int](node, "tilesetUid")

proc parseEntityDef*(node: JsonNode): EntityDef =
  result.identifier    = getField[string](node, "identifier")
  result.uid           = getField[int](node, "uid")
  result.width         = getField[int](node, "width")
  result.height        = getField[int](node, "height")
  result.color         = getField[string](node, "color")
  result.pivotX        = getField[float](node, "pivotX")
  result.pivotY        = getField[float](node, "pivotY")
  result.fillOpacity   = getField[float](node, "fillOpacity")
  result.lineOpacity   = getField[float](node, "lineOpacity")
  result.tileOpacity   = getField[float](node, "tileOpacity")
  result.maxCount      = getField[int](node, "maxCount")
  result.resizableX    = getField[bool](node, "resizableX")
  result.resizableY    = getField[bool](node, "resizableY")
  result.keepAspectRatio = getField[bool](node, "keepAspectRatio")
  result.hollow        = getField[bool](node, "hollow")
  result.showName      = getField[bool](node, "showName")
  result.exportToToc   = getField[bool](node, "exportToToc")
  result.allowOutOfBounds = getOpt[bool](node, "allowOutOfBounds")
  result.tileId        = getOpt[int](node, "tileId")
  result.tilesetId     = getOpt[int](node, "tilesetId")
  result.maxHeight     = getOpt[int](node, "maxHeight")
  result.minHeight     = getOpt[int](node, "minHeight")
  result.maxWidth      = getOpt[int](node, "maxWidth")
  result.minWidth      = getOpt[int](node, "minWidth")
  result.doc           = getOpt[string](node, "doc")
  result.renderMode    = parseEnumField[EntityRenderMode](
    getField[string](node, "renderMode"), "EntityDef.renderMode")
  result.tileRenderMode = parseEnumField[TileRenderMode](
    getField[string](node, "tileRenderMode"), "EntityDef.tileRenderMode")
  result.limitBehavior = parseEnumField[LimitBehavior](
    getField[string](node, "limitBehavior"), "EntityDef.limitBehavior")
  result.limitScope    = parseEnumField[LimitScope](
    getField[string](node, "limitScope"), "EntityDef.limitScope")
  if node.hasKey("tileRect") and node["tileRect"].kind == JObject:
    result.tileRect = some(parseTilesetRect(node["tileRect"]))
  if node.hasKey("tags") and node["tags"].kind == JArray:
    for tag in node["tags"]:
      if tag.kind != JString:
        raise newException(LdtkParseError, "EntityDef.tags: expected string, got " & $tag.kind)
      result.tags.add(tag.getStr)
  if node.hasKey("nineSliceBorders") and node["nineSliceBorders"].kind == JArray:
    for v in node["nineSliceBorders"]:
      if v.kind != JInt:
        raise newException(LdtkParseError, "EntityDef.nineSliceBorders: expected int, got " & $v.kind)
      result.nineSliceBorders.add(v.getInt)
  if node.hasKey("fieldDefs") and node["fieldDefs"].kind == JArray:
    for fd in node["fieldDefs"]:
      result.fieldDefs.add(parseFieldDef(fd))
