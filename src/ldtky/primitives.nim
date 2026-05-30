type
  GridPoint* = object
    cx*, cy*: int

  TilesetRect* = object
    h*, w*, x*, y*, tilesetUid*: int

  TileCustomMetadata* = object
    data*: string
    tileId*: int

  Tile* = object
    a*: float
    f*, t*: int
    px*, src*, d*: seq[int]
