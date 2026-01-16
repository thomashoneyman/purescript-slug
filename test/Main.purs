module Test.Main where

import Prelude

import Data.Array (all, any)
import Data.Array.NonEmpty (cons')
import Data.Array.Partial as AP
import Data.CodePoint.Unicode (isAlphaNum, isLatin1, isUpper)
import Data.Maybe (Maybe(..), fromJust, isJust, isNothing)
import Data.String as String
import Data.String.CodePoints as CodePoints
import Data.String.CodePoints (toCodePointArray, codePointFromChar)
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Partial.Unsafe (unsafePartial)
import Slug (Slug, Options)
import Slug as Slug
import Test.QuickCheck (class Arbitrary, arbitrary, assertEquals, assertNotEquals)
import Test.QuickCheck.Gen (elements, suchThat)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
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

  describe "Generate Slugs with Options" do
    it "Generated slugs are idempotent" do
      quickCheck' 500 \(Options' options) x -> do
        let
          generate = Slug.generateWithOptions options
          f = generate
          g = generate >=> generate <<< Slug.toString
        f x `assertEquals` g x

  describe "Parse Slugs with Options" do
    it "Slug parses successfully on valid input" do
      quickCheck' 500 \(SlugWithOptions { slug, options }) -> do
        Slug.parseWithOptions options (Slug.toString slug) `assertEquals` pure slug

    it "Slug fails to parse bad input" do
      quickCheck' 500 \(BadInputWithOptions { input, options }) -> do
        Slug.parseWithOptions options input `assertEquals` Nothing

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

  describe "Slug Unit Tests" do
    describe "Slug.generate" do
      it "Fails on input with all-special characters (as documented)" do
        Slug.generate "¬¬¬{}¬¬¬" `shouldEqual` Nothing

      it "Succeeds on article title example (as documented)" do
        map Slug.toString (Slug.generate "My article title!") `shouldEqual` Just "my-article-title"

      it "Trims surrounding spaces" do
        map Slug.toString (Slug.generate "   a   ") `shouldEqual` Just "a"

      it "Trims surrounding special characters" do
        map Slug.toString (Slug.generate "   -'a'-   ") `shouldEqual` Just "a"

      it "Doesn't create a word break on apostrophe" do
        map Slug.toString (Slug.generate "This library's great") `shouldEqual` Just "this-librarys-great"

    describe "Slug.generateWithOptions" do
      let
        slugifyOptions = Slug.defaultOptions { keepIf = isLatin1, lowerCase = false, stripApostrophes = false }
        slugify = Slug.generateWithOptions slugifyOptions
      it "Succeeds on article title example (as documented)" do
        map Slug.toString (slugify "This is my article's title!") `shouldEqual` Just "This-is-my-article's-title!"

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

instance arbitraryOptions' :: Arbitrary Options' where
  arbitrary = do
    replacement <- elements (cons' "-" [ "_", " ", "" ])
    keepIf <- arbitrary <#> \f -> f <<< CodePoints.singleton
    lowerCase <- arbitrary
    stripApostrophes <- arbitrary
    pure (Options' { replacement, keepIf, lowerCase, stripApostrophes })

-- For testing arbitrary slugs with options, we need to pair the generated slug
-- with the options used to generate it
newtype SlugWithOptions = SlugWithOptions { slug :: Slug, options :: Options }

-- Only generate valid slugs with options to test properties
instance arbitrarySlugWithOptions :: Arbitrary SlugWithOptions where
  arbitrary = do
    Options' options <- arbitrary
    let generate = Slug.generateWithOptions options
    slug <- (generate <$> arbitrary) `suchThat` isJust
    pure (SlugWithOptions { slug: unsafePartial (fromJust slug), options })

-- In order to test parsing fails appropriately
newtype BadInput = BadInput String

-- Only generate *invalid* string slugs to test properties
instance arbitraryBadInput :: Arbitrary BadInput where
  arbitrary = BadInput <$> arbitrary `suchThat` (isNothing <<< Slug.generate)

-- In order to test parsing with options fails appropriately
newtype BadInputWithOptions = BadInputWithOptions { input :: String, options :: Options }

-- Only generate *invalid* string slugs to test properties
instance arbitraryBadInputWithOptions :: Arbitrary BadInputWithOptions where
  arbitrary = do
    Options' options <- arbitrary
    input <- arbitrary `suchThat` (isNothing <<< Slug.generateWithOptions options)
    pure (BadInputWithOptions { input, options })

-- In order to test truncation fails appropriately
newtype NonPositiveInt = NonPositiveInt Int

instance arbitraryNonPositiveInt :: Arbitrary NonPositiveInt where
  arbitrary = NonPositiveInt <$> arbitrary `suchThat` \n -> n < 1

-- In order to test truncation succeeds appropriately
newtype PositiveInt = PositiveInt Int

instance arbitraryPositiveInt :: Arbitrary PositiveInt where
  arbitrary = PositiveInt <$> arbitrary `suchThat` \n -> n > 0
