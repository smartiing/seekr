# Getting started with seekr

## Introduction

`seekr` turns search-and-replace across files into an explicit workflow.

This article gives a detailed walkthrough of that workflow. It starts
from the basic steps—listing files, filtering files, and finding
matches—and then shows how matches can be inspected, filtered, updated,
replaced, and restored.

The examples use a temporary copy of the example files shipped with
`seekr`, so they are safe to modify.

``` r

library(seekr)
```

## List files

The first step is to list candidate files.

[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md)
lists the files that exist and that will be filtered before looking for
matches. Its main arguments are `path`, which defines where to look,
`all`, which controls whether hidden files and directories are included,
and `recurse`, which controls whether and how deeply subdirectories are
searched.

By default,
[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md)
searches recursively from the current directory, and ignores hidden
files and directories.

When searching inside a Git repository, you can also set
`use_git = TRUE` to restrict file discovery to files Git considers
relevant: tracked files and untracked files that are not ignored by Git.

``` r

files <- list_files()
files
#> [1] "/tmp/RtmpEtn5S5/seekr-example/extdata/config.yaml" "/tmp/RtmpEtn5S5/seekr-example/extdata/data.json"  
#> [3] "/tmp/RtmpEtn5S5/seekr-example/extdata/iris.csv"    "/tmp/RtmpEtn5S5/seekr-example/extdata/mtcars.csv" 
#> [5] "/tmp/RtmpEtn5S5/seekr-example/extdata/script1.R"   "/tmp/RtmpEtn5S5/seekr-example/extdata/script2.R"  
#> [7] "/tmp/RtmpEtn5S5/seekr-example/extdata/server1.log" "/tmp/RtmpEtn5S5/seekr-example/extdata/server2.log"
```

[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md)
is intentionally simple. Its role is to discover candidate files, not to
decide which files are relevant for a particular search. That decision
is handled later by
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md).

This separation is deliberate. File discovery can stay broad and
predictable, while file filtering remains explicit and inspectable.

## Filter files

Once files have been listed,
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
excludes the files that should not be searched.

### Built-in filters

[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
takes a vector of file paths, typically returned by
[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md),
and returns the subset of files that should be searched.

It has three main built-in filters:

- `extension`, to keep files with selected extensions,
- `path_pattern`, to keep files whose path matches a pattern,
- `max_file_size`, to keep files below a size limit.

In addition to these built-in filters,
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
also uses a list of `exclude_functions`. These are predicate-like
functions that decide whether specific files should be excluded. By
default, they are used to exclude files that should usually not be
searched, such as non-text files or files handled by the default
exclusion rules.

For example, we can keep only R files.

``` r

filter_files(files, extension = "R")
#> [1] "/tmp/RtmpEtn5S5/seekr-example/extdata/script1.R" "/tmp/RtmpEtn5S5/seekr-example/extdata/script2.R"
#> attr(,"exclusions")
#> # A tibble: 8 × 7
#>   path                                              excluded exclude_by_extension is_git_dir is_dependency_dir is_minified_file is_not_text_mime
#>   <chr>                                             <lgl>    <lgl>                <lgl>      <lgl>             <lgl>            <lgl>           
#> 1 /tmp/RtmpEtn5S5/seekr-example/extdata/config.yaml TRUE     TRUE                 NA         NA                NA               NA              
#> 2 /tmp/RtmpEtn5S5/seekr-example/extdata/data.json   TRUE     TRUE                 NA         NA                NA               NA              
#> 3 /tmp/RtmpEtn5S5/seekr-example/extdata/iris.csv    TRUE     TRUE                 NA         NA                NA               NA              
#> 4 /tmp/RtmpEtn5S5/seekr-example/extdata/mtcars.csv  TRUE     TRUE                 NA         NA                NA               NA              
#> 5 /tmp/RtmpEtn5S5/seekr-example/extdata/script1.R   FALSE    FALSE                FALSE      FALSE             FALSE            FALSE           
#> 6 /tmp/RtmpEtn5S5/seekr-example/extdata/script2.R   FALSE    FALSE                FALSE      FALSE             FALSE            FALSE           
#> 7 /tmp/RtmpEtn5S5/seekr-example/extdata/server1.log TRUE     TRUE                 NA         NA                NA               NA              
#> 8 /tmp/RtmpEtn5S5/seekr-example/extdata/server2.log TRUE     TRUE                 NA         NA                NA               NA
```

Here we combine the different types of filters to exclude the files we
are not interested in.

``` r

# Add a dummy png file to illustrate the exclusion of non-text files by default
files <- c(files, "server.png")

filtered <- filter_files(
  files, 
  extension = c("r", "log", "yaml", "png"),
  path_pattern = "script|server",
  max_file_size = 1000L
)

filtered
#> [1] "/tmp/RtmpEtn5S5/seekr-example/extdata/script1.R" "/tmp/RtmpEtn5S5/seekr-example/extdata/script2.R"
#> attr(,"exclusions")
#> # A tibble: 9 × 9
#>   path        excluded exclude_by_extension exclude_by_path_patt…¹ exclude_by_file_size is_git_dir is_dependency_dir is_minified_file is_not_text_mime
#>   <chr>       <lgl>    <lgl>                <lgl>                  <lgl>                <lgl>      <lgl>             <lgl>            <lgl>           
#> 1 /tmp/RtmpE… TRUE     FALSE                TRUE                   NA                   NA         NA                NA               NA              
#> 2 /tmp/RtmpE… TRUE     TRUE                 NA                     NA                   NA         NA                NA               NA              
#> 3 /tmp/RtmpE… TRUE     TRUE                 NA                     NA                   NA         NA                NA               NA              
#> 4 /tmp/RtmpE… TRUE     TRUE                 NA                     NA                   NA         NA                NA               NA              
#> 5 /tmp/RtmpE… FALSE    FALSE                FALSE                  FALSE                FALSE      FALSE             FALSE            FALSE           
#> 6 /tmp/RtmpE… FALSE    FALSE                FALSE                  FALSE                FALSE      FALSE             FALSE            FALSE           
#> 7 /tmp/RtmpE… TRUE     FALSE                FALSE                  TRUE                 NA         NA                NA               NA              
#> 8 /tmp/RtmpE… TRUE     FALSE                FALSE                  TRUE                 NA         NA                NA               NA              
#> 9 /tmp/RtmpE… TRUE     FALSE                FALSE                  FALSE                FALSE      FALSE             FALSE            TRUE            
#> # ℹ abbreviated name: ¹​exclude_by_path_pattern
```

### Inspect exclusions

Filtering is inspectable.
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
records which files were excluded and why.

In this example, files are first excluded by `extension`. Then, among
the remaining files, paths that do not match `path_pattern` are
excluded. Finally, the two log files are excluded because they are above
the size limit set with `max_file_size`.

Each column in the exclusions table represents one filtering or
exclusion step. The last column shows that the dummy `"server.png"` file
was excluded by the default rules because its extension is not
associated with text files.

``` r

exclusions(filtered)
#> # A tibble: 9 × 9
#>   path        excluded exclude_by_extension exclude_by_path_patt…¹ exclude_by_file_size is_git_dir is_dependency_dir is_minified_file is_not_text_mime
#>   <chr>       <lgl>    <lgl>                <lgl>                  <lgl>                <lgl>      <lgl>             <lgl>            <lgl>           
#> 1 /tmp/RtmpE… TRUE     FALSE                TRUE                   NA                   NA         NA                NA               NA              
#> 2 /tmp/RtmpE… TRUE     TRUE                 NA                     NA                   NA         NA                NA               NA              
#> 3 /tmp/RtmpE… TRUE     TRUE                 NA                     NA                   NA         NA                NA               NA              
#> 4 /tmp/RtmpE… TRUE     TRUE                 NA                     NA                   NA         NA                NA               NA              
#> 5 /tmp/RtmpE… FALSE    FALSE                FALSE                  FALSE                FALSE      FALSE             FALSE            FALSE           
#> 6 /tmp/RtmpE… FALSE    FALSE                FALSE                  FALSE                FALSE      FALSE             FALSE            FALSE           
#> 7 /tmp/RtmpE… TRUE     FALSE                FALSE                  TRUE                 NA         NA                NA               NA              
#> 8 /tmp/RtmpE… TRUE     FALSE                FALSE                  TRUE                 NA         NA                NA               NA              
#> 9 /tmp/RtmpE… TRUE     FALSE                FALSE                  FALSE                FALSE      FALSE             FALSE            TRUE            
#> # ℹ abbreviated name: ¹​exclude_by_path_pattern
```

This is useful because file filtering can otherwise be hard to audit.
Instead of silently excluding files, `seekr` lets you inspect what was
excluded at each step.

### Custom exclude functions

In addition to the built-in filters,
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
uses a list of exclude functions. These functions receive file paths and
return `TRUE` for files that should be excluded.

`seekr` provides a default set of exclude functions.

``` r

names(exclude_functions)
#> [1] "is_git_dir"        "is_dependency_dir" "is_minified_file"  "is_not_text_mime"
```

You can add your own **named** exclude function(s) by modifying a copy
of `exclude_functions`. Custom functions will also appear on their
dedicated column(s) in the
[`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md)
data frame.

``` r

my_exclude_functions <- c(
  exclude_functions,
  exclude_script2 = function(path) grepl("script2[.]R$", path)
)

filtered_custom <- filter_files(
  files,
  extension = "R",
  exclude = my_exclude_functions
)

filtered_custom
#> [1] "/tmp/RtmpEtn5S5/seekr-example/extdata/script1.R"
#> attr(,"exclusions")
#> # A tibble: 9 × 8
#>   path                                    excluded exclude_by_extension is_git_dir is_dependency_dir is_minified_file is_not_text_mime exclude_script2
#>   <chr>                                   <lgl>    <lgl>                <lgl>      <lgl>             <lgl>            <lgl>            <lgl>          
#> 1 /tmp/RtmpEtn5S5/seekr-example/extdata/… TRUE     TRUE                 NA         NA                NA               NA               NA             
#> 2 /tmp/RtmpEtn5S5/seekr-example/extdata/… TRUE     TRUE                 NA         NA                NA               NA               NA             
#> 3 /tmp/RtmpEtn5S5/seekr-example/extdata/… TRUE     TRUE                 NA         NA                NA               NA               NA             
#> 4 /tmp/RtmpEtn5S5/seekr-example/extdata/… TRUE     TRUE                 NA         NA                NA               NA               NA             
#> 5 /tmp/RtmpEtn5S5/seekr-example/extdata/… FALSE    FALSE                FALSE      FALSE             FALSE            FALSE            FALSE          
#> 6 /tmp/RtmpEtn5S5/seekr-example/extdata/… TRUE     FALSE                FALSE      FALSE             FALSE            FALSE            TRUE           
#> 7 /tmp/RtmpEtn5S5/seekr-example/extdata/… TRUE     TRUE                 NA         NA                NA               NA               NA             
#> 8 /tmp/RtmpEtn5S5/seekr-example/extdata/… TRUE     TRUE                 NA         NA                NA               NA               NA             
#> 9 /tmp/RtmpEtn5S5/seekr-example/extdata/… TRUE     TRUE                 NA         NA                NA               NA               NA
```

The order of exclude functions matters. They are evaluated in the order
in which they appear in `exclude`, so changing that order can change
which exclusion reason is recorded first. It can also matter for
performance: computationally expensive functions are usually better
placed near the end.

## Find matches

Now that we have selected the files we want to search, we can look for
matches with
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md).

The two central arguments are `pattern` and `replacement`. `pattern`
defines what to look for. `replacement` is optional: when provided, it
prepares replacement values for later, but it does not modify any file.
Files are only modified when
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
is called.

[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)
also has a few arguments that control how files are read and how matches
are recorded:

- `context` controls how many lines before and after each match are
  stored in the `seekr_match` vector.
- `encoding` controls how files are decoded. By default, files are read
  as UTF-8. Set `encoding = NULL` if you want `seekr` to try to detect
  the encoding with
  [`stringi::stri_enc_detect()`](https://rdrr.io/pkg/stringi/man/stri_enc_detect.html).

### Regular expression patterns

Here we look for function names composed of two words separated by an
underscore followed by `<- function`.

``` r

matches <- match_files(filtered, "([a-z]+)_([a-z]+)(?= <- function)")
matches
#> <seekr::match[5]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] ->  1 | add_one <- function(x) {
#> [2] ->  9 | say_hello <- function(name) {
#> 
#> script2.R [3]
#> [3] ->  2 | mean_safe <- function(x) {
#> [4] ->  7 | sd_safe <- function(x) {
#> [5] -> 12 | print_vector <- function(v) {
```

A plain character string is automatically treated as an ICU regular
expression via
[`stringr::regex()`](https://stringr.tidyverse.org/reference/modifiers.html),
as in `stringr`, except that `multiline` is set to `TRUE` by default.
Because `multiline = TRUE`, anchors such as `^` and `$` can match line
boundaries inside a file.

These two calls are therefore equivalent.

``` r

match_files(filtered, "pattern")

match_files(
  filtered,
  regex(
    "pattern",
    ignore_case = FALSE,
    multiline = TRUE,
    comments = FALSE,
    dotall = FALSE
  )
)
```

For more control, pass a `stringr` pattern object directly. For example,
we can make the search case-insensitive.

``` r

match_files(filtered, regex("FUNCTION", ignore_case = TRUE))
#> <seekr::match[7]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [3]
#> [1] ->  1 | add_one <- function(x) {
#> [2] ->  5 | capitalize <- function(txt) {
#> [3] ->  9 | say_hello <- function(name) {
#> 
#> script2.R [4]
#> [4] ->  1 | # TODO: optimize this function
#> [5] ->  2 | mean_safe <- function(x) {
#> [6] ->  7 | sd_safe <- function(x) {
#> [7] -> 12 | print_vector <- function(v) {
```

For more details about regular expressions in `stringr`, see the
[stringr regular expressions
documentation](https://stringr.tidyverse.org/articles/regular-expressions.html).

### Literal text patterns

If you want to search for literal text instead of a regular expression,
use
[`stringr::fixed()`](https://stringr.tidyverse.org/reference/modifiers.html)
or
[`stringr::coll()`](https://stringr.tidyverse.org/reference/modifiers.html)
which are also re-exported by `seekr`.

``` r

match_files(filtered, fixed("function(x)"))
#> <seekr::match[3]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [1]
#> [1] -> 1 | add_one <- function(x) {
#> 
#> script2.R [2]
#> [2] -> 2 | mean_safe <- function(x) {
#> [3] -> 7 | sd_safe <- function(x) {
match_files(filtered, coll("function(x)"))
#> <seekr::match[3]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [1]
#> [1] -> 1 | add_one <- function(x) {
#> 
#> script2.R [2]
#> [2] -> 2 | mean_safe <- function(x) {
#> [3] -> 7 | sd_safe <- function(x) {
```

This is useful when the text contains characters that would otherwise
have a special meaning in a regular expression. Note that
[`stringr::fixed()`](https://stringr.tidyverse.org/reference/modifiers.html)
performs bytewise matching, so
[`stringr::coll()`](https://stringr.tidyverse.org/reference/modifiers.html)
may be more appropriate for locale-sensitive text.

For more details about the different pattern engines in `stringr`, see
the [stringr
introduction](https://stringr.tidyverse.org/articles/stringr.html#engines).

## Prepare replacements

Searching and replacing are separate steps in `seekr`.

You can prepare replacements when searching, but files are not modified
until you call
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).
This makes it possible to search first, inspect the result, filter
matches, update replacements if needed, and only then write changes to
disk.

`seekr` offers five ways to prepare replacements during the matching
step:

- `NULL`, the default, to plan no replacement.
- A plain string, used literally as replacement text.
- A string with backreferences of the form `\\1`, `\\2`, and so on,
  replaced with the corresponding capture groups from `pattern`.
- A function, called once per file with a character vector of all
  matches found in that file, and expected to return a character vector
  of the same length, such as
  [`toupper()`](https://rdrr.io/r/base/chartr.html).
- A function wrapped with
  [`with_capture_groups_matrix()`](https://smartiing.github.io/seekr/reference/with_capture_groups_matrix.md),
  called once per file with a character matrix where the first column is
  the full match and the remaining columns are the capture groups.

### Literal replacements

The simplest replacement is a string.

``` r

match_files(
  filtered,
  pattern = "safe",
  replacement = "checked"
)
#> <seekr::match[2]> 1 source
#> /tmp/RtmpEtn5S5/seekr-example/extdata/script2.R [2]
#> [1] -- 2 | mean_safe <- function(x) {
#>     ++ 2 | mean_checked <- function(x) {
#> [2] -- 7 | sd_safe <- function(x) {
#>     ++ 7 | sd_checked <- function(x) {
```

Here, every match of `"safe"` gets the same planned replacement:
`"checked"`.

### Capture groups

Replacement strings can also refer to capture groups from a regular
expression.

Here, we reverse the two parts of each function name.

``` r

match_files(
  filtered, 
  pattern = "([a-z]+)_([a-z]+)(?= <- function)", 
  replacement = "\\2_\\1"
)
#> <seekr::match[5]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | one_add <- function(x) {
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | hello_say <- function(name) {
#> 
#> script2.R [3]
#> [3] --  2 | mean_safe <- function(x) {
#>     ++  2 | safe_mean <- function(x) {
#> [4] --  7 | sd_safe <- function(x) {
#>     ++  7 | safe_sd <- function(x) {
#> [5] -- 12 | print_vector <- function(v) {
#>     ++ 12 | vector_print <- function(v) {
```

### Function replacements

A replacement can also be a function. The function receives a character
vector of matched texts and must return one replacement value per match.
It is vectorized over the matches found in a file; it is not called
separately for each individual match.

``` r

match_files(
  filtered, 
  pattern = "([a-z]+)_([a-z]+)(?= <- function)", 
  replacement = toupper
)
#> <seekr::match[5]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | ADD_ONE <- function(x) {
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | SAY_HELLO <- function(name) {
#> 
#> script2.R [3]
#> [3] --  2 | mean_safe <- function(x) {
#>     ++  2 | MEAN_SAFE <- function(x) {
#> [4] --  7 | sd_safe <- function(x) {
#>     ++  7 | SD_SAFE <- function(x) {
#> [5] -- 12 | print_vector <- function(v) {
#>     ++ 12 | PRINT_VECTOR <- function(v) {
```

### Capture group matrix replacements

For more complex replacements, wrap a function with
[`with_capture_groups_matrix()`](https://smartiing.github.io/seekr/reference/with_capture_groups_matrix.md).

The function receives the capture group matrix returned by the matching
engine. The first column is the full match, and the following columns
are the capture groups.

``` r

repl_fn <- function(M) paste0(toupper(M[, 3L]), "_", tolower(M[, 2L]))
repl_fn <- with_capture_groups_matrix(repl_fn)

match_files(
  filtered, 
  pattern = "([a-z]+)_([a-z]+)(?= <- function)", 
  replacement = repl_fn
)
#> <seekr::match[5]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | ONE_add <- function(x) {
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | HELLO_say <- function(name) {
#> 
#> script2.R [3]
#> [3] --  2 | mean_safe <- function(x) {
#>     ++  2 | SAFE_mean <- function(x) {
#> [4] --  7 | sd_safe <- function(x) {
#>     ++  7 | SAFE_sd <- function(x) {
#> [5] -- 12 | print_vector <- function(v) {
#>     ++ 12 | VECTOR_print <- function(v) {
```

This is useful when the replacement logic depends on several captured
parts of the match.

For workflows where text has already been read, or where you want to
control reading and writing yourself, see the [Working with text
article](https://smartiing.github.io/seekr/articles/working-with-text.md).

## Use `seek()` and `seekr()`

The previous sections used the lower-level steps explicitly. For common
workflows,
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md) combines
listing, filtering, and matching in one call.
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) is a
shortcut around
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md) with R,
R Markdown, and Quarto extensions selected by default.

``` r

files <- list_files()
filtered <- filter_files(files, extension = "R")
x <- match_files(filtered, "(\\w+)_(\\w+)(?= <- function)", "\\2_\\1")

y <- seekr("(\\w+)_(\\w+)(?= <- function)", "\\2_\\1")

identical(x, y)
#> [1] TRUE
```

Note that:

- the vector of matches returned by
  [`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) also
  contains the
  [`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md)
  attribute,
- when no matches are found, the vector returned by
  [`seek()`](https://smartiing.github.io/seekr/reference/seek.md)/[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md)
  also contains an
  [`empty_stage()`](https://smartiing.github.io/seekr/reference/empty_stage.md)
  attribute that helps explain where the workflow became empty.

## Inspect the `seekr_match` vector

The result of
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md),
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md), and
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) is a
`seekr_match` vector.

A `seekr_match` vector behaves like a vector of matches, but each match
also stores fields such as the file path, match location, matched text,
planned replacement, surrounding context, and encoding.

``` r

str(x)
#> <seekr::match[5]> vctrs::rcrd
#> path        <chr> "/tmp/RtmpEtn5S5/seekr-example/extdata/script1.R", "/tmp/RtmpEtn5S5/seekr-example/extdata/script1.R", "/tmp/RtmpEtn5S5/seekr-example…
#> start_line  <int> 1, 9, 2, 7, 12
#> end_line    <int> 1, 9, 2, 7, 12
#> start       <int> 1, 107, 32, 119, 202
#> end         <int> 7, 115, 40, 125, 213
#> start_col   <int> 1, 1, 1, 1, 1
#> end_col     <int> 7, 9, 9, 7, 12
#> match       <chr> "add_one", "say_hello", "mean_safe", "sd_safe", "print_vector"
#> replacement <chr> "one_add", "hello_say", "safe_mean", "safe_sd", "vector_print"
#> before      <chr> NA, "\ncapitalize <- function(txt) {\n  toupper(substr(txt, 1, 1))\n}\n", "# TODO: optimize this function", "mean_safe <- function(x…
#> line        <chr> "add_one <- function(x) {", "say_hello <- function(name) {", "mean_safe <- function(x) {", "sd_safe <- function(x) {", "print_vector…
#> after       <chr> "  return(x + 1)\n}\n\ncapitalize <- function(txt) {\n  toupper(substr(txt, 1, 1))", "  paste('Hello', name)\n}\n", "  if (length(x)…
#> encoding    <chr> "UTF-8", "UTF-8", "UTF-8", "UTF-8", "UTF-8"
#> hash        <chr> "e4cc5c4031699a911e6d5029cce6d71c", "e4cc5c4031699a911e6d5029cce6d71c", "036951bf4066a0b69595b7a0d9d0eb96", "036951bf4066a0b69595b7a…
```

You can inspect the available fields with
[`fields()`](https://vctrs.r-lib.org/reference/fields.html).

``` r

fields(x)
#>  [1] "path"        "start_line"  "end_line"    "start"       "end"         "start_col"   "end_col"     "match"       "replacement" "before"     
#> [11] "line"        "after"       "encoding"    "hash"
```

Individual fields can be accessed with
[`field()`](https://vctrs.r-lib.org/reference/fields.html).

``` r

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
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
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

Use [`print()`](https://rdrr.io/r/base/print.html) to inspect matches
with surrounding context and preview replacements before modifying
files.

``` r

print(x, context = c(0L, 3L))
#> <seekr::match[5]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | one_add <- function(x) {
#>         2 |   return(x + 1)
#>         3 | }
#>         4 | 
#> 
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | hello_say <- function(name) {
#>        10 |   paste('Hello', name)
#>        11 | }
#>        12 | 
#> 
#> script2.R [3]
#> [3] --  2 | mean_safe <- function(x) {
#>     ++  2 | safe_mean <- function(x) {
#>         3 |   if (length(x) == 0) return(NA)
#>         4 |   mean(x, na.rm = TRUE)
#>         5 | }
#> 
#> [4] --  7 | sd_safe <- function(x) {
#>     ++  7 | safe_sd <- function(x) {
#>         8 |   if (length(x) <= 1) return(NA)
#>         9 |   sd(x, na.rm = TRUE)
#>        10 | }
#> 
#> [5] -- 12 | print_vector <- function(v) {
#>     ++ 12 | vector_print <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
#>        14 | }
#>        15 | 
```

In terminals that support OSC8 hyperlinks, printed file locations can
also be clickable.

For more on why `seekr` represents search results this way, see the
[Design choices
article](https://smartiing.github.io/seekr/articles/design-choices.md).

## Filter matches

Because a `seekr_match` is a vector, it can be subset like any other R
vector.

``` r

x[!grepl("safe", field(x, "match"))]
#> <seekr::match[3]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | one_add <- function(x) {
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | hello_say <- function(name) {
#> 
#> script2.R [1]
#> [3] -- 12 | print_vector <- function(v) {
#>     ++ 12 | vector_print <- function(v) {
```

However,
[`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
is usually more convenient. It evaluates expressions directly on the
fields of the `seekr_match` vector.

``` r

xf <- x |> filter_match(!grepl("safe", match))
xf
#> <seekr::match[3]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | one_add <- function(x) {
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | hello_say <- function(name) {
#> 
#> script2.R [1]
#> [3] -- 12 | print_vector <- function(v) {
#>     ++ 12 | vector_print <- function(v) {
```

## Use tabular workflows

For many workflows,
[`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
and [`field()`](https://vctrs.r-lib.org/reference/fields.html) are
enough.

For more complex operations, it can be useful to convert a `seekr_match`
vector to a a data frame, work with it using tabular tools, and then
convert it back to a `seekr_match` vector before replacing files.

This is especially useful for grouped summaries, joins, group-aware
filtering, or replacement logic that might be easier to express in a
tabular workflow.

When converting back,
[`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
validates that the data frame still contains the fields required to
reconstruct a valid `seekr_match` vector. This makes it possible to use
tabular workflows while still returning to the main `seekr` replacement
workflow.

For examples, see the
[`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
documentation and the [Tabular workflows
article](https://smartiing.github.io/seekr/articles/tabular-workflows.md).

## Update replacements after inspection

You do not need to decide every replacement when searching.

The `replacement` field can be set or updated after matches have been
inspected or filtered.

``` r

field(xf, "replacement") = toupper(field(xf, "replacement"))
print(xf, context = c(0, 2))
#> <seekr::match[3]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | ONE_ADD <- function(x) {
#>         2 |   return(x + 1)
#>         3 | }
#> 
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | HELLO_SAY <- function(name) {
#>        10 |   paste('Hello', name)
#>        11 | }
#> 
#> script2.R [1]
#> [3] -- 12 | print_vector <- function(v) {
#>     ++ 12 | VECTOR_PRINT <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
#>        14 | }
```

This makes it possible to search broadly, inspect the result, keep only
the matches that matter, and then decide what each selected match should
become.

## Replace selected matches

**Important:**
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
writes modified files in UTF-8. If you need to control how files are
written, use the workflow described in the [Working with text
article](https://smartiing.github.io/seekr/articles/working-with-text.md).

When the selected matches and replacements look right, we can call
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
which starts from the current `seekr_match` vector.

If you found five matches, filtered the vector down to three matches,
and updated their replacements, only those three remaining matches are
replaced, each with its corresponding replacement.

Before writing,
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
checks that every selected match has a replacement and that the hash of
each affected file still matches the hash recorded when the
`seekr_match` vector was created. If a file has changed since the
search, replacement stops before writing that file, and the search
should be run again on the current file contents.

If you created several `seekr_match` vectors from the same file state,
combine them before replacing. After the first replacement, the file
hash changes, so a second call using matches from the old file state
will fail. For example, use `replace_files(c(x, y))` instead of calling
`replace_files(x)` and then `replace_files(y)`.

By default, `backup = TRUE`, so each file that will be modified is
backed up before it is written. A `description` can be provided to make
the backup easier to identify later. The backup directory can also be
changed with `backup_dir` or the `seekr.backup_dir` option.

``` r

replace_files(
  xf, 
  description = "Inverse function names"
)
```

We can now see that our matches have been replaced.

``` r

seekr("(?i)([a-z]+)_([a-z]+)(?= <- function)") |> 
  print(context = c(0L, 3L))
#> <seekr::match[5]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] ->  1 | ONE_ADD <- function(x) {
#>         2 |   return(x + 1)
#>         3 | }
#>         4 | 
#> 
#> [2] ->  9 | HELLO_SAY <- function(name) {
#>        10 |   paste('Hello', name)
#>        11 | }
#>        12 | 
#> 
#> script2.R [3]
#> [3] ->  2 | mean_safe <- function(x) {
#>         3 |   if (length(x) == 0) return(NA)
#>         4 |   mean(x, na.rm = TRUE)
#>         5 | }
#> 
#> [4] ->  7 | sd_safe <- function(x) {
#>         8 |   if (length(x) <= 1) return(NA)
#>         9 |   sd(x, na.rm = TRUE)
#>        10 | }
#> 
#> [5] -> 12 | VECTOR_PRINT <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
#>        14 | }
#>        15 | 
```

## Restore files

After modifying files, backups can be inspected with
[`list_backups()`](https://smartiing.github.io/seekr/reference/backups.md),
and the most recent backup can be retrieved with
[`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md).

``` r

bck <- last_backup()
bck
#> # A tibble: 2 × 9
#>      id created_at          operation description            original                                       backup original_exists backup_exists  size
#>   <int> <dttm>              <chr>     <chr>                  <chr>                                          <chr>  <lgl>           <lgl>         <fs:>
#> 1     1 2026-07-14 15:02:32 replace   Inverse function names /tmp/RtmpEtn5S5/seekr-example/extdata/script1… /tmp/… TRUE            TRUE            161
#> 2     1 2026-07-14 15:02:32 replace   Inverse function names /tmp/RtmpEtn5S5/seekr-example/extdata/script2… /tmp/… TRUE            TRUE            279
```

Use
[`restore_files()`](https://smartiing.github.io/seekr/reference/restore_files.md)
to restore the previous file contents.

``` r

restore_files(
  from = bck$backup, 
  to = bck$original,
  description = "restore after reversing function names by mistake"
)
#> ℹ Creating a backup of the current version of each existing destination file before restoring it.
#> ℹ This ensures you can revert to the state before restoration if needed.
```

By default, restoring files also creates a backup before writing, so
both operations remain available in the backup history. This makes it
possible to undo a replacement, while still keeping a record of the
files that were present just before the restore operation.

``` r

list_backups()
#> # A tibble: 4 × 9
#>      id created_at          operation description                                       original            backup original_exists backup_exists  size
#>   <int> <dttm>              <chr>     <chr>                                             <chr>               <chr>  <lgl>           <lgl>         <fs:>
#> 1     2 2026-07-14 15:02:32 restore   restore after reversing function names by mistake /tmp/RtmpEtn5S5/se… /tmp/… TRUE            TRUE            161
#> 2     2 2026-07-14 15:02:32 restore   restore after reversing function names by mistake /tmp/RtmpEtn5S5/se… /tmp/… TRUE            TRUE            279
#> 3     1 2026-07-14 15:02:32 replace   Inverse function names                            /tmp/RtmpEtn5S5/se… /tmp/… TRUE            TRUE            161
#> 4     1 2026-07-14 15:02:32 replace   Inverse function names                            /tmp/RtmpEtn5S5/se… /tmp/… TRUE            TRUE            279
```

After restoring, the original matches are back.

``` r

after_restore <- seekr("([a-z]+)_([a-z]+)(?= <- function)")
print(after_restore, context = c(0L, 3L))
#> <seekr::match[5]> 2 sources
#> Common Path: /tmp/RtmpEtn5S5/seekr-example/extdata
#> 
#> script1.R [2]
#> [1] ->  1 | add_one <- function(x) {
#>         2 |   return(x + 1)
#>         3 | }
#>         4 | 
#> 
#> [2] ->  9 | say_hello <- function(name) {
#>        10 |   paste('Hello', name)
#>        11 | }
#>        12 | 
#> 
#> script2.R [3]
#> [3] ->  2 | mean_safe <- function(x) {
#>         3 |   if (length(x) == 0) return(NA)
#>         4 |   mean(x, na.rm = TRUE)
#>         5 | }
#> 
#> [4] ->  7 | sd_safe <- function(x) {
#>         8 |   if (length(x) <= 1) return(NA)
#>         9 |   sd(x, na.rm = TRUE)
#>        10 | }
#> 
#> [5] -> 12 | print_vector <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
#>        14 | }
#>        15 | 
```
