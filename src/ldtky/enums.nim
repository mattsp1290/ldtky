type
  LayerKind* {.pure.} = enum
    IntGrid
    Entities
    Tiles
    AutoLayer

  WorldLayout* {.pure.} = enum
    Free
    GridVania
    LinearHorizontal
    LinearVertical

  ImageExportMode* {.pure.} = enum
    None
    OneImagePerLayer
    OneImagePerLevel
    LayersAndLevels

  IdentifierStyle* {.pure.} = enum
    Capitalize
    Uppercase
    Lowercase
    Free

  ProjectFlag* {.pure.} = enum
    DiscardPreCsvIntGrid
    ExportOldTableOfContentData
    ExportPreCsvIntGridFormat
    IgnoreBackupSuggest
    PrependIndexToLevelFileNames
    MultiWorlds
    UseMultilinesType

  AutoRuleChecker* {.pure.} = enum
    None
    Horizontal
    Vertical

  TileMode* {.pure.} = enum
    Single
    Stamp

  AllowedRefs* {.pure.} = enum
    Any
    OnlySame
    OnlyTags
    OnlySpecificEntity

  EditorDisplayMode* {.pure.} = enum
    Hidden
    ValueOnly
    NameAndValue
    EntityTile
    LevelTile
    Points
    PointStar
    PointPath
    PointPathLoop
    RadiusPx
    RadiusGrid
    ArrayCountWithLabel
    ArrayCountNoLabel
    RefLinkBetweenPivots
    RefLinkBetweenCenters

  EditorDisplayPos* {.pure.} = enum
    Above
    Center
    Beneath

  EditorLinkStyle* {.pure.} = enum
    ZigZag
    StraightArrow
    CurvedArrow
    ArrowsLine
    DashedLine

  TextLanguageMode* {.pure.} = enum
    LangPython
    LangRuby
    LangJS
    LangLua
    LangC
    LangHaxe
    LangMarkdown
    LangJson
    LangXml
    LangLog

  CustomCommandWhen* {.pure.} = enum
    Manual
    AfterLoad
    BeforeSave
    AfterSave

  LimitBehavior* {.pure.} = enum
    DiscardOldOnes
    PreventAdding
    MoveLastOne

  LimitScope* {.pure.} = enum
    PerLayer
    PerLevel
    PerWorld

  EntityRenderMode* {.pure.} = enum
    Rectangle
    Ellipse
    Tile
    Cross

  TileRenderMode* {.pure.} = enum
    Cover
    FitInside
    Repeat
    Stretch
    FullSizeCropped
    FullSizeUncropped
    NineSlice

  BgPosMode* {.pure.} = enum
    Unscaled
    Contain
    Cover
    CoverDirty
    Repeat
