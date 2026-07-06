# Print matches with context and replacement preview

[`print()`](https://rdrr.io/r/base/print.html) displays a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector in a readable console format, grouped by source. Each printed
match is shown with its source, match index, line number, matched text,
and, when available, its staged replacement.

The amount of output can be controlled with `n`, which limits the number
of matches printed. `context` controls how many surrounding lines are
shown.

## Usage

``` r
# S3 method for class 'seekr_match'
print(x, ..., n = NULL, context = 0L)
```

## Arguments

- x:

  A
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  vector.

- ...:

  Not used. Present for compatibility with the
  [`print()`](https://rdrr.io/r/base/print.html) generic.

- n:

  Maximum number of matches to print. If `NULL`, a compact default is
  used: all matches are printed for small vectors, and only the first
  matches are printed for larger vectors. Use `Inf` to print all
  matches.

- context:

  Number of context lines to print around each match. Either:

  - A single non-negative integer: print that many lines before and
    after each match.

  - A pair of non-negative integers `c(before, after)`: print `before`
    lines before and `after` lines after each match.

  Only context lines captured when the
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  vector was created can be printed.

## Value

Invisibly returns the original
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector `x`.

## See also

[summary()](https://smartiing.github.io/seekr/reference/summary.seekr_match.md)
for a compact summary of matches,
[`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
to subset matches before printing, and
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md) for the
`context` argument that controls how many surrounding lines are
captured.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
x <- seekr(
  pattern = "(\\w+)(?= <- function)",
  replacement = toupper,
  path = ext_path
)

# Print up to 10 matches (default)
print(x)
#> <seekr::match[6]> 2 sources
#> Common Path: /home/runner/work/_temp/Library/seekr/extdata
#> 
#> script1.R [3]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | ADD_ONE <- function(x) {
#> [2] --  5 | capitalize <- function(txt) {
#>     ++  5 | CAPITALIZE <- function(txt) {
#> [3] --  9 | say_hello <- function(name) {
#>     ++  9 | SAY_HELLO <- function(name) {
#> 
#> script2.R [3]
#> [4] --  2 | mean_safe <- function(x) {
#>     ++  2 | MEAN_SAFE <- function(x) {
#> [5] --  7 | sd_safe <- function(x) {
#>     ++  7 | SD_SAFE <- function(x) {
#> [6] -- 12 | print_vector <- function(v) {
#>     ++ 12 | PRINT_VECTOR <- function(v) {
#> 

# Print all matches
print(x, n = Inf)
#> <seekr::match[6]> 2 sources
#> Common Path: /home/runner/work/_temp/Library/seekr/extdata
#> 
#> script1.R [3]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | ADD_ONE <- function(x) {
#> [2] --  5 | capitalize <- function(txt) {
#>     ++  5 | CAPITALIZE <- function(txt) {
#> [3] --  9 | say_hello <- function(name) {
#>     ++  9 | SAY_HELLO <- function(name) {
#> 
#> script2.R [3]
#> [4] --  2 | mean_safe <- function(x) {
#>     ++  2 | MEAN_SAFE <- function(x) {
#> [5] --  7 | sd_safe <- function(x) {
#>     ++  7 | SD_SAFE <- function(x) {
#> [6] -- 12 | print_vector <- function(v) {
#>     ++ 12 | PRINT_VECTOR <- function(v) {
#> 

# Print only 3 matches
print(x, n = 3L)
#> <seekr::match[6]> 2 sources
#> Common Path: /home/runner/work/_temp/Library/seekr/extdata
#> 
#> script1.R [3]
#> [1] -- 1 | add_one <- function(x) {
#>     ++ 1 | ADD_ONE <- function(x) {
#> [2] -- 5 | capitalize <- function(txt) {
#>     ++ 5 | CAPITALIZE <- function(txt) {
#> [3] -- 9 | say_hello <- function(name) {
#>     ++ 9 | SAY_HELLO <- function(name) {
#> 
#> # ℹ 3 more matches

# Reduce context to 1 line around each match
print(x, context = 1L)
#> <seekr::match[6]> 2 sources
#> Common Path: /home/runner/work/_temp/Library/seekr/extdata
#> 
#> script1.R [3]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | ADD_ONE <- function(x) {
#>         2 |   return(x + 1)
#> 
#>         4 | 
#> [2] --  5 | capitalize <- function(txt) {
#>     ++  5 | CAPITALIZE <- function(txt) {
#>         6 |   toupper(substr(txt, 1, 1))
#> 
#>         8 | 
#> [3] --  9 | say_hello <- function(name) {
#>     ++  9 | SAY_HELLO <- function(name) {
#>        10 |   paste('Hello', name)
#> 
#> script2.R [3]
#>         1 | # TODO: optimize this function
#> [4] --  2 | mean_safe <- function(x) {
#>     ++  2 | MEAN_SAFE <- function(x) {
#>         3 |   if (length(x) == 0) return(NA)
#> 
#>         6 | 
#> [5] --  7 | sd_safe <- function(x) {
#>     ++  7 | SD_SAFE <- function(x) {
#>         8 |   if (length(x) <= 1) return(NA)
#> 
#>        11 | 
#> [6] -- 12 | print_vector <- function(v) {
#>     ++ 12 | PRINT_VECTOR <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
#> 

# Show 3 lines before and 1 line after each match
print(x, context = c(3L, 1L))
#> <seekr::match[6]> 2 sources
#> Common Path: /home/runner/work/_temp/Library/seekr/extdata
#> 
#> script1.R [3]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | ADD_ONE <- function(x) {
#>         2 |   return(x + 1)
#>         3 | }
#>         4 | 
#> [2] --  5 | capitalize <- function(txt) {
#>     ++  5 | CAPITALIZE <- function(txt) {
#>         6 |   toupper(substr(txt, 1, 1))
#>         7 | }
#>         8 | 
#> [3] --  9 | say_hello <- function(name) {
#>     ++  9 | SAY_HELLO <- function(name) {
#>        10 |   paste('Hello', name)
#> 
#> script2.R [3]
#>         1 | # TODO: optimize this function
#> [4] --  2 | mean_safe <- function(x) {
#>     ++  2 | MEAN_SAFE <- function(x) {
#>         3 |   if (length(x) == 0) return(NA)
#>         4 |   mean(x, na.rm = TRUE)
#>         5 | }
#>         6 | 
#> [5] --  7 | sd_safe <- function(x) {
#>     ++  7 | SD_SAFE <- function(x) {
#>         8 |   if (length(x) <= 1) return(NA)
#>         9 |   sd(x, na.rm = TRUE)
#>        10 | }
#>        11 | 
#> [6] -- 12 | print_vector <- function(v) {
#>     ++ 12 | PRINT_VECTOR <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
#> 
```
