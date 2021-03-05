{ name = "slug"
, dependencies =
  [ "argonaut-codecs"
  , "maybe"
  , "prelude"
  , "strings"
  , "unicode"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
