import std/json
import std/options
import ldtky/enums
import ldtky/defs/intgrid
import ldtky/json_helpers
import ldtky/parse_utils
import ldtky/errors

type
  AutoRuleDef* = object
    uid*: int
    active*: bool
    alpha*: float
    breakOnMatch*: bool
    chance*: float
    flipX*, flipY*: bool
    perlinActive*: bool
    perlinOctaves*, perlinScale*, perlinSeed*: float
    pivotX*, pivotY*: float
    size*, xModulo*, xOffset*, yModulo*, yOffset*: int
    tileRandomXMax*, tileRandomXMin*, tileRandomYMax*, tileRandomYMin*: int
    tileXOffset*, tileYOffset*: int
    checker*: AutoRuleChecker
    tileMode*: TileMode
    pattern*: seq[int]
    tileRectsIds*: seq[seq[int]]
    outOfBoundsValue*: Option[int]
    tileIds*: Option[seq[int]]    ## deprecated; prefer tileRectsIds

  AutoLayerRuleGroup* = object
    uid*: int
    name*: string
    active*: bool
    isOptional*: bool
    usesWizard*: bool
    rules*: seq[AutoRuleDef]
    color*: Option[string]
    biomeRequirementMode*: Option[int]    ## absent in older LDtk versions
    requiredBiomeValues*: seq[string]     ## absent in older LDtk versions

  LayerDef* = object
    ## Layer definition. `layerDefType` is parsed from `__type` (double-underscore).
    ## `layerKind` is the same value parsed as `LayerKind` enum.
    identifier*: string
    uid*: int
    layerDefType*: string   ## raw __type string (e.g. "IntGrid", "Entities")
    layerKind*: LayerKind   ## parsed from __type
    gridSize*: int
    displayOpacity*, inactiveOpacity*: float
    pxOffsetX*, pxOffsetY*: int
    guideGridHei*, guideGridWid*: int
    parallaxFactorX*, parallaxFactorY*: float
    parallaxScaling*: bool
    renderInWorldView*: bool
    canSelectWhenInactive*: bool
    hideFieldsWhenInactive*: bool
    hideInList*: bool
    tilePivotX*, tilePivotY*: float
    autoRuleGroups*: seq[AutoLayerRuleGroup]
    intGridValues*: seq[IntGridValueDef]
    intGridValuesGroups*: seq[IntGridValueGroupDef]
    excludedTags*, requiredTags*: seq[string]
    uiFilterTags*: seq[string]
    tilesetDefUid*: Option[int]
    autoSourceLayerDefUid*: Option[int]
    autoTilesetDefUid*: Option[int]
    uiColor*: Option[string]
    doc*: Option[string]

proc parseAutoRuleDef(node: JsonNode): AutoRuleDef =
  result.uid            = getField[int](node, "uid")
  result.active         = getField[bool](node, "active")
  result.alpha          = getOpt[float](node, "alpha").get(1.0)  # absent in LDtk < v1.3
  result.breakOnMatch   = getField[bool](node, "breakOnMatch")
  result.chance         = getField[float](node, "chance")
  result.flipX          = getField[bool](node, "flipX")
  result.flipY          = getField[bool](node, "flipY")
  result.perlinActive   = getField[bool](node, "perlinActive")
  result.perlinOctaves  = getField[float](node, "perlinOctaves")
  result.perlinScale    = getField[float](node, "perlinScale")
  result.perlinSeed     = getField[float](node, "perlinSeed")
  result.pivotX         = getField[float](node, "pivotX")
  result.pivotY         = getField[float](node, "pivotY")
  result.size           = getField[int](node, "size")
  result.xModulo        = getField[int](node, "xModulo")
  result.xOffset        = getOpt[int](node, "xOffset").get(0)   # absent in LDtk v1.0
  result.yModulo        = getField[int](node, "yModulo")
  result.yOffset        = getOpt[int](node, "yOffset").get(0)   # absent in LDtk v1.0
  # tile offset/random fields added in LDtk v1.3+; default 0 for older files
  result.tileRandomXMax = getOpt[int](node, "tileRandomXMax").get(0)
  result.tileRandomXMin = getOpt[int](node, "tileRandomXMin").get(0)
  result.tileRandomYMax = getOpt[int](node, "tileRandomYMax").get(0)
  result.tileRandomYMin = getOpt[int](node, "tileRandomYMin").get(0)
  result.tileXOffset    = getOpt[int](node, "tileXOffset").get(0)
  result.tileYOffset    = getOpt[int](node, "tileYOffset").get(0)
  result.checker    = parseEnumField[AutoRuleChecker](getField[string](node, "checker"), "AutoRuleDef.checker")
  result.tileMode   = parseEnumField[TileMode](getField[string](node, "tileMode"), "AutoRuleDef.tileMode")
  result.outOfBoundsValue = getOpt[int](node, "outOfBoundsValue")
  if node.hasKey("pattern") and node["pattern"].kind == JArray:
    for v in node["pattern"]:
      if v.kind != JInt:
        raise newException(LdtkParseError, "AutoRuleDef.pattern: expected int, got " & $v.kind)
      result.pattern.add(v.getInt)
  if node.hasKey("tileRectsIds") and node["tileRectsIds"].kind == JArray:
    for row in node["tileRectsIds"]:
      if row.kind != JArray:
        raise newException(LdtkParseError, "AutoRuleDef.tileRectsIds: expected array of arrays")
      var inner: seq[int]
      for v in row:
        if v.kind != JInt:
          raise newException(LdtkParseError, "AutoRuleDef.tileRectsIds element: expected int, got " & $v.kind)
        inner.add(v.getInt)
      result.tileRectsIds.add(inner)
  if node.hasKey("tileIds") and node["tileIds"].kind == JArray:
    var ids: seq[int]
    for v in node["tileIds"]:
      if v.kind != JInt:
        raise newException(LdtkParseError, "AutoRuleDef.tileIds: expected int, got " & $v.kind)
      ids.add(v.getInt)
    result.tileIds = some(ids)

proc parseAutoLayerRuleGroup(node: JsonNode): AutoLayerRuleGroup =
  result.uid              = getField[int](node, "uid")
  result.name             = getField[string](node, "name")
  result.active           = getField[bool](node, "active")
  result.isOptional       = getField[bool](node, "isOptional")
  result.usesWizard       = getOpt[bool](node, "usesWizard").get(false)  # absent in LDtk v1.0
  result.color            = getOpt[string](node, "color")
  result.biomeRequirementMode = getOpt[int](node, "biomeRequirementMode")
  if node.hasKey("requiredBiomeValues") and node["requiredBiomeValues"].kind == JArray:
    for v in node["requiredBiomeValues"]:
      if v.kind != JString:
        raise newException(LdtkParseError, "AutoLayerRuleGroup.requiredBiomeValues: expected string, got " & $v.kind)
      result.requiredBiomeValues.add(v.getStr)
  if node.hasKey("rules") and node["rules"].kind == JArray:
    for r in node["rules"]:
      result.rules.add(parseAutoRuleDef(r))

proc parseLayerDef*(node: JsonNode): LayerDef =
  result.identifier      = getField[string](node, "identifier")
  result.uid             = getField[int](node, "uid")
  result.layerDefType    = getField[string](node, "__type")
  result.layerKind       = parseEnumField[LayerKind](result.layerDefType, "LayerDef.__type")
  result.gridSize        = getField[int](node, "gridSize")
  result.displayOpacity  = getField[float](node, "displayOpacity")
  result.inactiveOpacity = getField[float](node, "inactiveOpacity")
  result.pxOffsetX       = getField[int](node, "pxOffsetX")
  result.pxOffsetY       = getField[int](node, "pxOffsetY")
  result.guideGridHei    = getField[int](node, "guideGridHei")
  result.guideGridWid    = getField[int](node, "guideGridWid")
  result.parallaxFactorX  = getField[float](node, "parallaxFactorX")
  result.parallaxFactorY  = getField[float](node, "parallaxFactorY")
  result.parallaxScaling  = getField[bool](node, "parallaxScaling")
  # These fields were added in LDtk v1.2+ — default false for older files
  result.renderInWorldView      = getOpt[bool](node, "renderInWorldView").get(false)
  result.canSelectWhenInactive  = getOpt[bool](node, "canSelectWhenInactive").get(false)
  result.hideFieldsWhenInactive = getOpt[bool](node, "hideFieldsWhenInactive").get(false)
  result.hideInList      = getField[bool](node, "hideInList")
  result.tilePivotX      = getField[float](node, "tilePivotX")
  result.tilePivotY      = getField[float](node, "tilePivotY")
  result.tilesetDefUid         = getOpt[int](node, "tilesetDefUid")
  result.autoSourceLayerDefUid = getOpt[int](node, "autoSourceLayerDefUid")
  result.autoTilesetDefUid     = getOpt[int](node, "autoTilesetDefUid")
  result.uiColor         = getOpt[string](node, "uiColor")
  result.doc             = getOpt[string](node, "doc")
  for arrKey in ["autoRuleGroups", "intGridValues", "excludedTags", "requiredTags"]:
    if not node.hasKey(arrKey):
      raise newException(LdtkParseError, "LayerDef: missing required field: " & arrKey)
  if node["autoRuleGroups"].kind == JArray:
    for g in node["autoRuleGroups"]:
      result.autoRuleGroups.add(parseAutoLayerRuleGroup(g))
  if node["intGridValues"].kind == JArray:
    for v in node["intGridValues"]:
      result.intGridValues.add(parseIntGridValueDef(v))
  # intGridValuesGroups added in LDtk v1.4.x — absent in older files
  if node.hasKey("intGridValuesGroups") and node["intGridValuesGroups"].kind == JArray:
    for v in node["intGridValuesGroups"]:
      result.intGridValuesGroups.add(parseIntGridValueGroupDef(v))
  for tag in node["excludedTags"]:
    if tag.kind != JString:
      raise newException(LdtkParseError, "LayerDef.excludedTags: expected string, got " & $tag.kind)
    result.excludedTags.add(tag.getStr)
  for tag in node["requiredTags"]:
    if tag.kind != JString:
      raise newException(LdtkParseError, "LayerDef.requiredTags: expected string, got " & $tag.kind)
    result.requiredTags.add(tag.getStr)
  if node.hasKey("uiFilterTags") and node["uiFilterTags"].kind == JArray:
    for tag in node["uiFilterTags"]:
      if tag.kind != JString:
        raise newException(LdtkParseError, "LayerDef.uiFilterTags: expected string, got " & $tag.kind)
      result.uiFilterTags.add(tag.getStr)
