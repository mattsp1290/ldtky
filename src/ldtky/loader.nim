import std/json
import std/os
import std/options
import ldtky/project
import ldtky/instances/layer
import ldtky/instances/level
import ldtky/errors

proc readLdtkFile(path: string): JsonNode =
  ## Read and parse a JSON file, wrapping all stdlib exceptions as LdtkParseError.
  try: parseFile(path)
  except CatchableError as e:
    raise newException(LdtkParseError, "failed to read " & path & ": " & e.msg)

proc loadExternalLevels*(project: var LdtkJsonRoot, projectDir: string) =
  ## Populate `layerInstances` for levels that have `externalRelPath` set.
  ## Only called when `project.externalLevels` is true.
  ## Reads `.ldtkl` files relative to `projectDir` and injects `layerInstances`
  ## into each Level ref in-place.
  if not project.externalLevels:
    return

  proc injectLayers(levels: var seq[Level], dir: string) =
    for lv in levels.mitems:
      if lv.externalRelPath.isNone:
        continue
      let ldtklPath = dir / lv.externalRelPath.get
      if not fileExists(ldtklPath):
        raise newException(LdtkParseError,
          "external level file not found: " & ldtklPath)
      let ldtklData = readLdtkFile(ldtklPath)
      # .ldtkl files contain a single Level JSON object
      lv.layerInstances = some(newSeq[LayerInstance]())
      if ldtklData.hasKey("layerInstances") and ldtklData["layerInstances"].kind == JArray:
        var layers: seq[LayerInstance]
        for li in ldtklData["layerInstances"]:
          layers.add(parseLayerInstance(li))
        lv.layerInstances = some(layers)

  injectLayers(project.levels, projectDir)
  for w in project.worlds.mitems:
    injectLayers(w.levels, projectDir)

proc loadProject*(path: string): LdtkJsonRoot =
  ## Load and parse a `.ldtk` project file.
  ## If `externalLevels` is true, automatically loads `.ldtkl` sidecar files
  ## from the same directory, populating `layerInstances` for all levels.
  ## Raises `LdtkParseError` on missing file, malformed JSON, or parse failure.
  if not fileExists(path):
    raise newException(LdtkParseError, "project file not found: " & path)
  let data = readLdtkFile(path)
  result = parseProject(data)
  if result.externalLevels:
    loadExternalLevels(result, parentDir(path))
