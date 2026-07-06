# seekr

## Overview

`seekr` turns search-and-replace into an inspectable R workflow.

Instead of treating search, replacement, and file modification as a
single operation, `seekr` separates them into explicit steps. You can
decide which files to search, which files to exclude, inspect which
files were excluded, what matches were found, filter them, stage or
update replacements, and only then write the selected changes to disk.

At the center of this workflow is the `seekr_match` vector: a structured
object where each element represents one independent match in one file,
together with its location, matched text, optional replacement, and
surrounding context. After matching, most operations (summarizing,
printing, filtering, and replacing) work directly with this object.

`seekr_match` is designed to behave like a vector of matches while
storing the fields needed to inspect, filter, update, and replace them
safely. The [design choices
article](https://smartiing.github.io/seekr/articles/design-choices.html)
explains why `seekr` uses this representation and how it makes safe
replacement possible.

## Why seekr?

In real projects, search-and-replace often raises questions that are
difficult to answer: Which files were considered? Which files were
excluded, and why? Which matches were found? Which replacements will be
applied? Can I keep only some matches? Can I restore the previous files
if needed?

`seekr` provides a set of functions that make this workflow explicit,
composable, and safe:

- **List files** with
  [`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md).
  Start from one or more directories, recurse into subdirectories, and
  get a normalized character vector of file paths.
- **Filter files** with
  [`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md).
  Keep files by extension, path pattern, or size, and use a sensible
  default set of exclude functions to remove files that should not be
  searched.
- **Understand exclusions** with
  [`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md).
  Inspect which files were excluded and why, instead of silently
  excluding files by mistake.
- **Match patterns** with
  [`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md),
  or use [`seek()`](https://smartiing.github.io/seekr/reference/seek.md)
  to combine listing, filtering, and matching in one call. Replacements
  can be literal strings, backreferences, functions, or functions that
  operate on the capture group matrix.
- **Summarize matches** with
  [`summary()`](https://rdrr.io/r/base/summary.html). Get a compact
  overview of the number of matches, their distribution by file and
  extension, and the frequency of each match/replacement pair.
- **Print matches** with [`print()`](https://rdrr.io/r/base/print.html).
  Inspect matches with surrounding context, preview replacements, and
  use rich terminal output with clickable OSC8 links when supported.
- **Filter matches** with
  [`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md).
  Keep or discard matches after searching, without running the search
  again.
- **Set or update replacements** with
  [`field()`](https://vctrs.r-lib.org/reference/fields.html). Search
  first, inspect the result, then update the `replacement` field to
  decide what each selected match should become before writing files.
- **Replace selected matches** with
  [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).
  Starting from a `seekr_match` vector,
  [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  checks that each affected file still has the same text that was
  searched, then replaces only the matches still present in the vector
  with their corresponding replacements.
- **Inspect and restore backups** with
  [`list_backups()`](https://smartiing.github.io/seekr/reference/backups.md),
  [`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md),
  [`restore_files()`](https://smartiing.github.io/seekr/reference/restore_files.md),
  and
  [`restore_files_interactive()`](https://smartiing.github.io/seekr/reference/restore_files.md).
  Review automatic backups and recover previous file contents if
  something did not go as expected.

For more advanced workflows, a `seekr_match` vector can also be
converted to a tibble with `as_tibble()` and converted back with
[`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md).
This can make it easier to create custom summaries, filter matches, or
prepare replacements with grouped operations. See the [tabular workflows
article](https://smartiing.github.io/seekr/articles/tabular-workflows.html)
for a more detailed example.

If your text does not come directly from files, or if you want to
control reading and writing yourself, see [Working with
text](https://smartiing.github.io/seekr/articles/working-with-text.html).

For larger repositories or performance-sensitive searches, see the
[performance
notes](https://smartiing.github.io/seekr/articles/performance-note.html).

Patterns are powered by `stringr` and ICU regular expressions, so you
can use familiar tools such as
[`stringr::regex()`](https://stringr.tidyverse.org/reference/modifiers.html)
and
[`stringr::fixed()`](https://stringr.tidyverse.org/reference/modifiers.html)
when you need more control.

## Installation

``` r

# Install the package from CRAN:
install.packages("seekr")
```

## Usage

The following example uses the example files shipped with `seekr`.

In a simple workflow, you can search for a pattern, inspect or filter
the matches, and then apply only the selected replacements.

For example, this finds `"foo"` in R files listed recursively from the
working directory, prepares `"bar"` as the replacement, excludes matches
from files whose path contains `"test"`, and then applies the selected
replacements to the files.

``` r

matches <- seek("foo", "bar", extension = "R")
filtered <- filter_match(matches, !grepl("test", path))
replaced <- replace_files(filtered)

seekr("foo", "bar") |> 
  filter_match(!grepl("test", path)) |> 
  replace_files()
```

The sections below unpack this workflow step by step: how files are
listed and filtered, how matches and replacements are stored in a
`seekr_match` vector, how matches can be inspected or updated, and how
replacements are finally written to disk.

### Find matches

First, list all files that could be searched.

``` r

files <- list_files()
files
#> [1] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/config.yaml"
#> [2] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/data.json"  
#> [3] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/iris.csv"   
#> [4] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/mtcars.csv" 
#> [5] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/script1.R"  
#> [6] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/script2.R"  
#> [7] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/server1.log"
#> [8] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/server2.log"
```

Then filter to keep only R files.
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
records which files were excluded and why. The `exclusions` attribute
can be retrieved using
[`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md).

``` r

filtered <- filter_files(files, extension = "R")
filtered
#> [1] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/script1.R"
#> [2] "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/script2.R"
#> attr(,"exclusions")
#> # A tibble: 8 × 7
#>   path                                                    excluded exclude_by_extension is_git_dir is_dependency_dir is_minified_file is_not_text_mime
#>   <chr>                                                   <lgl>    <lgl>                <lgl>      <lgl>             <lgl>            <lgl>           
#> 1 C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 2 C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 3 C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 4 C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 5 C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-… FALSE    FALSE                FALSE      FALSE             FALSE            FALSE           
#> 6 C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-… FALSE    FALSE                FALSE      FALSE             FALSE            FALSE           
#> 7 C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-… TRUE     TRUE                 NA         NA                NA               NA              
#> 8 C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-… TRUE     TRUE                 NA         NA                NA               NA
```

Now that we have a list of files, we can search for function names
composed of two words separated by an underscore and prepare a
replacement that reverses them.

``` r

my_pattern <- "([a-z]+)_([a-z]+)(?= <- function)"
my_replacement <- "\\2_\\1"

x <- match_files(filtered, my_pattern, my_replacement)
```

### Inspect matches

`x` is a `seekr_match` vector. It behaves like a vector of matches, but
each match also stores fields that can be inspected with
[`fields()`](https://vctrs.r-lib.org/reference/fields.html) and accessed
with [`field()`](https://vctrs.r-lib.org/reference/fields.html).

``` r

str(x)
#> <seekr::match[5]> vctrs::rcrd
#> path        <chr> "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata/script1.R", "C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/…
#> start_line  <int> 1, 9, 2, 7, 12
#> end_line    <int> 1, 9, 2, 7, 12
#> start       <int> 1, 115, 33, 125, 213
#> end         <int> 7, 123, 41, 131, 224
#> start_col   <int> 1, 1, 1, 1, 1
#> end_col     <int> 7, 9, 9, 7, 12
#> match       <chr> "add_one", "say_hello", "mean_safe", "sd_safe", "print_vector"
#> replacement <chr> "one_add", "hello_say", "safe_mean", "safe_sd", "vector_print"
#> before      <chr> NA, "\r\ncapitalize <- function(txt) {\r\n  toupper(substr(txt, 1, 1))\r\n}\r\n", "# TODO: optimize this function", "mean_safe <- fu…
#> line        <chr> "add_one <- function(x) {", "say_hello <- function(name) {", "mean_safe <- function(x) {", "sd_safe <- function(x) {", "print_vector…
#> after       <chr> "  return(x + 1)\r\n}\r\n\r\ncapitalize <- function(txt) {\r\n  toupper(substr(txt, 1, 1))", "  paste('Hello', name)\r\n}\r\n", "  i…
#> encoding    <chr> "UTF-8", "UTF-8", "UTF-8", "UTF-8", "UTF-8"
#> hash        <chr> "6861824a9a14bce8180144e4716e3b6d", "6861824a9a14bce8180144e4716e3b6d", "936f5a0f99aca61483471cfc5223e8d6", "936f5a0f99aca61483471cf…
fields(x)
#>  [1] "path"        "start_line"  "end_line"    "start"       "end"         "start_col"   "end_col"     "match"       "replacement" "before"     
#> [11] "line"        "after"       "encoding"    "hash"
field(x, "match")
#> [1] "add_one"      "say_hello"    "mean_safe"    "sd_safe"      "print_vector"
field(x, "replacement")
#> [1] "one_add"      "hello_say"    "safe_mean"    "safe_sd"      "vector_print"
```

Use [`summary()`](https://rdrr.io/r/base/summary.html) to get a compact
overview of the matches and planned replacements.

``` r

summary(x)
#> ── <seekr::match[5]> ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#> Common Path: C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata
#> 
#> Top sources [2]
#>  • script2.R : 3 (60.0%)
#>  • script1.R : 2 (40.0%)
#> 
#> Top matches/replacements [5]
#>  • <say_hello/hello_say>       : 1 (20.0%)
#>  • <add_one/one_add>           : 1 (20.0%)
#>  • <mean_safe/safe_mean>       : 1 (20.0%)
#>  • <sd_safe/safe_sd>           : 1 (20.0%)
#>  • <print_vector/vector_print> : 1 (20.0%)
#> 
#> Top extension [1]
#>  • r : 5 (100.0%)
#> 
#> Top encoding [1]
#>  • UTF-8 : 5 (100.0%)
```

Use [`print()`](https://rdrr.io/r/base/print.html) to inspect each match
with surrounding context and preview the replacement. In terminals that
support OSC8 hyperlinks, file locations are printed as clickable links,
so you can jump directly from the console to the start of the match.

``` r

print(x, context = c(2, 1))
#> <seekr::match[5]> 2 sources
#> Common Path: C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | one_add <- function(x) {
#>         2 |   return(x + 1)
#> 
#>         7 | }
#>         8 | 
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | hello_say <- function(name) {
#>        10 |   paste('Hello', name)
#> 
#> script2.R [3]
#>         1 | # TODO: optimize this function
#> [3] --  2 | mean_safe <- function(x) {
#>     ++  2 | safe_mean <- function(x) {
#>         3 |   if (length(x) == 0) return(NA)
#> 
#>         5 | }
#>         6 | 
#> [4] --  7 | sd_safe <- function(x) {
#>     ++  7 | safe_sd <- function(x) {
#>         8 |   if (length(x) <= 1) return(NA)
#> 
#>        10 | }
#>        11 | 
#> [5] -- 12 | print_vector <- function(v) {
#>     ++ 12 | vector_print <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
```

The listing, filtering, and matching steps can also be combined in one
step with
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md).
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) is a
convenience wrapper around
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md) that
restricts the search to R, R Markdown, and Quarto files (`.R`, `.Rmd`,
`.qmd`).

``` r

y <- seek(my_pattern, my_replacement, extension = "R")
z <- seekr(my_pattern, my_replacement)
identical(x, y)
#> [1] TRUE
identical(y, z)
#> [1] TRUE
```

### Filter matches and update replacements

Matches can be filtered without reading the files again. Here, we remove
matches whose matched text contains `"safe"`.

``` r

x <- filter_match(x, !grepl("safe", match))
print(x, context = c(3L, 1L))
#> <seekr::match[3]> 2 sources
#> Common Path: C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | one_add <- function(x) {
#>         2 |   return(x + 1)
#> 
#>         6 |   toupper(substr(txt, 1, 1))
#>         7 | }
#>         8 | 
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | hello_say <- function(name) {
#>        10 |   paste('Hello', name)
#> 
#> script2.R [1]
#>         9 |   sd(x, na.rm = TRUE)
#>        10 | }
#>        11 | 
#> [3] -- 12 | print_vector <- function(v) {
#>     ++ 12 | vector_print <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
```

Replacements can also be updated after inspection. Here, we convert
functions in the first file to upper-case and to lower-case for the
rest.

``` r

first_path <- field(x, "path")[[1L]]
repl <- field(x, "replacement")

field(x, "replacement") = ifelse(
  field(x, "path") == first_path,
  toupper(repl),
  tolower(repl)
)

print(x, context = 2L)
#> <seekr::match[3]> 2 sources
#> Common Path: C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | ONE_ADD <- function(x) {
#>         2 |   return(x + 1)
#>         3 | }
#> 
#>         7 | }
#>         8 | 
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | HELLO_SAY <- function(name) {
#>        10 |   paste('Hello', name)
#>        11 | }
#> 
#> script2.R [1]
#>        10 | }
#>        11 | 
#> [3] -- 12 | print_vector <- function(v) {
#>     ++ 12 | vector_print <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
#>        14 | }
```

### Replace selected matches

Now that they are ready, we can apply our selected replacements.
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
starts from the current `seekr_match` vector and replaces only the
matches still present in that vector, each with its corresponding
replacement.

Before writing,
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
checks that every selected match has a replacement and that the hash of
each affected file still matches the hash recorded when the
`seekr_match` vector was created. If a file has changed since the
search, replacement stops and the search should be run again on the
current file contents.

``` r

replace_files(x)
```

### Restore files

By default,
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
creates a backup in the default `backup_dir` before modifying files. The
latest backup can be retrieved with
[`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md).

``` r

bck <- last_backup()
bck
#> # A tibble: 2 × 9
#>      id created_at          operation description original                                                  backup original_exists backup_exists  size
#>   <int> <dttm>              <chr>     <chr>       <chr>                                                     <chr>  <lgl>           <lgl>         <fs:>
#> 1     1 2026-07-07 00:02:41 replace   <NA>        C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-ex… C:/Us… TRUE            TRUE            172
#> 2     1 2026-07-07 00:02:41 replace   <NA>        C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-ex… C:/Us… TRUE            TRUE            293
```

Use
[`restore_files()`](https://smartiing.github.io/seekr/reference/restore_files.md)
to restore the previous file contents from the backup.

``` r

restore_files(from = bck$backup, to = bck$original)
#> ℹ Creating a backup of the current version of each existing destination file before restoring it.
#> ℹ This ensures you can revert to the state before restoration if needed.
```

[`restore_files()`](https://smartiing.github.io/seekr/reference/restore_files.md)
also creates a backup, by default, before restoring files.

``` r

list_backups()
#> # A tibble: 4 × 9
#>      id created_at          operation description original                                                  backup original_exists backup_exists  size
#>   <int> <dttm>              <chr>     <chr>       <chr>                                                     <chr>  <lgl>           <lgl>         <fs:>
#> 1     2 2026-07-07 00:02:42 restore   <NA>        C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-ex… C:/Us… TRUE            TRUE            172
#> 2     2 2026-07-07 00:02:42 restore   <NA>        C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-ex… C:/Us… TRUE            TRUE            293
#> 3     1 2026-07-07 00:02:41 replace   <NA>        C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-ex… C:/Us… TRUE            TRUE            172
#> 4     1 2026-07-07 00:02:41 replace   <NA>        C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-ex… C:/Us… TRUE            TRUE            293
```

After restoring, the original matches are back.

``` r

x_restored <- seekr(my_pattern, my_replacement)
identical(z, x_restored)
#> [1] TRUE
print(x_restored, context = 2L)
#> <seekr::match[5]> 2 sources
#> Common Path: C:/Users/smarting/AppData/Local/Temp/RtmpqWIj3a/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | one_add <- function(x) {
#>         2 |   return(x + 1)
#>         3 | }
#> 
#>         7 | }
#>         8 | 
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | hello_say <- function(name) {
#>        10 |   paste('Hello', name)
#>        11 | }
#> 
#> script2.R [3]
#>         1 | # TODO: optimize this function
#> [3] --  2 | mean_safe <- function(x) {
#>     ++  2 | safe_mean <- function(x) {
#>         3 |   if (length(x) == 0) return(NA)
#>         4 |   mean(x, na.rm = TRUE)
#>         5 | }
#>         6 | 
#> [4] --  7 | sd_safe <- function(x) {
#>     ++  7 | safe_sd <- function(x) {
#>         8 |   if (length(x) <= 1) return(NA)
#>         9 |   sd(x, na.rm = TRUE)
#>        10 | }
#>        11 | 
#> [5] -- 12 | print_vector <- function(v) {
#>     ++ 12 | vector_print <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
#>        14 | }
```

### Pipe workflow

The same `seekr` workflow can also easily be written as a pipe.

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

![Summary and print of seekr matches with context and replacement
preview](reference/figures/example_summary_print.gif)
