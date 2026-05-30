import std/json
import std/options
import ldtky/errors

# Private typed helpers. Named to avoid colliding with std/json's same-signature
# getStr/getInt/getFloat/getBool procs. Callers use getField[T] and getOpt[T].

proc strField(node: JsonNode, key: string): string =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "missing required field: " & key)
  let v = node[key]
  if v.kind != JString:
    raise newException(LdtkParseError, "field " & key & ": expected string, got " & $v.kind)
  v.getStr

proc intField(node: JsonNode, key: string): int =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "missing required field: " & key)
  let v = node[key]
  if v.kind != JInt:
    raise newException(LdtkParseError, "field " & key & ": expected int, got " & $v.kind)
  v.getInt

proc floatField(node: JsonNode, key: string): float =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "missing required field: " & key)
  let v = node[key]
  # LDtk emits integer JSON values for float fields (e.g. Tile.a = 1, not 1.0).
  # Accept JInt as well as JFloat. The reverse (JFloat for an int field) is not accepted.
  case v.kind
  of JFloat: v.getFloat
  of JInt:   v.getInt.float
  else:
    raise newException(LdtkParseError, "field " & key & ": expected float, got " & $v.kind)

proc boolField(node: JsonNode, key: string): bool =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "missing required field: " & key)
  let v = node[key]
  if v.kind != JBool:
    raise newException(LdtkParseError, "field " & key & ": expected bool, got " & $v.kind)
  v.getBool

proc optStrField(node: JsonNode, key: string): Option[string] =
  if not node.hasKey(key): return none(string)
  let v = node[key]
  if v.kind == JNull: return none(string)
  if v.kind != JString:
    raise newException(LdtkParseError, "field " & key & ": expected string or null, got " & $v.kind)
  some(v.getStr)

proc optIntField(node: JsonNode, key: string): Option[int] =
  if not node.hasKey(key): return none(int)
  let v = node[key]
  if v.kind == JNull: return none(int)
  if v.kind != JInt:
    raise newException(LdtkParseError, "field " & key & ": expected int or null, got " & $v.kind)
  some(v.getInt)

proc optFloatField(node: JsonNode, key: string): Option[float] =
  if not node.hasKey(key): return none(float)
  let v = node[key]
  if v.kind == JNull: return none(float)
  case v.kind
  of JFloat: some(v.getFloat)
  of JInt:   some(v.getInt.float)
  else:
    raise newException(LdtkParseError, "field " & key & ": expected float or null, got " & $v.kind)

proc optBoolField(node: JsonNode, key: string): Option[bool] =
  if not node.hasKey(key): return none(bool)
  let v = node[key]
  if v.kind == JNull: return none(bool)
  if v.kind != JBool:
    raise newException(LdtkParseError, "field " & key & ": expected bool or null, got " & $v.kind)
  some(v.getBool)

proc getField*[T](node: JsonNode, key: string): T =
  ## Extract a required field from a JsonNode, raising LdtkParseError on
  ## missing or wrong-type. Supports string, int, float, bool.
  when T is string:  strField(node, key)
  elif T is int:     intField(node, key)
  elif T is float:   floatField(node, key)
  elif T is bool:    boolField(node, key)
  else: {.error: "getField[T]: unsupported type " & $T.}

proc getOpt*[T](node: JsonNode, key: string): Option[T] =
  ## Extract an optional field from a JsonNode. Returns none(T) for missing or
  ## null values. Raises LdtkParseError if the key is present but has the wrong type.
  when T is string:  optStrField(node, key)
  elif T is int:     optIntField(node, key)
  elif T is float:   optFloatField(node, key)
  elif T is bool:    optBoolField(node, key)
  else: {.error: "getOpt[T]: unsupported type " & $T.}
