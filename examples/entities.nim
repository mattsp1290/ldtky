## entities.nim — iterate entity instances and their field values.
##
## Run from the repo root:
##   nim c --mm:orc -r examples/entities.nim tests/fixtures/labRefs.ldtk
import std/os
import std/options
import ldtky/ldtky

proc printFieldValue(v: FieldValue) =
  case v.kind
  of fkInt:       echo "Int(", v.intVal, ")"
  of fkFloat:     echo "Float(", v.floatVal, ")"
  of fkBool:      echo "Bool(", v.boolVal, ")"
  of fkString:    echo "String(", v.strVal, ")"
  of fkColor:     echo "Color(", v.colorVal, ")"
  of fkPoint:     echo "Point(", v.pointVal.cx, ",", v.pointVal.cy, ")"
  of fkEnum:      echo "Enum(", v.enumVal, ")"
  of fkEntityRef: echo "EntityRef(", v.entityRefVal.entityIid, ")"
  of fkTile:      echo "Tile(", v.tileVal.tilesetUid, ")"
  of fkIntArray:  echo "IntArray[", v.intArr.len, "]"
  of fkFloatArray: echo "FloatArray[", v.floatArr.len, "]"
  of fkBoolArray: echo "BoolArray[", v.boolArr.len, "]"
  of fkStringArray: echo "StringArray[", v.strArr.len, "]"
  of fkColorArray: echo "ColorArray[", v.colorArr.len, "]"
  of fkPointArray: echo "PointArray[", v.pointArr.len, "]"
  of fkTileArray: echo "TileArray[", v.tileArr.len, "]"
  of fkEntityRefArray: echo "EntityRefArray[", v.entityRefArr.len, "]"
  of fkEnumArray: echo "EnumArray[", v.enumArr.len, "]"

proc main =
  if paramCount() < 1:
    echo "usage: entities <path/to/project.ldtk>"
    quit(1)

  let project = loadProject(paramStr(1))
  var entityCount = 0

  let levels = if project.worlds.len > 0:
    var all: seq[Level]
    for w in project.worlds:
      all.add(w.levels)
    all
  else:
    project.levels

  for lv in levels:
    if lv.layerInstances.isNone: continue
    for layer in lv.layerInstances.get:
      for entity in layer.entityInstances:
        inc entityCount
        echo "Entity: ", entity.identifier, " [", entity.iid, "]"
        echo "  px=", entity.px, " size=", entity.width, "x", entity.height
        for fi in entity.fieldInstances:
          echo "  Field: ", fi.identifier, " (", fi.fieldType, ") = "
          if fi.value.isNone: echo "    <null>"
          else: printFieldValue(fi.value.get)

  echo ""
  echo "Total entities: ", entityCount

main()
