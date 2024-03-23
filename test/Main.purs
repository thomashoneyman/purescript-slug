module Test.Main where

import Prelude

import Data.Array (all, any, elem)
import Data.Array.Partial as AP
import Data.CodePoint.Unicode (isAlphaNum, isLatin1, isUpper)
import Data.Maybe (Maybe(..), fromJust, isJust, isNothing)
import Data.Maybe as Maybe
import Data.String as String
import Data.String.CodePoints (toCodePointArray, codePointFromChar)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Partial.Unsafe (unsafePartial)
import Slug (Slug, Options)
import Slug as Slug
import Test.QuickCheck (class Arbitrary, Result(..), arbitrary, assertEquals, assertNotEquals)
import Test.QuickCheck.Gen (suchThat)
import Test.Slugify as Slugify
import Test.Spec (describe, it)
import Test.Spec.QuickCheck (quickCheck')
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (runSpec)

main :: Effect Unit
main = launchAff_ $ runSpec [ consoleReporter ] do
  describe "Slug Properties" do
    it "Cannot be empty" do
      quickCheck' 500 $ \(Slug' slug) ->
        Slug.toString slug `assertNotEquals` ""

    it "Contains only dashes and alphanumeric characters" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let f x = isAlphaNum x || x == codePointFromChar '-'
        all f (toCodePointArray (Slug.toString slug)) `assertEquals` true

    it "Does not begin with a dash" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let first = unsafePartial (AP.head (toCodePointArray (Slug.toString slug)))
        first `assertNotEquals` codePointFromChar '-'

    it "Does not end with a dash" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let last = unsafePartial (AP.last (toCodePointArray (Slug.toString slug)))
        last `assertNotEquals` codePointFromChar '-'

    it "Does not contain empty words between dashes" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let arr = String.split (Pattern "-") (Slug.toString slug)
        any String.null arr `assertEquals` false

    it "Does not contain any uppercase characters" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let arr = toCodePointArray $ Slug.toString slug
        any isUpper arr `assertEquals` false

  describe "Semigroup Instance" do
    it "Append always creates a valid slug" do
      quickCheck' 100 $ \(Slug' x) (Slug' y) -> do
        let
          slug = Slug.toString (x <> y)
          slug' = Slug.toString <$> Slug.parse slug
        slug' `assertEquals` pure slug

  describe "Generate Slugs" do
    it "Generated slugs are idempotent" do
      quickCheck' 500 $ \x -> do
        let
          f = Slug.generate
          g = Slug.generate >=> Slug.generate <<< Slug.toString
        f x `assertEquals` g x

  describe "Parse Slugs" do
    it "Slug parses successfully on valid input" do
      quickCheck' 500 $ \(Slug' slug) -> do
        Slug.parse (Slug.toString slug) `assertEquals` pure slug

    it "Slug fails to parse bad input" do
      quickCheck' 500 $ \(BadInput str) -> do
        Slug.parse str `assertEquals` Nothing

  describe "Truncate Slugs" do
    it "Truncated slugs fail when given a non-positive length" do
      quickCheck' 500 $ \(NonPositiveInt n) (Slug' slug) -> do
        Slug.truncate n slug `assertEquals` Nothing

    it "Truncated slugs succeed with (n) or (n - 1) when given a positive length" do
      quickCheck' 500 $ \(PositiveInt n) (Slug' slug) -> do
        let startLen = String.length (Slug.toString slug)
        case Slug.truncate n slug of
          -- truncation should always produce a valid slug
          Nothing -> true `assertEquals` false
          Just slug' -> do
            let x = String.length (Slug.toString slug')
            case n > startLen of
              -- a truncation longer than the string should not affect length
              true -> (x == startLen) `assertEquals` true
              -- a truncation less than the string should produce `n` (or `n - 1`
              -- if there is a trailing dash)
              _ -> (x == n || x == n - 1) `assertEquals` true

  describe "Generate with Options" do
    it "Generated slugs are idempotent" do
      quickCheck' 500 $ \(Tuple str (Options' opts)) -> do
        let
          f = Slug.generateWithOptions opts
          g = Slug.generateWithOptions opts >=> Slug.generateWithOptions opts <<< Slug.toString
        f str `assertEquals` g str

  describe "Parse Slugs with Options" do
    it "Slug parses successfully on valid input" do
      quickCheck' 500 $ \(Tuple str (Options' opts)) -> do
        case Slug.generateWithOptions opts str of
          Just slug -> do
            Slug.parseWithOptions opts (Slug.toString slug) `assertEquals` pure slug
          Nothing -> Success

    it "Can parse slugify-generated slugs" do
      let
        slugifyOpts = Slug.defaultOptions { lowerCase = false, filter = isLatin1 }
        parse = Slug.parseWithOptions slugifyOpts
      quickCheck' 500 $ \str -> do
        let
          slugifySlug = Slugify.slugify str
          maybeSlug = Slug.toString <$> parse slugifySlug
          -- NOTE: `slugify` can return an empty string, so to test
          -- compatibility, we default to empty string in case of
          -- parse failure
          slug = Maybe.fromMaybe "" maybeSlug
        slug `assertEquals` slugifySlug

----------
-- Arbitrary instances

-- In order to avoid unnecessary dependencies and instances in
-- the main `Slug` source
newtype Slug' = Slug' Slug

newtype Options' = Options' Options

-- Only generate valid slugs to test properties
instance arbitrarySlug' :: Arbitrary Slug' where
  arbitrary = do
    let slug = ((map Slug' <<< Slug.generate) <$> arbitrary) `suchThat` isJust
    slug <#> \x -> unsafePartial (fromJust x)

-- Only generate valid slugs to test properties
instance arbitraryOptions' :: Arbitrary Options' where
  arbitrary = do
    replaceSpaceWith <- arbitrary
    filter <- flip elem <<< toCodePointArray <$> arbitrary
    lowerCase <- arbitrary
    pure $ Options' { replaceSpaceWith, filter, lowerCase }

-- In order to test parsing fails appropriately
newtype BadInput = BadInput String

-- Only generate *invalid* string slugs to test properties
instance arbitraryBadInput :: Arbitrary BadInput where
  arbitrary = BadInput <$> arbitrary `suchThat` (isNothing <<< Slug.generate)

-- In order to test truncation fails appropriately
newtype NonPositiveInt = NonPositiveInt Int

instance arbitraryNonPositiveInt :: Arbitrary NonPositiveInt where
  arbitrary = NonPositiveInt <$> arbitrary `suchThat` \n -> n < 1

-- In order to test truncation succeeds appropriately
newtype PositiveInt = PositiveInt Int

instance arbitraryPositiveInt :: Arbitrary PositiveInt where
  arbitrary = PositiveInt <$> arbitrary `suchThat` \n -> n > 0
