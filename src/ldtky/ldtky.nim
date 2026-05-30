## ldtky — pure-Nim library for loading and parsing LDtk project files.
##
## Primary entry point: `loadProject(path)` returns an `LdtkJsonRoot`.
##
## LDtk JSON format v1.5.3 target. Files from earlier versions (v1.0.0+) load
## with graceful defaults; a warning is emitted to stderr when the jsonVersion
## field differs from the supported version.

import ldtky/errors;            export errors
import ldtky/enums;             export enums
import ldtky/primitives;        export primitives
import ldtky/field_value;       export field_value
import ldtky/json_helpers;      export json_helpers
import ldtky/defs;              export defs
import ldtky/instances/layer_utils; export layer_utils
import ldtky/instances/field;   export field
import ldtky/instances/entity;  export entity
import ldtky/instances/layer;   export layer
import ldtky/instances/level;   export level
import ldtky/instances/world;   export world
import ldtky/instances/toc;     export toc
import ldtky/project;           export project
import ldtky/loader;            export loader
