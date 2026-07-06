# Sort matches within each file

`sort_within_files()` sorts matches by position within each file, while
preserving the order in which files appear in `x`.

This differs from [`sort()`](https://rdrr.io/r/base/sort.html), which
sorts globally and reorders files alphabetically. Use
`sort_within_files()` when you want positions within each file to be
consistent — for example, after combining two
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vectors with
[`vctrs::vec_c()`](https://vctrs.r-lib.org/reference/vec_c.html) —
without changing the order in which files are displayed or processed.

## Usage

``` r
sort_within_files(x)
```

## Arguments

- x:

  A
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  vector.

## Value

A
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector with the same matches in potentially different order: files
appear in their original order, and matches within each file are sorted
by `start`, then `end`, then `match`, then `replacement`.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
x <- seekr("TODO", path = ext_path)
y <- seekr("FIXME", path = ext_path)

# Combine and reorder within files without changing file order
z <- vctrs::vec_c(x, y)
sort_within_files(z)
#> <seekr::match[1]> 1 source
#> /home/runner/work/_temp/Library/seekr/extdata/script2.R [1]
#> [1] -> 1 | # TODO: optimize this function
#> 
```
