# Use capture groups in function-based replacements

This helper wraps a function to indicate that it should receive the full
capture group matrix as input, instead of the default vector of full
matches. This allows the replacement logic to use individual capture
groups.

## Usage

``` r
with_capture_groups_matrix(fn)
```

## Arguments

- fn:

  A function taking a single argument: a character matrix of capture
  groups, where each row corresponds to a match, the first column is the
  full match and subsequent columns are capture groups.

## Value

A function identical to `fn`, but marked with an internal attribute used
by
[`compute_replacement()`](https://smartiing.github.io/seekr/reference/compute_replacement.md)
to dispatch on replacement logic.

## Details

The capture matrix is the result of
[`stringr::str_match_all()`](https://stringr.tidyverse.org/reference/str_match.html):
the first column contains the full match, and subsequent columns contain
capture groups.

## Examples

``` r
text <- "lorem ipsum foo_bar lorem ipsum bar_foo lorem ipsum"
fn_repl <- function(M) paste0(tolower(M[, 3L]), ".", toupper(M[, 2L]))
fn_repl <- with_capture_groups_matrix(fn_repl)
match_text(text, path = "example", pattern = "(\\w+)_(\\w+)", replacement = fn_repl)
#> <seekr::match[2]> 1 source
#> example [2]
#> [1] -- 1 | lorem ipsum foo_bar lorem ipsum bar_foo lorem ipsum
#>     ++ 1 | lorem ipsum bar.FOO lorem ipsum bar_foo lorem ipsum
#> [2] -- 1 | lorem ipsum foo_bar lorem ipsum bar_foo lorem ipsum
#>     ++ 1 | lorem ipsum foo_bar lorem ipsum foo.BAR lorem ipsum
#> 
```
