import std/json
import std/options
import ldtky/enums
import ldtky/instances/level
import ldtky/json_helpers
import ldtky/parse_utils
import ldtky/errors

type
  World* = object
    identifier*, iid*: string
    worldGridHeight*, worldGridWidth*: int
    defaultLevelHeight*, defaultLevelWidth*: int
    worldLayout*: Option[WorldLayout]  ## null in single-world projects (root-level)
    levels*: seq[Level]

proc parseWorld*(node: JsonNode): World =
  result.identifier        = getField[string](node, "identifier")
  result.iid               = getField[string](node, "iid")
  result.worldGridHeight   = getField[int](node, "worldGridHeight")
  result.worldGridWidth    = getField[int](node, "worldGridWidth")
  result.defaultLevelHeight = getField[int](node, "defaultLevelHeight")
  result.defaultLevelWidth  = getField[int](node, "defaultLevelWidth")
  let wlStr = getOpt[string](node, "worldLayout")
  if wlStr.isSome:
    result.worldLayout = some(parseEnumField[WorldLayout](wlStr.get, "World.worldLayout"))
  if node.hasKey("levels") and node["levels"].kind == JArray:
    for lv in node["levels"]:
      result.levels.add(parseLevel(lv))
