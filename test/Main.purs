module Test.Main where

import Prelude

import Data.Array (all, any)
import Data.Array.Partial as AP
import Data.CodePoint.Unicode (isAlphaNum, isUpper)
import Data.Maybe (Maybe(..), fromJust, isJust, isNothing)
import Data.String as String
import Data.String.CodePoints (toCodePointArray, codePointFromChar)
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Partial.Unsafe (unsafePartial)
import Slug (Slug)
import Slug as Slug
import Test.QuickCheck (assertEquals, assertNotEquals)
import Test.QuickCheck.Arbitrary (class Arbitrary, arbitrary)
import Test.QuickCheck.Gen (suchThat)
import Test.Unit (suite, test)
import Test.Unit.Main (runTest)
import Test.Unit.QuickCheck (quickCheck')

main :: Effect Unit
main = runTest do
  suite "Slug Properties" do
    test "Cannot be empty" do
      quickCheck' 500 $ \(Slug' slug) ->
        Slug.toString slug `assertNotEquals` ""

    test "Contains only dashes and alphanumeric characters" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let f x = isAlphaNum x || x == codePointFromChar '-'
        all f (toCodePointArray (Slug.toString slug)) `assertEquals` true

    test "Does not begin with a dash" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let first = unsafePartial (AP.head (toCodePointArray (Slug.toString slug)))
        first `assertNotEquals` codePointFromChar '-'

    test "Does not end with a dash" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let last = unsafePartial (AP.last (toCodePointArray (Slug.toString slug)))
        last `assertNotEquals` codePointFromChar '-'

    test "Does not contain empty words between dashes" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let arr = String.split (Pattern "-") (Slug.toString slug)
        any String.null arr `assertEquals` false

    test "Does not contain any uppercase characters" do
      quickCheck' 500 $ \(Slug' slug) -> do
        let arr = toCodePointArray $ Slug.toString slug
        any isUpper arr `assertEquals` false

  suite "Semigroup Instance" do
    test "Append always creates a valid slug" do
      quickCheck' 100 $ \(Slug' x) (Slug' y) -> do
        let slug = Slug.toString (x <> y)
            slug' = Slug.toString <$> Slug.parse slug
        slug' `assertEquals` pure slug

  suite "Generate Slugs" do
    test "Generated slugs are idempotent" do
      quickCheck' 500 $ \x -> do
        let f = Slug.generate
            g = Slug.generate >=> Slug.generate <<< Slug.toString
        f x `assertEquals` g x

  suite "Parse Slugs" do
    test "Slug parses successfully on valid input" do
      quickCheck' 500 $ \(Slug' slug) -> do
        Slug.parse (Slug.toString slug) `assertEquals` pure slug

    test "Slug fails to parse bad input" do
      quickCheck' 500 $ \(BadInput str) -> do
        Slug.parse str `assertEquals` Nothing

  suite "Truncate Slugs" do
    test "Truncated slugs fail when given a non-positive length" do
      quickCheck' 500 $ \(NonPositiveInt n) (Slug' slug) -> do
        Slug.truncate n slug `assertEquals` Nothing

    test "Truncated slugs succeed with (n) or (n - 1) when given a positive length" do
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

----------
-- Arbitrary instances

-- In order to avoid unnecessary dependencies and instances in
-- the main `Slug` source
newtype Slug' = Slug' Slug

-- Only generate valid slugs to test properties
instance arbitrarySlug' :: Arbitrary Slug' where
  arbitrary = do
    let slug = ((map Slug' <<< Slug.generate) <$> arbitrary) `suchThat` isJust
    slug <#> \x -> unsafePartial (fromJust x)

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
