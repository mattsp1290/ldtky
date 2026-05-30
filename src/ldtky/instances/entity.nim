import std/json
import std/options
import ldtky/primitives
import ldtky/instances/field
import ldtky/json_helpers
import ldtky/parse_utils
import ldtky/errors

type
  EntityInstance* = object
    ## A placed entity instance in a layer.
    ## Keys __grid, __identifier, __pivot, __smartColor, __tags, __tile,
    ## __worldX, __worldY all have double-underscore prefixes in LDtk JSON.
    identifier*: string      ## from __identifier
    iid*: string
    defUid*, height*, width*: int
    grid*: seq[int]           ## from __grid  ([cx, cy] in cell units)
    pivot*: seq[float]        ## from __pivot ([px, py] in 0.0–1.0)
    px*: seq[int]             ## pixel position [x, y]
    smartColor*: string       ## from __smartColor
    tags*: seq[string]        ## from __tags
    fieldInstances*: seq[FieldInstance]
    tile*: Option[TilesetRect]    ## from __tile (opt)
    worldX*, worldY*: Option[int] ## from __worldX, __worldY (opt)

proc parseEntityInstance*(node: JsonNode): EntityInstance =
  result.identifier  = getField[string](node, "__identifier")
  result.iid         = getField[string](node, "iid")
  result.defUid      = getField[int](node, "defUid")
  result.height      = getField[int](node, "height")
  result.width       = getField[int](node, "width")
  result.smartColor  = getField[string](node, "__smartColor")
  result.worldX      = getOpt[int](node, "__worldX")
  result.worldY      = getOpt[int](node, "__worldY")
  if node.hasKey("__tile") and node["__tile"].kind == JObject:
    result.tile = some(parseTilesetRect(node["__tile"]))
  for key in ["__grid", "__pivot", "px", "__tags", "fieldInstances"]:
    if not node.hasKey(key):
      raise newException(LdtkParseError, "EntityInstance: missing required array field: " & key)
    if node[key].kind != JArray:
      raise newException(LdtkParseError, "EntityInstance." & key & ": expected array, got " & $node[key].kind)
  for v in node["__grid"]:
    if v.kind != JInt:
      raise newException(LdtkParseError, "EntityInstance.__grid: expected int, got " & $v.kind)
    result.grid.add(v.getInt)
  for v in node["__pivot"]:
    case v.kind
    of JFloat: result.pivot.add(v.getFloat)
    of JInt:   result.pivot.add(v.getInt.float)
    else:
      raise newException(LdtkParseError, "EntityInstance.__pivot: expected float/int, got " & $v.kind)
  for v in node["px"]:
    if v.kind != JInt:
      raise newException(LdtkParseError, "EntityInstance.px: expected int, got " & $v.kind)
    result.px.add(v.getInt)
  for tag in node["__tags"]:
    if tag.kind != JString:
      raise newException(LdtkParseError, "EntityInstance.__tags: expected string, got " & $tag.kind)
    result.tags.add(tag.getStr)
  for fi in node["fieldInstances"]:
    result.fieldInstances.add(parseFieldInstance(fi))
