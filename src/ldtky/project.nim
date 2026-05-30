import std/json
import std/options
import std/strutils
import ldtky/enums
import ldtky/defs
import ldtky/instances/level
import ldtky/instances/world
import ldtky/instances/toc
import ldtky/json_helpers
import ldtky/parse_utils
import ldtky/errors

const SupportedVersion* = "1.5.3"

type
  LdtkJsonRoot* = object
    ## The root object of a parsed `.ldtk` project file.
    ## `worlds` is empty in single-world projects; `levels` is empty in multi-world.
    jsonVersion*: string
    iid*: string
    appBuildId*: float
    nextUid*: int
    bgColor*: string
    externalLevels*: bool
    defaultGridSize*: int
    defaultLevelHeight*, defaultLevelWidth*: int
    defaultEntityHeight*, defaultEntityWidth*: int
    defaultPivotX*, defaultPivotY*: float
    defaultLevelBgColor*: string
    backupLimit*: int
    backupOnSave*: bool
    backupRelPath*: Option[string]
    exportLevelBg*: bool
    exportTiled*: bool
    minifyJson*: bool
    simplifiedExport*: bool
    dummyWorldIid*: string
    tutorialDesc*: Option[string]
    levelNamePattern*: string
    pngFilePattern*: Option[string]
    identifierStyle*: IdentifierStyle
    imageExportMode*: ImageExportMode
    worldLayout*: Option[WorldLayout]
    worldGridHeight*, worldGridWidth*: int
    flags*: seq[string]
    defs*: Definitions
    levels*: seq[Level]
    worlds*: seq[World]
    toc*: seq[TableOfContentEntry]
    customCommands*: seq[CustomCommand]

proc parseProject*(node: JsonNode): LdtkJsonRoot =
  result.jsonVersion = getField[string](node, "jsonVersion")
  if result.jsonVersion != SupportedVersion:
    stderr.writeLine("ldtky warning: jsonVersion " & result.jsonVersion &
      " != supported " & SupportedVersion & " — parsing continues")
  result.iid              = getOpt[string](node, "iid").get("")
  result.appBuildId       = getOpt[float](node, "appBuildId").get(0.0)
  result.nextUid          = getField[int](node, "nextUid")
  result.bgColor          = getField[string](node, "bgColor")
  result.externalLevels   = getField[bool](node, "externalLevels")
  result.defaultGridSize  = getField[int](node, "defaultGridSize")
  result.defaultLevelHeight = getOpt[int](node, "defaultLevelHeight").get(0)
  result.defaultLevelWidth  = getOpt[int](node, "defaultLevelWidth").get(0)
  result.defaultEntityHeight = getOpt[int](node, "defaultEntityHeight").get(0)
  result.defaultEntityWidth  = getOpt[int](node, "defaultEntityWidth").get(0)
  result.defaultPivotX    = getField[float](node, "defaultPivotX")
  result.defaultPivotY    = getField[float](node, "defaultPivotY")
  result.defaultLevelBgColor = getField[string](node, "defaultLevelBgColor")
  result.backupLimit      = getField[int](node, "backupLimit")
  result.backupOnSave     = getField[bool](node, "backupOnSave")
  result.backupRelPath    = getOpt[string](node, "backupRelPath")
  result.exportLevelBg    = getOpt[bool](node, "exportLevelBg").get(false)
  result.exportTiled      = getField[bool](node, "exportTiled")
  result.minifyJson       = getField[bool](node, "minifyJson")
  result.simplifiedExport = getOpt[bool](node, "simplifiedExport").get(false)
  result.dummyWorldIid    = getOpt[string](node, "dummyWorldIid").get("")
  result.tutorialDesc     = getOpt[string](node, "tutorialDesc")
  result.levelNamePattern = getField[string](node, "levelNamePattern")
  result.pngFilePattern   = getOpt[string](node, "pngFilePattern")
  result.worldGridHeight  = getOpt[int](node, "worldGridHeight").get(0)
  result.worldGridWidth   = getOpt[int](node, "worldGridWidth").get(0)
  result.identifierStyle = parseEnumField[IdentifierStyle](
    getField[string](node, "identifierStyle"), "LdtkJsonRoot.identifierStyle")
  result.imageExportMode = parseEnumField[ImageExportMode](
    getField[string](node, "imageExportMode"), "LdtkJsonRoot.imageExportMode")
  let wlStr = getOpt[string](node, "worldLayout")
  if wlStr.isSome:
    result.worldLayout = some(parseEnumField[WorldLayout](wlStr.get, "LdtkJsonRoot.worldLayout"))
  if node.hasKey("flags") and node["flags"].kind == JArray:
    for f in node["flags"]:
      if f.kind == JString:
        result.flags.add(f.getStr)
  if not node.hasKey("defs"):
    raise newException(LdtkParseError, "LdtkJsonRoot: missing required 'defs' field")
  result.defs = parseDefinitions(node["defs"])
  if node.hasKey("levels") and node["levels"].kind == JArray:
    for lv in node["levels"]:
      result.levels.add(parseLevel(lv))
  if node.hasKey("worlds") and node["worlds"].kind == JArray:
    for w in node["worlds"]:
      result.worlds.add(parseWorld(w))
  if node.hasKey("toc") and node["toc"].kind == JArray:
    for entry in node["toc"]:
      result.toc.add(parseTableOfContentEntry(entry))
  if node.hasKey("customCommands") and node["customCommands"].kind == JArray:
    for cmd in node["customCommands"]:
      result.customCommands.add(parseCustomCommand(cmd))
