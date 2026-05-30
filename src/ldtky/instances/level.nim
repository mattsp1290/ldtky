import std/json
import std/options
import ldtky/instances/layer
import ldtky/instances/field
import ldtky/json_helpers
import ldtky/errors

type
  NeighbourLevel* = object
    ## A directional reference to an adjacent level.
    dir*: string       ## compass direction ("n", "s", "e", "w", etc.)
    levelIid*: string
    levelUid*: Option[int]

  LevelBgPosInfos* = object
    ## Background image position/scale info. Values may be int or float in JSON.
    cropRect*: seq[float]    ## [x, y, w, h] crop rectangle in source image (pixels)
    scale*: seq[float]       ## [sx, sy] scale factors
    topLeftPx*: seq[float]   ## [x, y] top-left pixel position in the level

  Level* = ref object
    ## A level in the project. Use ref to avoid deep-copy cost (contains layerInstances).
    ## Several fields (__bgColor, __neighbours, __smartColor, __bgPos) use __-prefixes.
    identifier*, iid*: string
    uid*, pxHei*, pxWid*, worldDepth*, worldX*, worldY*: int
    bgPivotX*, bgPivotY*: float
    smartColor*: string         ## from __smartColor
    computedBgColor*: Option[string]  ## from computedBgColor (absent in older LDtk)
    bgColor*: Option[string]    ## from __bgColor (user-defined override)
    useAutoIdentifier*: bool
    externalRelPath*: Option[string]
    bgRelPath*: Option[string]
    neighbours*: seq[NeighbourLevel]   ## from __neighbours
    bgPos*: Option[LevelBgPosInfos]    ## from __bgPos
    layerInstances*: Option[seq[LayerInstance]]  ## null when externalLevels=true
    fieldInstances*: seq[FieldInstance]

proc parseFloatSeq(node: JsonNode, ctx: string): seq[float] =
  if node.kind != JArray:
    raise newException(LdtkParseError, ctx & ": expected array, got " & $node.kind)
  for v in node:
    case v.kind
    of JFloat: result.add(v.getFloat)
    of JInt:   result.add(v.getInt.float)
    else:
      raise newException(LdtkParseError, ctx & " element: expected float/int, got " & $v.kind)

proc parseNeighbourLevel(node: JsonNode): NeighbourLevel =
  result.dir      = getField[string](node, "dir")
  result.levelIid = getField[string](node, "levelIid")
  result.levelUid = getOpt[int](node, "levelUid")

proc parseFloatSeqField(node: JsonNode, key: string): seq[float] =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "LevelBgPosInfos: missing field: " & key)
  parseFloatSeq(node[key], "LevelBgPosInfos." & key)

proc parseLevelBgPosInfos(node: JsonNode): LevelBgPosInfos =
  if node.kind != JObject:
    raise newException(LdtkParseError, "LevelBgPosInfos: expected object, got " & $node.kind)
  result.cropRect  = parseFloatSeqField(node, "cropRect")
  result.scale     = parseFloatSeqField(node, "scale")
  result.topLeftPx = parseFloatSeqField(node, "topLeftPx")

proc parseLevel*(node: JsonNode): Level =
  ## Parse a level JSON object. Returns a `Level` ref.
  ## `layerInstances` is `none` when the level has external layers (`externalLevels=true`).
  result = Level()
  result.identifier   = getField[string](node, "identifier")
  result.iid          = getField[string](node, "iid")
  result.uid          = getField[int](node, "uid")
  result.pxHei        = getField[int](node, "pxHei")
  result.pxWid        = getField[int](node, "pxWid")
  result.worldDepth   = getField[int](node, "worldDepth")
  result.worldX       = getField[int](node, "worldX")
  result.worldY       = getField[int](node, "worldY")
  result.bgPivotX     = getField[float](node, "bgPivotX")
  result.bgPivotY     = getField[float](node, "bgPivotY")
  result.smartColor   = getField[string](node, "__smartColor")
  result.bgColor      = getOpt[string](node, "__bgColor")
  result.computedBgColor = getOpt[string](node, "computedBgColor")
  result.useAutoIdentifier = getOpt[bool](node, "useAutoIdentifier").get(false)
  result.externalRelPath = getOpt[string](node, "externalRelPath")
  result.bgRelPath    = getOpt[string](node, "bgRelPath")
  if node.hasKey("__bgPos") and node["__bgPos"].kind == JObject:
    result.bgPos = some(parseLevelBgPosInfos(node["__bgPos"]))
  if node.hasKey("__neighbours") and node["__neighbours"].kind == JArray:
    for nb in node["__neighbours"]:
      result.neighbours.add(parseNeighbourLevel(nb))
  if node.hasKey("layerInstances") and node["layerInstances"].kind == JArray:
    var layers: seq[LayerInstance]
    for li in node["layerInstances"]:
      layers.add(parseLayerInstance(li))
    result.layerInstances = some(layers)
  if node.hasKey("fieldInstances") and node["fieldInstances"].kind == JArray:
    for fi in node["fieldInstances"]:
      result.fieldInstances.add(parseFieldInstance(fi))
