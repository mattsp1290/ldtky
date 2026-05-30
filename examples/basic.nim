## basic.nim — load a project and iterate over its levels and layers.
##
## Run from the repo root:
##   nim c --mm:orc -r examples/basic.nim tests/fixtures/grassAndDirt.ldtk
import std/os
import std/options
import ldtky/ldtky

proc main =
  if paramCount() < 1:
    echo "usage: basic <path/to/project.ldtk>"
    quit(1)

  let project = loadProject(paramStr(1))
  echo "Project: ", project.bgColor
  echo "  jsonVersion: ", project.jsonVersion
  echo "  externalLevels: ", project.externalLevels
  echo "  worlds: ", project.worlds.len
  echo "  levels: ", project.levels.len

  let levels = if project.worlds.len > 0:
    var all: seq[Level]
    for w in project.worlds:
      all.add(w.levels)
    all
  else:
    project.levels

  for lv in levels:
    echo ""
    echo "Level: ", lv.identifier, " (", lv.pxWid, "x", lv.pxHei, " px)"
    echo "  worldX=", lv.worldX, " worldY=", lv.worldY
    if lv.layerInstances.isNone:
      echo "  [external — no layer data loaded]"
      continue
    for layer in lv.layerInstances.get:
      echo "  Layer: ", layer.identifier, " [", layer.layerType, "]"
      echo "    grid=", layer.cWid, "x", layer.cHei, " gridSize=", layer.gridSize
      echo "    entities=", layer.entityInstances.len,
           " tiles=", layer.gridTiles.len + layer.autoLayerTiles.len,
           " intGridCsv=", layer.intGridCsv.len

main()
