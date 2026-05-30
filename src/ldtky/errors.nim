type
  LdtkParseError* = object of CatchableError
    ## Raised when an `.ldtk` project file is malformed or violates the expected schema.
