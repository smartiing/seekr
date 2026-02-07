# Read and Prepare Matching Lines

Reads a set of files, filters lines based on a regular expression
pattern, and constructs a tidy tibble of the results.

## Usage

``` r
seek_lines(files, pattern, ..., path, relative_path, matches)
```

## Arguments

- files:

  A character vector of files to search (only for
  [`seek_in()`](https://smartiing.github.io/seekr/reference/seek.md)).

- pattern:

  A regular expression pattern used to match lines.

- ...:

  Additional arguments passed to
  [`readr::read_lines()`](https://readr.tidyverse.org/reference/read_lines.html),
  such as `skip`, `n_max`, or `locale`.

- path:

  A character vector of one or more directories where files should be
  discovered (only for
  [`seek()`](https://smartiing.github.io/seekr/reference/seek.md)).

- relative_path:

  Logical. If TRUE, file paths are made relative to the path argument.
  If multiple root paths are provided, relative_path is automatically
  ignored and absolute paths are kept to avoid ambiguity.

- matches:

  Logical. If `TRUE`, all matches per line are also returned in a
  `matches` list-column.

## Value

A tibble with one row per matching line.
