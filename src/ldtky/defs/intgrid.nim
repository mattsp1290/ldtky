import std/json
import std/options
import ldtky/json_helpers

type
  IntGridValueDef* = object
    ## A single IntGrid value: its integer value, display color, and optional identifier.
    color*: string
    groupUid*, value*: int
    identifier*: Option[string]

  IntGridValueGroupDef* = object
    ## A group of IntGrid values with a shared optional color and identifier.
    uid*: int
    color*, identifier*: Option[string]

  IntGridValueInstance* = object
    ## A placed IntGrid value instance: flat coordinate ID and value.
    coordId*, v*: int

proc parseIntGridValueDef*(node: JsonNode): IntGridValueDef =
  result.color      = getField[string](node, "color")
  result.groupUid   = getField[int](node, "groupUid")
  result.value      = getField[int](node, "value")
  result.identifier = getOpt[string](node, "identifier")

proc parseIntGridValueGroupDef*(node: JsonNode): IntGridValueGroupDef =
  result.uid        = getField[int](node, "uid")
  result.color      = getOpt[string](node, "color")
  result.identifier = getOpt[string](node, "identifier")

proc parseIntGridValueInstance*(node: JsonNode): IntGridValueInstance =
  result.coordId = getField[int](node, "coordId")
  result.v       = getField[int](node, "v")
