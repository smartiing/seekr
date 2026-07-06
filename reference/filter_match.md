# Filter matches

`filter_match()` subsets a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector using expressions evaluated directly against its fields, without
needing to call
[`vctrs::field()`](https://vctrs.r-lib.org/reference/fields.html)
explicitly.

The two calls below are equivalent:

    x[field(x, "start_line") > 10]
    filter_match(x, start_line > 10)

`filter_match()` is modelled after
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html):
field names can be used directly in expressions, and multiple
expressions are combined with `&`. This makes it easy to write readable
multi-condition filters:

    x |> filter_match(
      grepl("/R/", path),
      match == "TODO",
      start_line > 10
    )

## Usage

``` r
filter_match(x, ...)
```

## Arguments

- x:

  A
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  vector.

- ...:

  One or more filtering expressions, evaluated against the fields of
  `x`. Field names (`path`, `match`, `start_line`, `replacement`, etc.)
  can be used directly. Each expression must return a logical vector of
  the same length as `x`, with no missing values. Multiple expressions
  are combined with `&`.

## Value

A
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector containing only the matches for which all expressions evaluated
to `TRUE`. If no expressions are supplied, `x` is returned unchanged.

## Differences from base R subsetting

Unlike `x[condition]`, `filter_match()` does not recycle logical
vectors. Each expression must return exactly `length(x)` values. Missing
values (`NA`) in any expression cause an error. This prevents silent
mistakes from implicit recycling or incomplete conditions.

## See also

- [`vctrs::field()`](https://vctrs.r-lib.org/reference/fields.html) to
  access a field directly for use in base R subsetting.

- [`as_tibble.seekr_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
  and
  [`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
  for more complex workflows that require tabular manipulation.

- [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  to apply staged replacements after filtering.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
x <- seekr("TODO|FIXME", path = ext_path)

# Filter by line number
filter_match(x, start_line > 10)
#> <seekr::match[0]> 0 sources

# Filter by file path
filter_match(x, grepl("/R/", path))
#> <seekr::match[0]> 0 sources

# Filter by matched text
filter_match(x, match == "TODO")
#> <seekr::match[1]> 1 source
#> /home/runner/work/_temp/Library/seekr/extdata/script2.R [1]
#> [1] -> 1 | # TODO: optimize this function
#> 

# Combine multiple conditions
filter_match(x, match == "TODO", start_line > 10, grepl("/R/", path))
#> <seekr::match[0]> 0 sources

# Equivalent base R subsetting (more verbose)
x[
  field(x, "match") == "TODO" &
  field(x, "start_line") > 10 &
  grepl("/R/", field(x, "path"))
]
#> <seekr::match[0]> 0 sources
```
