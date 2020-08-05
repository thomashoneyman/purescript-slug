# Slug

[![CI](https://github.com/thomashoneyman/purescript-slug/workflows/CI/badge.svg?branch=main)](https://github.com/thomashoneyman/purescript-slug/actions?query=workflow%3ACI+branch%3Amain)
[![Latest release](http://img.shields.io/github/release/thomashoneyman/purescript-slug.svg)](https://github.com/thomashoneyman/purescript-slug/releases)
[![Latest package set](https://img.shields.io/endpoint.svg?url=https://package-sets-badge-0lf69kxs4fbd.runkit.sh/slug)](https://github.com/purescript/package-sets)
[![Maintainer: thomashoneyman](https://img.shields.io/badge/maintainer-thomashoneyman-lightgrey.svg)](http://github.com/thomashoneyman)

Type-safe slugs for PureScript.

## Installation

```sh
spago install slug
```

## Use

This package provides a `Slug` type and related type classes & helper functions to help you construct and use type-safe slugs. When you have a `Slug`, you can be sure:

- it isn't empty
- it only contains alpha-numeric groups of characters separated by dashes (`-`)
- it does not start or end with a dash
- there are never two dashes in a row
- every character is lower cased

> **Note**: This library currently only supports characters within the Latin-1 character set.

Create a slug with `Slug.generate`:

```purs
generate :: String -> Maybe Slug

> show $ Slug.generate "This is an article!"
> Just (Slug "this-is-an-article")

> show $ Slug.generate "¬¬¬{}¬¬¬"
> Nothing
```

Parse a string that is (supposedly) already a slug with `Slug.parse`:

```purs
parse :: String -> Either SlugError Slug

> Slug.parse "this-is-an-article"
> Just (Slug "this-is-an-article")

> Slug.parse "-this-is--not-"
> Nothing
```

Recover a string from a valid `Slug` with `Slug.toString`:

```purs
toString :: Slug -> String

> Slug.toString (mySlug :: Slug)
> "this-is-an-article"
```

## Contributing

Read the [contribution guidelines](https://github.com/thomashoneyman/purescript-slug/blob/main/.github/contributing.md) to get started and see helpful related resources.

Inspired by the Haskell [slug](https://github.com/mrkkrp/slug) library by [@mrkkrp](https://github.com/mrkkrp). Some naming conventions mirror [elm-slug](https://github.com/hecrj/elm-slug).
