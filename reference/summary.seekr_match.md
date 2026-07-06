# Summarize matches and planned replacements

[`summary()`](https://rdrr.io/r/base/summary.html) produces a compact
overview of a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector: the most frequent files, matched texts, file extensions, and
encodings.

When replacements are staged, matched texts are displayed together with
their replacement preview, giving a high-level picture of what
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
would change.

## Usage

``` r
# S3 method for class 'seekr_match'
summary(object, ...)

# S3 method for class 'summary_seekr_match'
print(x, ..., n = NULL)
```

## Arguments

- object:

  A
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  vector.

- ...:

  Not used. Present for compatibility with the
  [`summary()`](https://rdrr.io/r/base/summary.html) generic.

- x:

  A `summary_seekr_match` object, as returned by
  `summary.seekr_match()`.

- n:

  Maximum number of rows to print in each summary table. If `NULL`, a
  compact default is used. This limit is applied separately to each
  section of the summary, such as top files, top matches/replacements,
  top extensions, and top encodings.

## Value

An object of class `summary_seekr_match`, containing summary tables for
files, matches/replacements, extensions, and encodings. Print it with
[`print()`](https://rdrr.io/r/base/print.html) to display a formatted
summary in the console.

## See also

- [`print.seekr_match()`](https://smartiing.github.io/seekr/reference/print.seekr_match.md)
  for a full match-level display with context lines.

- [`str.seekr_match()`](https://smartiing.github.io/seekr/reference/str.seekr_match.md)
  for the internal field structure.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
x <- seekr("TODO", path = ext_path)
y <- seekr("TODO", "DONE", path = ext_path)
summary(x)
#> ── <seekr::match[1]> ───────────────────────────────────────────────────────────
#> Top source [1]
#>  • /home/runner/work/_temp/Library/seekr/extdata/script2.R : 1 (100.0%)
#> 
#> Top match [1]
#>  • <TODO> : 1 (100.0%)
#> 
#> Top extension [1]
#>  • r : 1 (100.0%)
#> 
#> Top encoding [1]
#>  • UTF-8 : 1 (100.0%)
#> 
summary(y)
#> ── <seekr::match[1]> ───────────────────────────────────────────────────────────
#> Top source [1]
#>  • /home/runner/work/_temp/Library/seekr/extdata/script2.R : 1 (100.0%)
#> 
#> Top match/replacement [1]
#>  • <TODO/DONE> : 1 (100.0%)
#> 
#> Top extension [1]
#>  • r : 1 (100.0%)
#> 
#> Top encoding [1]
#>  • UTF-8 : 1 (100.0%)
#> 
summary(c(x, y))
#> ── <seekr::match[2]> ───────────────────────────────────────────────────────────
#> Top source [1]
#>  • /home/runner/work/_temp/Library/seekr/extdata/script2.R : 2 (100.0%)
#> 
#> Top matches/replacements [2]
#>  • <TODO/DONE> : 1 (50.0%)
#>  • <TODO>      : 1 (50.0%)
#> 
#> Top extension [1]
#>  • r : 2 (100.0%)
#> 
#> Top encoding [1]
#>  • UTF-8 : 2 (100.0%)
#> 
```
