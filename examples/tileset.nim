## tileset.nim — inspect tileset definitions and tile metadata.
##
## Run from the repo root:
##   nim c --mm:orc -r examples/tileset.nim tests/fixtures/labRefs.ldtk
import std/os
import std/options
import ldtky/ldtky

proc main =
  if paramCount() < 1:
    echo "usage: tileset <path/to/project.ldtk>"
    quit(1)

  let project = loadProject(paramStr(1))

  echo "Tilesets (", project.defs.tilesets.len, "):"
  for ts in project.defs.tilesets:
    echo ""
    echo "  Tileset: ", ts.identifier, " [uid=", ts.uid, "]"
    echo "    relPath: ", ts.relPath.get("(none)")
    echo "    size: ", ts.pxWid, "x", ts.pxHei, " px"
    echo "    tileGrid: ", ts.cWid, "x", ts.cHei, " cells (", ts.tileGridSize, "px each)"
    echo "    spacing: ", ts.spacing, " padding: ", ts.padding
    if ts.customData.len > 0:
      echo "    customData entries: ", ts.customData.len
      for cd in ts.customData:
        echo "      tileId=", cd.tileId, " data=", cd.data
    if ts.enumTags.len > 0:
      echo "    enumTags: ", ts.enumTags.len
    if ts.tags.len > 0:
      echo "    tags: ", ts.tags

  echo ""
  echo "Enums (", project.defs.enums.len, "):"
  for e in project.defs.enums:
    echo "  Enum: ", e.identifier, " [uid=", e.uid, "] values=", e.values.len

main()
