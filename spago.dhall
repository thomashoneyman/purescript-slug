{ name = "slug"
, dependencies =
  [ "argonaut-codecs"
  , "debug"
  , "maybe"
  , "prelude"
  , "psci-support"
  , "quickcheck"
  , "strings"
  , "test-unit"
  , "unicode"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
