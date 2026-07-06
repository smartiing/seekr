# Diagnose where a workflow became empty

`empty_stage()` retrieves the pipeline stage that produced an empty
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
result returned by
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md) or
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md).

Empty results can happen at different stages of the pipeline:

- `"input"`: the input `path` was empty.

- `"list"`: no files were found by
  [`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md).

- `"filter"`: all files were excluded by
  [`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md).

- `"match"`: files were searched, but no match was found.

For non-empty results, `empty_stage()` returns `NULL`.

## Usage

``` r
empty_stage(x)
```

## Arguments

- x:

  A
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  object, returned by either
  [`seek()`](https://smartiing.github.io/seekr/reference/seek.md) or
  [`seekr()`](https://smartiing.github.io/seekr/reference/seek.md).

## Value

Either `NULL` for non-empty results, or one of `"input"`, `"list"`,
`"filter"`, or `"match"` for empty results.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
x <- seek("pattern_that_does_not_exist", path = ext_path)
empty_stage(x)
#> [1] "match"
```
