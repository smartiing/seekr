# Inspect the structure of a `seekr_match` vector

[`str()`](https://rdrr.io/r/utils/str.html) displays the internal
structure of a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector: the name, type, and sample values of each field, formatted for
the console width.

This is useful for a quick overview of what a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector contains without printing the full formatted output produced by
[`print.seekr_match()`](https://smartiing.github.io/seekr/reference/print.seekr_match.md).

## Usage

``` r
# S3 method for class 'seekr_match'
str(object, ...)
```

## Arguments

- object:

  A
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  vector.

- ...:

  Not used. Present for compatibility with the
  [`str()`](https://rdrr.io/r/utils/str.html) generic.

## Value

Invisibly returns the
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
x <- seekr("TODO", path = ext_path)
str(x)
#> <seekr::match[1]> vctrs::rcrd
#> path        <chr> "/home/runner/work/_temp/Library/seekr/extdata/script2.R"
#> start_line  <int> 1
#> end_line    <int> 1
#> start       <int> 3
#> end         <int> 6
#> start_col   <int> 3
#> end_col     <int> 6
#> match       <chr> "TODO"
#> replacement <chr> NA
#> before      <chr> NA
#> line        <chr> "# TODO: optimize this function"
#> after       <chr> "mean_safe <- function(x) {\n  if (length(x) == 0) return(NA)\…
#> encoding    <chr> "UTF-8"
#> hash        <chr> "036951bf4066a0b69595b7a0d9d0eb96"
```
