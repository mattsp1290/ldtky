import std/json
import std/options
import ldtky/primitives
import ldtky/instances/entity
import ldtky/json_helpers
import ldtky/errors

type
  LayerInstance* = ref object
    ## A layer instance within a level. Use ref to avoid deep-copy cost.
    ## All __-prefixed fields are parsed manually via getField[T].
    identifier*: string       ## from __identifier
    iid*: string
    layerType*: string        ## from __type (e.g. "IntGrid", "Entities")
    cHei*, cWid*: int         ## from __cHei, __cWid
    gridSize*: int            ## from __gridSize
    opacity*: float           ## from __opacity
    pxTotalOffsetX*, pxTotalOffsetY*: int  ## from __pxTotalOffsetX/Y
    tilesetRelPath*: Option[string]         ## from __tilesetRelPath (opt)
    tilesetDefUid*: Option[int]             ## from __tilesetDefUid (opt)
    layerDefUid*, levelId*: int
    pxOffsetX*, pxOffsetY*: int
    seed*: int
    visible*: bool
    overrideTilesetUid*: Option[int]
    intGridCsv*: seq[int]
    optionalRules*: seq[int]
    autoLayerTiles*: seq[Tile]
    gridTiles*: seq[Tile]
    entityInstances*: seq[EntityInstance]

proc parseTile(node: JsonNode): Tile =
  if node.kind != JObject:
    raise newException(LdtkParseError, "Tile: expected object, got " & $node.kind)
  result.f = getField[int](node, "f")
  result.t = getField[int](node, "t")
  result.a = getField[float](node, "a")
  if node.hasKey("px") and node["px"].kind == JArray:
    for v in node["px"]:
      result.px.add(v.getInt)
  if node.hasKey("src") and node["src"].kind == JArray:
    for v in node["src"]:
      result.src.add(v.getInt)
  if node.hasKey("d") and node["d"].kind == JArray:
    for v in node["d"]:
      result.d.add(v.getInt)

proc parseLayerInstance*(node: JsonNode): LayerInstance =
  result = LayerInstance()
  result.identifier       = getField[string](node, "__identifier")
  result.iid              = getField[string](node, "iid")
  result.layerType        = getField[string](node, "__type")
  result.cHei             = getField[int](node, "__cHei")
  result.cWid             = getField[int](node, "__cWid")
  result.gridSize         = getField[int](node, "__gridSize")
  result.opacity          = getField[float](node, "__opacity")
  result.pxTotalOffsetX   = getField[int](node, "__pxTotalOffsetX")
  result.pxTotalOffsetY   = getField[int](node, "__pxTotalOffsetY")
  result.tilesetRelPath   = getOpt[string](node, "__tilesetRelPath")
  result.tilesetDefUid    = getOpt[int](node, "__tilesetDefUid")
  result.layerDefUid      = getField[int](node, "layerDefUid")
  result.levelId          = getField[int](node, "levelId")
  result.pxOffsetX        = getField[int](node, "pxOffsetX")
  result.pxOffsetY        = getField[int](node, "pxOffsetY")
  result.seed             = getField[int](node, "seed")
  result.visible          = getField[bool](node, "visible")
  result.overrideTilesetUid = getOpt[int](node, "overrideTilesetUid")
  if node.hasKey("intGridCsv") and node["intGridCsv"].kind == JArray:
    for v in node["intGridCsv"]:
      if v.kind != JInt:
        raise newException(LdtkParseError, "LayerInstance.intGridCsv: expected int, got " & $v.kind)
      result.intGridCsv.add(v.getInt)
  if node.hasKey("optionalRules") and node["optionalRules"].kind == JArray:
    for v in node["optionalRules"]:
      if v.kind != JInt:
        raise newException(LdtkParseError, "LayerInstance.optionalRules: expected int, got " & $v.kind)
      result.optionalRules.add(v.getInt)
  if node.hasKey("autoLayerTiles") and node["autoLayerTiles"].kind == JArray:
    for t in node["autoLayerTiles"]:
      result.autoLayerTiles.add(parseTile(t))
  if node.hasKey("gridTiles") and node["gridTiles"].kind == JArray:
    for t in node["gridTiles"]:
      result.gridTiles.add(parseTile(t))
  if node.hasKey("entityInstances") and node["entityInstances"].kind == JArray:
    for e in node["entityInstances"]:
      result.entityInstances.add(parseEntityInstance(e))
