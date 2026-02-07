# Identify Files with Known Non-Text Extensions

Checks whether the provided file paths have extensions typically
associated with binary or non-text formats (e.g., images, archives,
executables).

## Usage

``` r
has_known_nontext_extension(files)
```

## Arguments

- files:

  A character vector of files to search (only for
  [`seek_in()`](https://smartiing.github.io/seekr/reference/seek.md)).

## Value

A logical vector indicating whether each file has a known non-text
extension.
