## Shared internal parsing helpers used across definition and instance modules.
## Not part of the public API — import ldtky/ldtky.nim for the public surface.
import std/json
import std/strutils
import ldtky/primitives
import ldtky/json_helpers
import ldtky/errors

proc parseEnumField*[T: enum](s, ctx: string): T =
  ## Wraps `parseEnum` to re-raise `ValueError` as `LdtkParseError`.
  try: parseEnum[T](s)
  except ValueError:
    raise newException(LdtkParseError, ctx & ": unknown enum value: " & s)

proc parseTilesetRect*(node: JsonNode): TilesetRect =
  ## Parse a `TilesetRect` from a JSON object with h/w/x/y/tilesetUid keys.
  if node.kind != JObject:
    raise newException(LdtkParseError, "TilesetRect: expected object, got " & $node.kind)
  result.h          = getField[int](node, "h")
  result.w          = getField[int](node, "w")
  result.x          = getField[int](node, "x")
  result.y          = getField[int](node, "y")
  result.tilesetUid = getField[int](node, "tilesetUid")

proc parseEntityReferenceInfos*(node: JsonNode): EntityReferenceInfos =
  ## Parse an `EntityReferenceInfos` from a JSON object.
  if node.kind != JObject:
    raise newException(LdtkParseError, "EntityReferenceInfos: expected object, got " & $node.kind)
  result.entityIid = getField[string](node, "entityIid")
  result.layerIid  = getField[string](node, "layerIid")
  result.levelIid  = getField[string](node, "levelIid")
  result.worldIid  = getField[string](node, "worldIid")
