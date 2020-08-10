{ name = "slug"
, dependencies =
  [ "argonaut-codecs"
  , "debug"
  , "generics-rep"
  , "maybe"
  , "prelude"
  , "psci-support"
  , "quickcheck"
  , "strings"
  , "test-unit"
  , "unicode"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
