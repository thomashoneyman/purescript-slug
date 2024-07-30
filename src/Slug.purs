module Slug
  ( Slug
  , Options
  , defaultOptions
  , generate
  , generateWithOptions
  , parse
  , parseWithOptions
  , toString
  , truncate
  ) where

import Prelude

import Data.Argonaut.Decode (class DecodeJson, JsonDecodeError(..), decodeJson)
import Data.Argonaut.Encode (class EncodeJson, encodeJson)
import Data.Array as Array
import Data.CodePoint.Unicode (isAlphaNum, isLatin1)
import Data.Either (note)
import Data.Maybe (Maybe(..))
import Data.String (CodePoint)
import Data.String as String
import Data.String.CodePoints (fromCodePointArray, toCodePointArray, codePointFromChar)
import Data.String.Pattern (Pattern(..), Replacement(..))

-- | A `Slug` is usually created for article titles and other resources
-- | which need a human-readable resource name in a URL, typically with
-- | spaces replaced by a dash separator and all other non-alphanumeric
-- | characters removed.
-- | 
-- | A `Slug` is guaranteed to be non-empty, and when generated using
-- | the `generate` function is also guaranteed to have the following
-- | qualities:
-- |
-- | - it consists of alphanumeric groups of characters separated by `-`
-- |   dashes, where the slug cannot begin or end with a dash, and there
-- |   can never be two dashes in a row.
-- | - every character with a defined notion of case is lower-cased
-- | - its string value (got by `toString`) can be successfully parsed
-- |   with the `parse` function
-- |
-- | Example: `Slug "this-is-an-article-slug"`
-- |
-- | See `generateWithOptions` and `parseWithOptions` if you need to
-- | customize the behavior of `Slug` generation and parsing.
newtype Slug = Slug String

derive newtype instance Eq Slug
derive newtype instance Ord Slug
derive newtype instance Semigroup Slug

instance Show Slug where
  show (Slug str) = "(Slug " <> show str <> ")"

instance EncodeJson Slug where
  encodeJson (Slug s) = encodeJson s

instance DecodeJson Slug where
  decodeJson = note (TypeMismatch "Slug") <<< parse <=< decodeJson

-- | Create a `Slug` from a string. This will transform the input string
-- | to be a valid slug (if it is possible to do so) by separating words
-- | with `-` dashes, ensuring the string does not begin or end with a
-- | dash, and ensuring there are never two dashes in a row.
-- |
-- |
-- | ```purescript
-- | > Slug.generate "My article title!"
-- | > Just (Slug "my-article-title")
-- |
-- | > Slug.generate "¬¬¬{}¬¬¬"
-- | > Nothing
-- | ```
generate :: String -> Maybe Slug
generate = generateWithOptions defaultOptions

-- | Parse a valid slug (as a string) into a `Slug`. This will fail if the
-- | string is not a valid slug and does not provide the same behavior as
-- | `generate`.
-- |
-- | ```purescript
-- | > Slug.parse "my-article-title"
-- | > Just (Slug "my-article-title")
-- |
-- | > Slug.parse "My article"
-- | > Nothing
-- | ```
parse :: String -> Maybe Slug
parse = parseWithOptions defaultOptions

-- | Unwrap a `Slug` into the string contained within, without performing
-- | any transformations.
-- |
-- | ```purescript
-- | > Slug.toString (mySlug :: Slug)
-- | > "my-slug-i-generated"
-- | ```
toString :: Slug -> String
toString (Slug s) = s

-- | Ensure a `Slug` is no longer than a given number of characters. If the last
-- | character is a dash, it will also be removed. Providing a non-positive
-- | number as the length will return `Nothing`.
-- |
-- | ```purescript
-- | > Slug.generate "My article title is long!" >>= Slug.truncate 3
-- | > Just (Slug "my")
-- | ```
truncate :: Int -> Slug -> Maybe Slug
truncate n (Slug s)
  | n < 1 = Nothing
  | n >= String.length s = Just (Slug s)
  | otherwise = generate $ String.take n s

-- | Configure `generateWithOptions` and `parseWithOptions` to create a
-- | `Slug` from a string with custom options.
-- |
-- | - `replacement` is used to replace spaces (default is `"-"`).
-- | - `keepIf` is a function that determines which characters are
-- |   allowed in the slug (default is `isAlphaNum && isLatin1`).
-- | - `lowerCase` determines whether the slug should be lower-cased
-- |   (default is `true`).
-- | - `stripApostrophes` determines whether apostrophes should be
-- |   removed before generating the slug (default is `true`).
type Options =
  { replacement :: String
  , keepIf :: CodePoint -> Boolean
  , lowerCase :: Boolean
  , stripApostrophes :: Boolean
  }

defaultOptions :: Options
defaultOptions =
  { replacement: "-"
  , keepIf: isAlphaNum && isLatin1
  , lowerCase: true
  , stripApostrophes: true
  }

-- | Create a `Slug` from a string with custom options.
-- |
-- | ```purescript
-- | > slugifyOptions = Slug.defaultOptions { keepIf = isLatin1, lowerCase = false, stripApostrophes = false }
-- | > slugify = Slug.generateWithOptions slugifyOptions
-- |
-- | > slugify "This is my article's title!"
-- | > Just (Slug "This-is-my-article's-title!")
-- | ```
generateWithOptions :: Options -> String -> Maybe Slug
generateWithOptions options str = do
  let arr = words $ replaceUnwanted $ caseTransform $ stripApostrophes str
  if Array.null arr then
    Nothing
  else
    Just $ Slug $ String.joinWith options.replacement arr
  where
  -- Optionally lower-case the string
  caseTransform = if options.lowerCase then String.toLower else identity
  -- Strip apostrophes to avoid unnecessary word breaks
  stripApostrophes = if options.stripApostrophes then String.replaceAll (Pattern "'") (Replacement "") else identity

  -- Replace unwanted characters with spaces to be replaced or stripped later.
  replaceUnwanted =
    fromCodePointArray
      <<< map (\x -> if options.keepIf x then x else codePointFromChar ' ')
      <<< toCodePointArray

  -- Split on whitespace
  words = Array.filter (not String.null) <<< String.split (Pattern " ")

-- | Parse a valid slug (as a string) into a `Slug` with custom options.
-- | This will fail if the string is not a valid slug and does not
-- | provide the same behavior as `generateWithOptions` given the same
-- | `Options`.
-- |
-- | ```purescript
-- | > myOptions = Slug.defaultOptions { replacement = "_" }
-- | > Slug.parseWithOptions myOptions "my_article_title"
-- | > Just (Slug "my_article_title")
-- |
-- | > Slug.parseWithOptions myOptions "My article"
-- | > Nothing
-- | ```
parseWithOptions :: Options -> String -> Maybe Slug
parseWithOptions options str = generateWithOptions options str >>= check
  where
  check slug@(Slug s)
    | s == str = Just slug
    | otherwise = Nothing
