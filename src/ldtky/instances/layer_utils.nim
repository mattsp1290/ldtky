import ldtky/errors

proc flipX*(f: int): bool =
  ## True when the tile's X-flip bit is set (bit 0 of the `f` field).
  (f and 1) != 0

proc flipY*(f: int): bool =
  ## True when the tile's Y-flip bit is set (bit 1 of the `f` field).
  (f and 2) != 0

proc tileCoordId*(x, y, cWid: int): int =
  ## Convert 2D tile coordinates to a flat index: `y * cWid + x`.
  y * cWid + x

proc decodeIntGridCsv*(csv: seq[int], cWid, cHei: int): seq[seq[int]] =
  ## Map a flat intGridCsv array to a 2D grid[row][col].
  ## `cWid` and `cHei` are the layer cell dimensions (from `__cWid` / `__cHei`).
  let expected = cWid * cHei
  if csv.len != expected:
    raise newException(LdtkParseError,
      "intGridCsv length " & $csv.len & " != cWid*cHei (" & $cWid & "*" & $cHei & "=" & $expected & ")")
  result = newSeq[seq[int]](cHei)
  for row in 0 ..< cHei:
    result[row] = newSeq[int](cWid)
    for col in 0 ..< cWid:
      result[row][col] = csv[row * cWid + col]
