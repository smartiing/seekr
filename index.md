
<!-- README.md is generated from README.Rmd. Please edit that file -->

# seekr <a href="https://smartiing.github.io/seekr/"><img src="man/figures/logo.png" align="right" height="150" alt="seekr website" /></a>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/seekr)](https://CRAN.R-project.org/package=seekr)
[![R-CMD-check](https://github.com/smartiing/seekr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/smartiing/seekr/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/smartiing/seekr/graph/badge.svg)](https://app.codecov.io/gh/smartiing/seekr)
<!-- badges: end -->

## Overview

`seekr` turns search-and-replace into an inspectable R workflow.

Instead of modifying files as soon as a pattern is found, `seekr`
returns a `seekr_match` vector. Each element represents one match in one
file and stores its location, matched text, surrounding context lines,
and optional replacement.

You can keep working with that vector after the search: inspect the
result, remove unwanted matches, and define or revise the replacement
associated with each remaining match. When you are ready, only those
matches are written back to disk.

The [Design choices
article](https://smartiing.github.io/seekr/articles/design-choices.html)
explains why `seekr` uses this representation and how it makes safe
replacement possible.

In real projects, search-and-replace often raises questions beyond
finding a pattern: Which files were considered? Which files were
excluded, and why? Which matches were found? Which replacements will be
applied? Can I keep only some matches? Can I restore the previous file
contents if needed?

`seekr` provides a set of functions that make this workflow explicit,
composable, and safe:

- **List files** with `list_files()`. Start from one or more
  directories, recurse into subdirectories, optionally restrict
  discovery with Git, and get a normalized character vector of file
  paths.
- **Filter files** with `filter_files()`. Keep files by extension, path
  pattern, or size, and use a sensible default set of exclude functions
  to remove files that should not be searched.
- **Understand exclusions** with `exclusions()`. Inspect which files
  were excluded and why, instead of silently excluding files by mistake.
- **Match patterns** with `match_files()`, or use `seek()` to combine
  listing, filtering, and matching in one call. Replacements can be
  literal strings, backreferences, functions, or functions that operate
  on the capture group matrix.
- **Summarize matches** with `summary()`. Get a compact overview of the
  number of matches, their distribution by file and extension, and the
  frequency of each match/replacement pair.
- **Print matches** with `print()`. Inspect matches with surrounding
  context, preview replacements, and use rich terminal output with
  clickable OSC8 links when supported.
- **Filter matches** with `filter_match()`. Keep or discard matches
  after searching, without running the search again.
- **Set or update replacements** with `field()`. Search first, inspect
  the result, then update the `replacement` field to decide what each
  selected match should become before writing files.
- **Replace selected matches** with `replace_files()`. Starting from a
  `seekr_match` vector, `replace_files()` checks that each affected file
  still has the same text that was searched, then replaces only the
  matches still present in the vector with their corresponding
  replacements.
- **Inspect and restore backups** with `list_backups()`,
  `last_backup()`, `restore_files()`, and `restore_files_interactive()`.
  Review automatic backups and recover previous file contents if
  something did not go as expected.

For more advanced workflows, a `seekr_match` vector can also be
converted to a data frame and converted back with `as_match()`. This can
make it easier to create custom summaries, filter matches, or prepare
replacements with grouped operations. For a detailed example, see the
[Tabular workflows
article](https://smartiing.github.io/seekr/articles/tabular-workflows.html).

If your text does not come directly from files, or if you want to
control reading and writing yourself, see the [Working with text
article](https://smartiing.github.io/seekr/articles/working-with-text.html).

For larger repositories or performance-sensitive searches, see the
[Performance notes
article](https://smartiing.github.io/seekr/articles/performance-note.html).

Patterns are powered by [`stringr`](https://stringr.tidyverse.org/) and
ICU regular expressions, so you can use familiar tools such as
`stringr::regex()`, `stringr::fixed()`, and `stringr::coll()` when you
need more control.

## Installation

``` r
# Install the package from CRAN:
install.packages("seekr")

# Or the the development version from GitHub:
# install.packages("pak")
pak::pak("smartiing/seekr")
```

## Usage

### Find matches

First, list all files that could be searched.

``` r
files <- list_files()
files
#> [1] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/config.yaml"
#> [2] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/data.json"  
#> [3] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/iris.csv"   
#> [4] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/mtcars.csv" 
#> [5] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/script1.R"  
#> [6] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/script2.R"  
#> [7] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/server1.log"
#> [8] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/server2.log"
```

Then filter to keep only R files. `filter_files()` records which files
were excluded and why. The `exclusions` attribute can be retrieved using
`exclusions()`.

``` r
filtered <- filter_files(files, extension = "R")
filtered
#> [1] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/script1.R"
#> [2] "C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/script2.R"
#> attr(,"exclusions")
#> # A tibble: 8 × 7
#>   path                                                    excluded exclude_by_extension is_git_dir is_dependency_dir is_minified_file is_not_text_mime
#>   <chr>                                                   <lgl>    <lgl>                <lgl>      <lgl>             <lgl>            <lgl>           
#> 1 C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 2 C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 3 C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 4 C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 5 C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-… FALSE    FALSE                FALSE      FALSE             FALSE            FALSE           
#> 6 C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-… FALSE    FALSE                FALSE      FALSE             FALSE            FALSE           
#> 7 C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 8 C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-… TRUE     TRUE                 NA         NA                NA               NA
```

Now that we have a list of files, we can search for function names
composed of at least two words separated by an underscore and prepare a
replacement that reverses them.

``` r
my_pattern <- "([a-z]+)_([a-z]+)(?= <- function)"
my_replacement <- "\\2_\\1"

x <- match_files(filtered, my_pattern, my_replacement)
```

The listing, filtering, and matching steps can also be combined in one
step with `seek()`. `seekr()` is a convenience wrapper around `seek()`
that restricts the search to R, R Markdown, and Quarto files (`.R`,
`.Rmd`, `.qmd`).

``` r
y <- seek(my_pattern, my_replacement, extension = "R")
identical(x, y)
#> [1] TRUE
```

### Inspect matches

`x` is a `seekr_match` vector. It behaves like a vector of matches, but
each match also stores fields that can be inspected with `fields()` and
accessed with `field()`.

``` r
str(x)
#> <seekr::match[5]>[3;38;5;243m vctrs::rcrd[0m
#> path        [3;38;5;243m<chr>[0m [38;5;243m"[39mC:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata/script1.R[38;5;243m", "[39mC:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/[38;5;243m…[0m
#> start_line  [3;38;5;243m<int>[0m 1[38;5;243m, [39m9[38;5;243m, [39m2[38;5;243m, [39m7[38;5;243m, [39m12
#> end_line    [3;38;5;243m<int>[0m 1[38;5;243m, [39m9[38;5;243m, [39m2[38;5;243m, [39m7[38;5;243m, [39m12
#> start       [3;38;5;243m<int>[0m 1[38;5;243m, [39m107[38;5;243m, [39m32[38;5;243m, [39m119[38;5;243m, [39m202
#> end         [3;38;5;243m<int>[0m 7[38;5;243m, [39m115[38;5;243m, [39m40[38;5;243m, [39m125[38;5;243m, [39m213
#> start_col   [3;38;5;243m<int>[0m 1[38;5;243m, [39m1[38;5;243m, [39m1[38;5;243m, [39m1[38;5;243m, [39m1
#> end_col     [3;38;5;243m<int>[0m 7[38;5;243m, [39m9[38;5;243m, [39m9[38;5;243m, [39m7[38;5;243m, [39m12
#> match       [3;38;5;243m<chr>[0m [38;5;243m"[39madd_one[38;5;243m", "[39msay_hello[38;5;243m", "[39mmean_safe[38;5;243m", "[39msd_safe[38;5;243m", "[39mprint_vector[38;5;243m"[39m
#> replacement [3;38;5;243m<chr>[0m [38;5;243m"[39mone_add[38;5;243m", "[39mhello_say[38;5;243m", "[39msafe_mean[38;5;243m", "[39msafe_sd[38;5;243m", "[39mvector_print[38;5;243m"[39m
#> before      [3;38;5;243m<chr>[0m [31mNA[39m[38;5;243m, "[39m\ncapitalize <- function(txt) {\n  toupper(substr(txt, 1, 1))\n}\n[38;5;243m", "[39m# TODO: optimize this function[38;5;243m", "[39mmean_safe <- function(x[38;5;243m…[0m
#> line        [3;38;5;243m<chr>[0m [38;5;243m"[39madd_one <- function(x) {[38;5;243m", "[39msay_hello <- function(name) {[38;5;243m", "[39mmean_safe <- function(x) {[38;5;243m", "[39msd_safe <- function(x) {[38;5;243m", "[39mprint_vector[38;5;243m…[0m
#> after       [3;38;5;243m<chr>[0m [38;5;243m"[39m  return(x + 1)\n}\n\ncapitalize <- function(txt) {\n  toupper(substr(txt, 1, 1))[38;5;243m", "[39m  paste('Hello', name)\n}\n[38;5;243m", "[39m  if (length(x)[38;5;243m…[0m
#> encoding    [3;38;5;243m<chr>[0m [38;5;243m"[39mUTF-8[38;5;243m", "[39mUTF-8[38;5;243m", "[39mUTF-8[38;5;243m", "[39mUTF-8[38;5;243m", "[39mUTF-8[38;5;243m"[39m
#> hash        [3;38;5;243m<chr>[0m [38;5;243m"[39m64a0df249c4d06303279cefc18f90dab[38;5;243m", "[39m64a0df249c4d06303279cefc18f90dab[38;5;243m", "[39m2f39361ab4ba30df0d4f2d4fcb002d21[38;5;243m", "[39m2f39361ab4ba30df0d4f2d4[38;5;243m…[0m
fields(x)
#>  [1] "path"        "start_line"  "end_line"    "start"       "end"         "start_col"   "end_col"     "match"       "replacement" "before"     
#> [11] "line"        "after"       "encoding"    "hash"
field(x, "match")
#> [1] "add_one"      "say_hello"    "mean_safe"    "sd_safe"      "print_vector"
field(x, "replacement")
#> [1] "one_add"      "hello_say"    "safe_mean"    "safe_sd"      "vector_print"
```

Use `summary()` to get a compact overview of the matches and planned
replacements.

``` r
summary(x)
#> ── <seekr::match[5]> ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#> Common Path: [1;34mC:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata[0m
#> 
#> Top sources [38;5;243m[2][0m
#>  • [34mscript2.R[0m : 3 [38;5;243m(60.0%)[0m
#>  • [34mscript1.R[0m : 2 [38;5;243m(40.0%)[0m
#> 
#> Top matches/replacements [38;5;243m[5][0m
#>  • [38;5;243m<[0m[31msay_hello[0m[38;5;243m/[0m[32mhello_say[0m[38;5;243m>[0m       : 1 [38;5;243m(20.0%)[0m
#>  • [38;5;243m<[0m[31madd_one[0m[38;5;243m/[0m[32mone_add[0m[38;5;243m>[0m           : 1 [38;5;243m(20.0%)[0m
#>  • [38;5;243m<[0m[31mmean_safe[0m[38;5;243m/[0m[32msafe_mean[0m[38;5;243m>[0m       : 1 [38;5;243m(20.0%)[0m
#>  • [38;5;243m<[0m[31msd_safe[0m[38;5;243m/[0m[32msafe_sd[0m[38;5;243m>[0m           : 1 [38;5;243m(20.0%)[0m
#>  • [38;5;243m<[0m[31mprint_vector[0m[38;5;243m/[0m[32mvector_print[0m[38;5;243m>[0m : 1 [38;5;243m(20.0%)[0m
#> 
#> Top extension [38;5;243m[1][0m
#>  • r : 5 [38;5;243m(100.0%)[0m
#> 
#> Top encoding [38;5;243m[1][0m
#>  • UTF-8 : 5 [38;5;243m(100.0%)[0m
```

Use `print()` to inspect each match with surrounding context and preview
the replacement.

``` r
print(x, context = c(0, 3))
#> <seekr::match[5]>[38;5;243m 2 sources[0m
#> Common Path: [1;34mC:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata[0m
#> 
#> [34mscript1.R[0m [38;5;243m[2][0m
#> [1] --  1 [38;5;243m|[0m [31madd_one[0m <- function(x) {
#>     ++  1 [38;5;243m|[0m [32mone_add[0m <- function(x) {
#> [38;5;243m        2 |   return(x + 1)[0m
#> [38;5;243m        3 | }[0m
#> [38;5;243m        4 | [0m
#> 
#> [2] --  9 [38;5;243m|[0m [31msay_hello[0m <- function(name) {
#>     ++  9 [38;5;243m|[0m [32mhello_say[0m <- function(name) {
#> [38;5;243m       10 |   paste('Hello', name)[0m
#> [38;5;243m       11 | }[0m
#> [38;5;243m       12 | [0m
#> 
#> [34mscript2.R[0m [38;5;243m[3][0m
#> [3] --  2 [38;5;243m|[0m [31mmean_safe[0m <- function(x) {
#>     ++  2 [38;5;243m|[0m [32msafe_mean[0m <- function(x) {
#> [38;5;243m        3 |   if (length(x) == 0) return(NA)[0m
#> [38;5;243m        4 |   mean(x, na.rm = TRUE)[0m
#> [38;5;243m        5 | }[0m
#> 
#> [4] --  7 [38;5;243m|[0m [31msd_safe[0m <- function(x) {
#>     ++  7 [38;5;243m|[0m [32msafe_sd[0m <- function(x) {
#> [38;5;243m        8 |   if (length(x) <= 1) return(NA)[0m
#> [38;5;243m        9 |   sd(x, na.rm = TRUE)[0m
#> [38;5;243m       10 | }[0m
#> 
#> [5] -- 12 [38;5;243m|[0m [31mprint_vector[0m <- function(v) {
#>     ++ 12 [38;5;243m|[0m [32mvector_print[0m <- function(v) {
#> [38;5;243m       13 |   print(paste('Vector of length', length(v)))[0m
#> [38;5;243m       14 | }[0m
#> [38;5;243m       15 | [0m
```

### Filter matches and update replacements

Matches can be filtered without reading the files again. Here, we remove
matches whose matched text contains `"safe"`.

``` r
x <- filter_match(x, !grepl("safe", match))
print(x, context = c(0L, 2L))
#> <seekr::match[3]>[38;5;243m 2 sources[0m
#> Common Path: [1;34mC:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata[0m
#> 
#> [34mscript1.R[0m [38;5;243m[2][0m
#> [1] --  1 [38;5;243m|[0m [31madd_one[0m <- function(x) {
#>     ++  1 [38;5;243m|[0m [32mone_add[0m <- function(x) {
#> [38;5;243m        2 |   return(x + 1)[0m
#> [38;5;243m        3 | }[0m
#> 
#> [2] --  9 [38;5;243m|[0m [31msay_hello[0m <- function(name) {
#>     ++  9 [38;5;243m|[0m [32mhello_say[0m <- function(name) {
#> [38;5;243m       10 |   paste('Hello', name)[0m
#> [38;5;243m       11 | }[0m
#> 
#> [34mscript2.R[0m [38;5;243m[1][0m
#> [3] -- 12 [38;5;243m|[0m [31mprint_vector[0m <- function(v) {
#>     ++ 12 [38;5;243m|[0m [32mvector_print[0m <- function(v) {
#> [38;5;243m       13 |   print(paste('Vector of length', length(v)))[0m
#> [38;5;243m       14 | }[0m
```

Replacements can also be set or updated after inspection. Here, we
convert the replacement to upper case and preview the result.

``` r
field(x, "replacement") = toupper(field(x, "replacement"))
print(x, context = c(0, 2))
#> <seekr::match[3]>[38;5;243m 2 sources[0m
#> Common Path: [1;34mC:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata[0m
#> 
#> [34mscript1.R[0m [38;5;243m[2][0m
#> [1] --  1 [38;5;243m|[0m [31madd_one[0m <- function(x) {
#>     ++  1 [38;5;243m|[0m [32mONE_ADD[0m <- function(x) {
#> [38;5;243m        2 |   return(x + 1)[0m
#> [38;5;243m        3 | }[0m
#> 
#> [2] --  9 [38;5;243m|[0m [31msay_hello[0m <- function(name) {
#>     ++  9 [38;5;243m|[0m [32mHELLO_SAY[0m <- function(name) {
#> [38;5;243m       10 |   paste('Hello', name)[0m
#> [38;5;243m       11 | }[0m
#> 
#> [34mscript2.R[0m [38;5;243m[1][0m
#> [3] -- 12 [38;5;243m|[0m [31mprint_vector[0m <- function(v) {
#>     ++ 12 [38;5;243m|[0m [32mVECTOR_PRINT[0m <- function(v) {
#> [38;5;243m       13 |   print(paste('Vector of length', length(v)))[0m
#> [38;5;243m       14 | }[0m
```

### Replace selected matches

Now that the vector is ready, `replace_files()` can apply only the
matches still present, each with its corresponding replacement.

Before writing, `replace_files()` checks that every selected match has a
replacement and that the hash of each affected file still matches the
hash recorded when the `seekr_match` vector was created. If a file has
changed since the search, replacement stops and the search should be run
again on the current file contents.

``` r
replace_files(x)
```

In this example, the replacement strings still match `my_pattern` if we
ignore the case. This lets us search again and verify that the three
selected matches were replaced, while the two excluded matches were left
unchanged.

``` r
seekr(regex(my_pattern, ignore_case = TRUE))
#> <seekr::match[5]>[38;5;243m 2 sources[0m
#> Common Path: [1;34mC:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata[0m
#> 
#> [34mscript1.R[0m [38;5;243m[2][0m
#> [1] ->  1 [38;5;243m|[0m [36mONE_ADD[0m <- function(x) {
#> [2] ->  9 [38;5;243m|[0m [36mHELLO_SAY[0m <- function(name) {
#> 
#> [34mscript2.R[0m [38;5;243m[3][0m
#> [3] ->  2 [38;5;243m|[0m [36mmean_safe[0m <- function(x) {
#> [4] ->  7 [38;5;243m|[0m [36msd_safe[0m <- function(x) {
#> [5] -> 12 [38;5;243m|[0m [36mVECTOR_PRINT[0m <- function(v) {
```

### Restore files

By default, `replace_files()` creates a backup in the default
`backup_dir` before modifying files. The latest backup can be retrieved
with `last_backup()`.

``` r
bck <- last_backup()
bck
#> # A tibble: 2 × 9
#>      id created_at          operation description original                                                  backup original_exists backup_exists  size
#>   <int> <dttm>              <chr>     <chr>       <chr>                                                     <chr>  <lgl>           <lgl>         <fs:>
#> 1     1 2026-07-14 17:07:59 replace   <NA>        C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-ex… C:/Us… TRUE            TRUE            161
#> 2     1 2026-07-14 17:07:59 replace   <NA>        C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-ex… C:/Us… TRUE            TRUE            279
```

Use `restore_files()` to restore the previous file contents from the
backup.

``` r
restore_files(from = bck$backup, to = bck$original)
#> ℹ Creating a backup of the current version of each existing destination file before restoring it.
#> ℹ This ensures you can revert to the state before restoration if needed.
```

`restore_files()` also creates a backup, by default, before restoring
files.

``` r
list_backups()
#> # A tibble: 4 × 9
#>      id created_at          operation description original                                                  backup original_exists backup_exists  size
#>   <int> <dttm>              <chr>     <chr>       <chr>                                                     <chr>  <lgl>           <lgl>         <fs:>
#> 1     2 2026-07-14 17:07:59 restore   <NA>        C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-ex… C:/Us… TRUE            TRUE            161
#> 2     2 2026-07-14 17:07:59 restore   <NA>        C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-ex… C:/Us… TRUE            TRUE            279
#> 3     1 2026-07-14 17:07:59 replace   <NA>        C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-ex… C:/Us… TRUE            TRUE            161
#> 4     1 2026-07-14 17:07:59 replace   <NA>        C:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-ex… C:/Us… TRUE            TRUE            279
```

Once the files have been restored, the original files are back.

``` r
x_restored <- seekr(my_pattern, my_replacement)
identical(y, x_restored)
#> [1] TRUE
print(x_restored)
#> <seekr::match[5]>[38;5;243m 2 sources[0m
#> Common Path: [1;34mC:/Users/smarting/AppData/Local/Temp/Rtmp6rAmJE/seekr-example/extdata[0m
#> 
#> [34mscript1.R[0m [38;5;243m[2][0m
#> [1] --  1 [38;5;243m|[0m [31madd_one[0m <- function(x) {
#>     ++  1 [38;5;243m|[0m [32mone_add[0m <- function(x) {
#> [2] --  9 [38;5;243m|[0m [31msay_hello[0m <- function(name) {
#>     ++  9 [38;5;243m|[0m [32mhello_say[0m <- function(name) {
#> 
#> [34mscript2.R[0m [38;5;243m[3][0m
#> [3] --  2 [38;5;243m|[0m [31mmean_safe[0m <- function(x) {
#>     ++  2 [38;5;243m|[0m [32msafe_mean[0m <- function(x) {
#> [4] --  7 [38;5;243m|[0m [31msd_safe[0m <- function(x) {
#>     ++  7 [38;5;243m|[0m [32msafe_sd[0m <- function(x) {
#> [5] -- 12 [38;5;243m|[0m [31mprint_vector[0m <- function(v) {
#>     ++ 12 [38;5;243m|[0m [32mvector_print[0m <- function(v) {
```

### Pipe workflow

The main `seekr` functions are designed to compose: the output of one
step can usually be passed directly to the next. In real use, you will
often pause to inspect, filter, or update the result, but the pipe form
makes the structure of the workflow clear.

``` r
x <-
  list_files() |>
  filter_files(extension = "R") |>
  match_files(my_pattern, my_replacement) |>
  filter_match(!grepl("safe", match)) |>
  replace_files()
```

## Clickable output

`seekr` is designed to make search results actionable. When your
terminal supports OSC8 hyperlinks, printed matches include clickable
file locations, so you can inspect matches in the console and jump
directly to the corresponding file and line.

<img src="man/figures/example_summary_print.gif" alt="Summary and print of seekr matches with context and replacement preview">
