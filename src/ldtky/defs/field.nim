import std/json
import std/options
import std/strutils
import ldtky/enums
import ldtky/json_helpers
import ldtky/errors

type
  FieldDef* = object
    ## A field definition attached to an entity or level.
    ## `fieldDefType` is the human-readable type string from `__type` (e.g. "Int", "LocalEnum.Foo").
    ## `internalType` is the raw LDtk internal type string from the `type` key (e.g. "F_EntityRef").
    identifier*: string
    uid*: int
    fieldDefType*: string
    internalType*: string
    isArray*: bool
    canBeNull*: bool
    allowOutOfLevelRef*: bool
    symmetricalRef*: bool
    autoChainRef*: bool
    useForSmartColor*: bool
    editorAlwaysShow*: bool
    editorShowInWorld*: bool
    editorCutLongValues*: bool
    allowedRefs*: AllowedRefs
    allowedRefsEntityUid*: Option[int]
    allowedRefTags*: seq[string]
    tilesetUid*: Option[int]
    min*, max*: Option[float]
    arrayMinLength*, arrayMaxLength*: Option[int]
    doc*: Option[string]
    regex*: Option[string]
    defaultOverride*: Option[JsonNode]
    textLanguageMode*: Option[TextLanguageMode]
    editorDisplayMode*: EditorDisplayMode
    editorDisplayPos*: EditorDisplayPos
    editorLinkStyle*: EditorLinkStyle
    editorTextSuffix*, editorTextPrefix*: Option[string]
    exportToToc*: Option[bool]
    searchable*: Option[bool]

proc parseFieldDef*(node: JsonNode): FieldDef =
  result.identifier          = getField[string](node, "identifier")
  result.uid                 = getField[int](node, "uid")
  # __type requires manual access (double-underscore key)
  result.fieldDefType = node["__type"].getStr
  result.internalType        = getField[string](node, "type")
  result.isArray             = getField[bool](node, "isArray")
  result.canBeNull           = getField[bool](node, "canBeNull")
  result.allowOutOfLevelRef  = getField[bool](node, "allowOutOfLevelRef")
  result.symmetricalRef      = getField[bool](node, "symmetricalRef")
  result.autoChainRef        = getField[bool](node, "autoChainRef")
  result.useForSmartColor    = getField[bool](node, "useForSmartColor")
  result.editorAlwaysShow    = getField[bool](node, "editorAlwaysShow")
  result.editorShowInWorld   = getField[bool](node, "editorShowInWorld")
  result.editorCutLongValues = getField[bool](node, "editorCutLongValues")
  result.tilesetUid          = getOpt[int](node, "tilesetUid")
  result.min                 = getOpt[float](node, "min")
  result.max                 = getOpt[float](node, "max")
  result.arrayMinLength      = getOpt[int](node, "arrayMinLength")
  result.arrayMaxLength      = getOpt[int](node, "arrayMaxLength")
  result.doc                 = getOpt[string](node, "doc")
  result.regex               = getOpt[string](node, "regex")
  result.allowedRefsEntityUid = getOpt[int](node, "allowedRefsEntityUid")
  result.editorTextSuffix    = getOpt[string](node, "editorTextSuffix")
  result.editorTextPrefix    = getOpt[string](node, "editorTextPrefix")
  result.exportToToc         = getOpt[bool](node, "exportToToc")
  result.searchable          = getOpt[bool](node, "searchable")
  if node.hasKey("defaultOverride") and node["defaultOverride"].kind != JNull:
    result.defaultOverride = some(node["defaultOverride"])
  result.allowedRefs = parseEnum[AllowedRefs](getField[string](node, "allowedRefs"))
  result.editorDisplayMode = parseEnum[EditorDisplayMode](getField[string](node, "editorDisplayMode"))
  result.editorDisplayPos  = parseEnum[EditorDisplayPos](getField[string](node, "editorDisplayPos"))
  result.editorLinkStyle   = parseEnum[EditorLinkStyle](getField[string](node, "editorLinkStyle"))
  let tlmStr = getOpt[string](node, "textLanguageMode")
  if tlmStr.isSome:
    result.textLanguageMode = some(parseEnum[TextLanguageMode](tlmStr.get))
  if node.hasKey("allowedRefTags") and node["allowedRefTags"].kind == JArray:
    for tag in node["allowedRefTags"]:
      if tag.kind != JString:
        raise newException(LdtkParseError, "FieldDef.allowedRefTags: expected string, got " & $tag.kind)
      result.allowedRefTags.add(tag.getStr)
