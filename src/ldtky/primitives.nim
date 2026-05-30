import std/options

type
  EntityReferenceInfos* = object
    ## Cross-reference to an entity instance identified by IID strings.
    entityIid*, layerIid*, levelIid*, worldIid*: string

  GridPoint* = object
    cx*, cy*: int  ## Cell coordinates (grid units, not pixels)

  TilesetRect* = object
    ## A rectangular region within a tileset image.
    h*, w*: int               ## Height and width in pixels
    x*, y*: int               ## Top-left corner in the tileset image (pixels)
    tilesetUid*: Option[int]  ## UID of the owning tileset; null means no tileset assigned

  TileCustomMetadata* = object
    ## Per-tile custom metadata attached to a tileset tile.
    data*: string    ## Arbitrary user-defined string payload
    tileId*: int     ## Tile identifier within the tileset

  Tile* = object
    ## A placed tile in a Tiles or AutoLayer layer instance.
    ## LDtk JSON field names are single characters; see LDtk JSON schema v1.5.3.
    a*: float        ## Alpha (0.0–1.0); LDtk emits integer 1 for fully opaque
    f*: int          ## Flip bits: bit0 = X-flip, bit1 = Y-flip
    t*: int          ## Tile ID in the source tileset
    px*: seq[int]    ## [x, y] pixel position in the layer (2 elements)
    src*: seq[int]   ## [x, y] pixel position in the tileset image (2 elements)
    d*: seq[int]     ## Tile data (format varies by layer type; may be empty)
