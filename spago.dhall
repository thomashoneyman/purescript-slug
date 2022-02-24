{ name = "slug"
, dependencies =
  [ "argonaut-codecs"
  , "arrays"
  , "either"
  , "maybe"
  , "prelude"
  , "strings"
  , "unicode"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
