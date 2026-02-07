# Identify Files with Known Text Extensions

Checks whether the provided file paths have extensions commonly
associated with text-based formats (e.g., scripts, markdown,
configuration files).

## Usage

``` r
has_known_text_extension(files)
```

## Arguments

- files:

  A character vector of files to search (only for
  [`seek_in()`](https://smartiing.github.io/seekr/reference/seek.md)).

## Value

A logical vector indicating whether each file has a known text
extension.
