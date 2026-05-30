import unittest
import ldtky/primitives
import ldtky/enums
import ldtky/instances/layer_utils
import ldtky/errors

suite "GridPoint":
  test "construction and field access":
    let p = GridPoint(cx: 3, cy: 7)
    check p.cx == 3
    check p.cy == 7

suite "TilesetRect":
  test "construction and field access":
    let r = TilesetRect(h: 16, w: 16, x: 32, y: 64, tilesetUid: 5)
    check r.h == 16
    check r.w == 16
    check r.tilesetUid == 5

suite "flipX / flipY":
  test "flipX(0) = false":
    check flipX(0) == false

  test "flipX(1) = true (bit 0 set)":
    check flipX(1) == true

  test "flipX(2) = false (bit 0 not set)":
    check flipX(2) == false

  test "flipX(3) = true (bit 0 set)":
    check flipX(3) == true

  test "flipY(0) = false":
    check flipY(0) == false

  test "flipY(1) = false (bit 1 not set)":
    check flipY(1) == false

  test "flipY(2) = true (bit 1 set)":
    check flipY(2) == true

  test "flipY(3) = true (bit 1 set)":
    check flipY(3) == true

suite "decodeIntGridCsv":
  test "2x2 grid decodes row-major":
    let grid = decodeIntGridCsv(@[1, 2, 3, 4], 2, 2)
    check grid[0][0] == 1
    check grid[0][1] == 2
    check grid[1][0] == 3
    check grid[1][1] == 4

  test "1x4 grid (single row)":
    let grid = decodeIntGridCsv(@[10, 20, 30, 40], 4, 1)
    check grid[0][0] == 10
    check grid[0][3] == 40

  test "wrong size raises LdtkParseError":
    expect(LdtkParseError):
      discard decodeIntGridCsv(@[1, 2, 3], 2, 2)

suite "LayerKind enum":
  test "IntGrid value compares equal":
    check LayerKind.IntGrid == LayerKind.IntGrid

  test "all 4 variants are distinct":
    check LayerKind.IntGrid != LayerKind.Entities
    check LayerKind.Entities != LayerKind.Tiles
    check LayerKind.Tiles != LayerKind.AutoLayer
