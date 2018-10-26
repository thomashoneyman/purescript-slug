# purescript-slug

[![Latest release](http://img.shields.io/github/release/thomashoneyman/purescript-slug.svg)](https://github.com/thomashoneyman/purescript-slug/releases)
[![Pursuit](http://pursuit.purescript.org/packages/purescript-slug/badge)](http://pursuit.purescript.org/packages/purescript-slug/)
[![Maintainer: thomashoneyman](https://img.shields.io/badge/maintainer-thomashoneyman-lightgrey.svg)](http://github.com/thomashoneyman)

Type-safe slugs for PureScript.

## Installation

```shell
bower install purescript-slug
```

# Use

This package provides a `Slug` type and related type classes & helper functions to help you construct and use type-safe slugs. When you have a `Slug`, you can be sure:

- it isn't empty
- it only contains alpha-numeric groups of characters separated by dashes (`-`)
- it does not start or end with a dash
- there are never two dashes in a row
- every character is lower cased

Create a slug with `Slug.generate`:

```purescript
generate :: String -> Maybe Slug

> show $ Slug.generate "This is an article!"
> Just (Slug "this-is-an-article")

> show $ Slug.generate "¬¬¬{}¬¬¬"
> Nothing
```

Parse a string that is (supposedly) already a slug with `Slug.parse`:

```purescript
parse :: String -> Either SlugError Slug

> Slug.parse "this-is-an-article"
> Just (Slug "this-is-an-article")

> Slug.parse "-this-is--not-"
> Nothing
```

Recover a string from a valid `Slug` with `Slug.toString`:

```purescript
toString :: Slug -> String

> Slug.toString (mySlug :: Slug)
> "this-is-an-article"
```

## Contributing

Read the [contribution guidelines](https://github.com/thomashoneyman/purescript-slug/blob/master/.github/contributing.md) to get started and see helpful related resources.

Inspired by the Haskell [slug](https://github.com/mrkkrp/slug) library by [@mrkkrp](https://github.com/mrkkrp). Some naming conventions mirror [elm-slug](https://github.com/hecrj/elm-slug).
