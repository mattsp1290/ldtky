import std/json
import std/options
import ldtky/errors

proc getStr*(node: JsonNode, key: string): string =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "missing required field: " & key)
  let v = node[key]
  if v.kind != JString:
    raise newException(LdtkParseError, "field " & key & ": expected string, got " & $v.kind)
  v.getStr

proc getInt*(node: JsonNode, key: string): int =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "missing required field: " & key)
  let v = node[key]
  if v.kind != JInt:
    raise newException(LdtkParseError, "field " & key & ": expected int, got " & $v.kind)
  v.getInt

proc getFloat*(node: JsonNode, key: string): float =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "missing required field: " & key)
  let v = node[key]
  case v.kind
  of JFloat: v.getFloat
  of JInt:   v.getInt.float
  else:
    raise newException(LdtkParseError, "field " & key & ": expected float, got " & $v.kind)

proc getBool*(node: JsonNode, key: string): bool =
  if not node.hasKey(key):
    raise newException(LdtkParseError, "missing required field: " & key)
  let v = node[key]
  if v.kind != JBool:
    raise newException(LdtkParseError, "field " & key & ": expected bool, got " & $v.kind)
  v.getBool

proc getOptStr*(node: JsonNode, key: string): Option[string] =
  if not node.hasKey(key): return none(string)
  let v = node[key]
  if v.kind == JNull: return none(string)
  if v.kind != JString:
    raise newException(LdtkParseError, "field " & key & ": expected string or null, got " & $v.kind)
  some(v.getStr)

proc getOptInt*(node: JsonNode, key: string): Option[int] =
  if not node.hasKey(key): return none(int)
  let v = node[key]
  if v.kind == JNull: return none(int)
  if v.kind != JInt:
    raise newException(LdtkParseError, "field " & key & ": expected int or null, got " & $v.kind)
  some(v.getInt)

proc getOptFloat*(node: JsonNode, key: string): Option[float] =
  if not node.hasKey(key): return none(float)
  let v = node[key]
  if v.kind == JNull: return none(float)
  case v.kind
  of JFloat: some(v.getFloat)
  of JInt:   some(v.getInt.float)
  else:
    raise newException(LdtkParseError, "field " & key & ": expected float or null, got " & $v.kind)

proc getOptBool*(node: JsonNode, key: string): Option[bool] =
  if not node.hasKey(key): return none(bool)
  let v = node[key]
  if v.kind == JNull: return none(bool)
  if v.kind != JBool:
    raise newException(LdtkParseError, "field " & key & ": expected bool or null, got " & $v.kind)
  some(v.getBool)

proc getField*[T](node: JsonNode, key: string): T =
  ## Generic required field extractor. Raises LdtkParseError on missing or wrong type.
  when T is string:  getStr(node, key)
  elif T is int:     getInt(node, key)
  elif T is float:   getFloat(node, key)
  elif T is bool:    getBool(node, key)
  else: {.error: "getField[T]: unsupported type " & $T.}

proc getOpt*[T](node: JsonNode, key: string): Option[T] =
  ## Generic optional field extractor. Returns none(T) for missing or null.
  when T is string:  getOptStr(node, key)
  elif T is int:     getOptInt(node, key)
  elif T is float:   getOptFloat(node, key)
  elif T is bool:    getOptBool(node, key)
  else: {.error: "getOpt[T]: unsupported type " & $T.}
