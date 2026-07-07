# Find matches in text files

`seek()` searches text files for a pattern and returns a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector. The result can be inspected, filtered, and passed to
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
to apply replacements.

`seekr()` is a convenience wrapper around `seek()` that restricts the
search to R, R Markdown, and Quarto files (`.R`, `.Rmd`, `.qmd`).

[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md),
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md),
and
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)
are the three building blocks of `seek()`. They can be called
individually when you need more control over each step.

### Steps

- **[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md)**
  starts from `path` and `recurse`s into subdirectories to list files.
  By default, not `all` files are listed, with hidden files and
  directories excluded.

- **[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)**
  keeps files matching `extension` and `path_pattern` and not exceeding
  `max_file_size`. Finally, the `exclude` functions are applied to the
  remaining files, discarding common non-text or irrelevant files by
  default.

- **[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)**
  reads each file, decodes them using `encoding`, finds `pattern`
  matches, and captures surrounding `context` lines. A `replacement` can
  be provided to stage changes for later application with
  [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).

## Usage

``` r
seek(
  pattern,
  replacement = NULL,
  ...,
  path = ".",
  recurse = TRUE,
  all = FALSE,
  extension = NULL,
  path_pattern = NULL,
  max_file_size = Inf,
  exclude = seekr::exclude_functions,
  context = 5L,
  encoding = "UTF-8",
  .progress = seekr_option("seekr.progress")
)

seekr(
  pattern,
  replacement = NULL,
  ...,
  path = ".",
  recurse = TRUE,
  all = FALSE,
  path_pattern = NULL,
  max_file_size = Inf,
  exclude = seekr::exclude_functions,
  context = 5L,
  encoding = "UTF-8",
  .progress = seekr_option("seekr.progress")
)
```

## Arguments

- pattern:

  Pattern to search for, matched using
  [stringr](https://stringr.tidyverse.org/reference/stringr-package.html)
  (ICU regular expressions). Either:

  - A string, automatically wrapped as
    [`stringr::regex()`](https://stringr.tidyverse.org/reference/modifiers.html)
    with `ignore_case = FALSE`, `multiline = TRUE`, `comments = FALSE`,
    and `dotall = FALSE`.

  - A `stringr_pattern` object such as
    [`stringr::regex()`](https://stringr.tidyverse.org/reference/modifiers.html),
    [`stringr::fixed()`](https://stringr.tidyverse.org/reference/modifiers.html),
    or
    [`stringr::coll()`](https://stringr.tidyverse.org/reference/modifiers.html),
    used as-is for more control.

- replacement:

  Replacement to associate with each match. Replacements are computed
  immediately during the search and stored in the result. Either:

  - `NULL` (default): no replacement.
    [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
    cannot be called without setting replacements first.

  - A plain string, used literally as replacement text.

  - A string with backreferences of the form `\1`, `\2`, etc., replaced
    with the corresponding capture group from `pattern`.

  - A function, called once per file with a character vector of all
    matches found in that file, and expected to return a character
    vector of the same length (e.g.
    [toupper](https://rdrr.io/r/base/chartr.html)).

  - A function wrapped with
    [`with_capture_groups_matrix()`](https://smartiing.github.io/seekr/reference/with_capture_groups_matrix.md),
    called once per file with a character matrix where the first column
    is the full match and the remaining columns are the capture groups.

- ...:

  These dots are for future extensions and must be empty.

- path:

  A character vector of one or more existing directories to search in.
  Defaults to `"."` (the current working directory).

- recurse:

  Controls how deep the directory traversal goes to list files. Either:

  - `TRUE` (default): recurse into all subdirectories.

  - `FALSE`: only list files at the top level of each directory in
    `path`.

  - A positive integer: limit recursion to that many levels deep.

- all:

  Whether to list hidden files and directories. Default is `FALSE`.

- extension:

  Optional character vector of file extensions to keep. Either:

  - `NULL` (default): no filtering by extension; all extensions are
    kept.

  - A character vector of extensions to keep, with or without a leading
    dot (e.g. `c("R", ".Rmd", "qmd")`).

  Extensions are normalized before matching: leading dots are stripped,
  matching is case-insensitive, and duplicates are ignored. Only the
  last component of compound extensions is used (e.g. `"tar.gz"` uses
  `"gz"`), with a warning.

- path_pattern:

  Optional pattern applied to filter normalized file paths (see
  [`as_seekr_path()`](https://smartiing.github.io/seekr/reference/as_seekr_path.md)).
  Either:

  - `NULL` (default): no filtering by path.

  - A string, interpreted as a regular expression via
    [`stringr::regex()`](https://stringr.tidyverse.org/reference/modifiers.html).

  - A `stringr_pattern` object such as
    [`stringr::regex()`](https://stringr.tidyverse.org/reference/modifiers.html)
    or
    [`stringr::fixed()`](https://stringr.tidyverse.org/reference/modifiers.html).

- max_file_size:

  Maximum file size in bytes. Files larger than this value are excluded.
  Default is `Inf`, meaning no files are excluded by size. Zero and
  negative values are treated as `Inf`.

- exclude:

  Named list of functions used to exclude unwanted files during
  filtering. Either:

  - `NULL`, to disable additional exclude functions.

  - A named list of functions, each taking a character vector of
    normalized file paths and returning a logical vector of the same
    length, where `TRUE` means the file should be excluded.

  Defaults to
  [exclude_functions](https://smartiing.github.io/seekr/reference/exclude_functions.md),
  which excludes common non-text or irrelevant files.

- context:

  Number of surrounding lines to capture around each match. Either:

  - A single non-negative integer (default: `5L`): captures the same
    number of lines before and after each match.

  - A pair of non-negative integers `c(before, after)`: captures
    `before` lines before and `after` lines after each match.

- encoding:

  Encoding used to decode file content during the matching step. Either:

  - A single string (default: `"UTF-8"`), applied to all files.

  - `NULL`: encoding is guessed for each file individually using
    [`stringi::stri_enc_detect()`](https://rdrr.io/pkg/stringi/man/stri_enc_detect.html),
    falling back to `"UTF-8"` when detection fails.

  Note:
  [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  always writes files in UTF-8. A warning is issued once per session
  when any file is read with a non-UTF-8 encoding. By default,
  [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  refuses to write those matches unless `allow_encoding_change = TRUE`
  is set.

- .progress:

  Whether to display progress messages. Default is `TRUE` in interactive
  sessions and `FALSE` otherwise (see
  [`rlang::is_interactive()`](https://rlang.r-lib.org/reference/is_interactive.html)).
  Can be set globally with `options(seekr.progress = FALSE)`.

## Value

A
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector. Each element represents one match and carries the file path,
match position, matched text, optional replacement, context lines,
encoding, and a hash of the searched text used for replacement safety.
The vector is always returned, even when empty.

An attribute `"exclusions"` is attached to the result after filtering,
containing a data frame with one row per input file and one column per
exclusion function, detailing which files were excluded and why.
Retrieve it with
[`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md).

If the result is empty, use
[`empty_stage()`](https://smartiing.github.io/seekr/reference/empty_stage.md)
to see whether the pipeline became empty during input, listing,
filtering, or matching.

## See also

- [seekr_match](https://smartiing.github.io/seekr/reference/seekr_match.md)
  for the match object structure and available methods.

- [`print.seekr_match()`](https://smartiing.github.io/seekr/reference/print.seekr_match.md)
  and
  [`summary.seekr_match()`](https://smartiing.github.io/seekr/reference/summary.seekr_match.md)
  to inspect results.

- [`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
  to subset matches.

- [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  to apply replacements.

## Examples

``` r
# Create a small temporary project to search in
example_dir <- tempfile("seekr-example")
dir.create(example_dir)
dir.create(file.path(example_dir, "R"))
dir.create(file.path(example_dir, "tests"))
dir.create(file.path(example_dir, "data"))

writeLines(
  c(
    "old_fn <- function(x) {",
    "  # TODO: rename foo",
    "  foo + x",
    "}"
  ),
  file.path(example_dir, "R", "code.R")
)

writeLines(
  c(
    "test_that('foo works', {",
    "  # TODO: update test",
    "  expect_equal(foo, 1)",
    "})"
  ),
  file.path(example_dir, "tests", "test-code.R")
)

writeLines(
  c(
    "name,value",
    "foo,1",
    "bar,2"
  ),
  file.path(example_dir, "data", "values.csv")
)

# seek() is built from three lower-level functions
files <- list_files(example_dir)
filtered <- filter_files(files, extension = "R", path_pattern = "/R/")
x <- match_files(filtered, "foo", "bar")

# These functions can be piped
y <-
  example_dir |>
  list_files() |>
  filter_files(extension = "R", path_pattern = "/R/") |>
  match_files("foo", "bar")

identical(x, y)
#> [1] TRUE

# This is equivalent to the seek() call below
z <- seek("foo", "bar", path = example_dir, extension = "R", path_pattern = "/R/")
identical(y, z)
#> [1] TRUE

# Search for a pattern in all text files
x <- seek("TODO", path = example_dir)
print(x)
#> <seekr::match[2]> 2 sources
#> Common Path: /tmp/RtmpryISCg/seekr-example1a0b5ef82c4
#> 
#> R/code.R [1]
#> [1] -> 2 |   # TODO: rename foo
#> 
#> tests/test-code.R [1]
#> [2] -> 2 |   # TODO: update test
#> 

# Search only in R files
seek("TODO", path = example_dir, extension = "R")
#> <seekr::match[2]> 2 sources
#> Common Path: /tmp/RtmpryISCg/seekr-example1a0b5ef82c4
#> 
#> R/code.R [1]
#> [1] -> 2 |   # TODO: rename foo
#> 
#> tests/test-code.R [1]
#> [2] -> 2 |   # TODO: update test
#> 

# Search only in a specific subfolder
seek("TODO", path = example_dir, path_pattern = "/R/")
#> <seekr::match[1]> 1 source
#> /tmp/RtmpryISCg/seekr-example1a0b5ef82c4/R/code.R [1]
#> [1] -> 2 |   # TODO: rename foo
#> 

# seekr() is a shortcut for searching R, R Markdown, and Quarto files
seekr("old_fn", path = example_dir)
#> <seekr::match[1]> 1 source
#> /tmp/RtmpryISCg/seekr-example1a0b5ef82c4/R/code.R [1]
#> [1] -> 1 | old_fn <- function(x) {
#> 

# Stage a plain string replacement
x <- seek("old_fn", "new_fn", path = example_dir)
x
#> <seekr::match[1]> 1 source
#> /tmp/RtmpryISCg/seekr-example1a0b5ef82c4/R/code.R [1]
#> [1] -- 1 | old_fn <- function(x) {
#>     ++ 1 | new_fn <- function(x) {
#> 

# Stage replacements with a function
x <- seek(
  "foo|bar",
  replacement = function(x) ifelse(x == "foo", "bar", "foo"),
  path = example_dir
)
x
#> <seekr::match[6]> 3 sources
#> Common Path: /tmp/RtmpryISCg/seekr-example1a0b5ef82c4
#> 
#> R/code.R [2]
#> [1] -- 2 |   # TODO: rename foo
#>     ++ 2 |   # TODO: rename bar
#> [2] -- 3 |   foo + x
#>     ++ 3 |   bar + x
#> 
#> data/values.csv [2]
#> [3] -- 2 | foo,1
#>     ++ 2 | bar,1
#> [4] -- 3 | bar,2
#>     ++ 3 | foo,2
#> 
#> tests/test-code.R [2]
#> [5] -- 1 | test_that('foo works', {
#>     ++ 1 | test_that('bar works', {
#> [6] -- 3 |   expect_equal(foo, 1)
#>     ++ 3 |   expect_equal(bar, 1)
#> 

# Stage replacements after searching
x <- seekr("foo|bar", path = example_dir)
field(x, "replacement") <- ifelse(field(x, "match") == "foo", "bar", "foo")
x
#> <seekr::match[4]> 2 sources
#> Common Path: /tmp/RtmpryISCg/seekr-example1a0b5ef82c4
#> 
#> R/code.R [2]
#> [1] -- 2 |   # TODO: rename foo
#>     ++ 2 |   # TODO: rename bar
#> [2] -- 3 |   foo + x
#>     ++ 3 |   bar + x
#> 
#> tests/test-code.R [2]
#> [3] -- 1 | test_that('foo works', {
#>     ++ 1 | test_that('bar works', {
#> [4] -- 3 |   expect_equal(foo, 1)
#>     ++ 3 |   expect_equal(bar, 1)
#> 

# Create a temporary backup directory
backup_dir <- tempfile("seekr-backup")
dir.create(backup_dir)

# Apply replacements after inspection
replace_files(x, backup_dir = backup_dir)

# Restore files from the latest backup
bck <- last_backup(backup_dir = backup_dir)
restore_files(from = bck$backup, to = bck$original, backup_dir = backup_dir)
#> ℹ Creating a backup of the current version of each existing destination file
#>   before restoring it.
#> ℹ This ensures you can revert to the state before restoration if needed.

# See which files were excluded
exclusions(x)
#> # A tibble: 3 × 7
#>   path                excluded exclude_by_extension is_git_dir is_dependency_dir
#>   <chr>               <lgl>    <lgl>                <lgl>      <lgl>            
#> 1 /tmp/RtmpryISCg/se… FALSE    FALSE                FALSE      FALSE            
#> 2 /tmp/RtmpryISCg/se… TRUE     TRUE                 NA         NA               
#> 3 /tmp/RtmpryISCg/se… FALSE    FALSE                FALSE      FALSE            
#> # ℹ 2 more variables: is_minified_file <lgl>, is_not_text_mime <lgl>

# empty_stage() explains where the pipeline became empty
dir.create(file.path(example_dir, "empty"))

empty_stage(seek("foo", path = character()))
#> [1] "input"
empty_stage(seek("foo", path = file.path(example_dir, "empty")))
#> [1] "list"
empty_stage(seek("foo", path = example_dir, extension = "dummy"))
#> Use `exclusions()` to understand why all files were excluded.
#> This message is displayed once per session.
#> [1] "filter"
empty_stage(seek("missing_pattern", path = example_dir))
#> [1] "match"

# Remove the two temporary directories
unlink(backup_dir, recursive = TRUE)
unlink(example_dir, recursive = TRUE)
```
