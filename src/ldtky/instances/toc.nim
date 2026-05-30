import std/json
import std/options
import std/strutils
import ldtky/enums
import ldtky/primitives
import ldtky/json_helpers
import ldtky/errors
import ldtky/parse_utils

type
  TocInstanceData* = object
    ## Per-instance data stored in a table-of-contents entry.
    worldX*, worldY*: int
    heiPx*, widPx*: int
    iids*: Option[EntityReferenceInfos]  ## absent in some LDtk versions
    fields*: Option[JsonNode]             ## raw field data; none when key absent

  TableOfContentEntry* = object
    ## Entry for one entity type in the project table of contents.
    identifier*: string
    instancesData*: seq[TocInstanceData]

  CustomCommand* = object
    ## A custom external command defined in the project.
    ## `execWhen` corresponds to the JSON "when" key (`when` is reserved in Nim).
    command*: string
    execWhen*: CustomCommandWhen

proc parseTocInstanceData(node: JsonNode): TocInstanceData =
  if node.kind != JObject:
    raise newException(LdtkParseError, "TocInstanceData: expected object, got " & $node.kind)
  result.worldX = getField[int](node, "worldX")
  result.worldY = getField[int](node, "worldY")
  result.heiPx  = getField[int](node, "heiPx")
  result.widPx  = getField[int](node, "widPx")
  if node.hasKey("iids") and node["iids"].kind == JObject:
    result.iids = some(parseEntityReferenceInfos(node["iids"]))
  if node.hasKey("fields") and node["fields"].kind != JNull:
    result.fields = some(node["fields"])

proc parseTableOfContentEntry*(node: JsonNode): TableOfContentEntry =
  result.identifier = getField[string](node, "identifier")
  if node.hasKey("instancesData") and node["instancesData"].kind == JArray:
    for item in node["instancesData"]:
      result.instancesData.add(parseTocInstanceData(item))

proc parseCustomCommand*(node: JsonNode): CustomCommand =
  result.command  = getField[string](node, "command")
  result.execWhen = parseEnumField[CustomCommandWhen](
    getField[string](node, "when"), "CustomCommand.when")
