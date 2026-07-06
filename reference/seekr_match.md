# Create `seekr_match` vectors

A `seekr_match` is an S3 vector built on
[`vctrs::new_rcrd()`](https://vctrs.r-lib.org/reference/new_rcrd.html)
that represents the matches found by
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md),
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md),
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md),
or
[`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md).

Each element corresponds to a single match and stores its source path,
position, matched text, optional replacement, surrounding context lines,
encoding, and a hash of the searched text used for replacement safety.

## Usage

``` r
new_seekr_match(
  path = character(),
  start_line = integer(),
  end_line = integer(),
  start = integer(),
  end = integer(),
  start_col = integer(),
  end_col = integer(),
  match = character(),
  replacement = character(),
  before = character(),
  line = character(),
  after = character(),
  encoding = character(),
  hash = character()
)
```

## Arguments

- path:

  A character vector of source identifiers. For file workflows, these
  are normalized absolute file paths. For
  [`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
  workflows, they may also be non-existing identifiers.

- start_line, end_line:

  Integer vectors. 1-based line numbers where each match begins and
  ends.

- start, end:

  Integer vectors. 1-based absolute character positions where each match
  begins and ends.

- start_col, end_col:

  Integer vectors. 1-based column positions of the match start and end
  within their respective lines.

- match:

  A character vector. The exact text matched.

- replacement:

  A character vector. The staged replacement for each match. `NA`
  indicates no replacement is staged.

- before:

  A character vector. Context lines preceding each match.

- line:

  A character vector. The complete line(s) containing each match.

- after:

  A character vector. Context lines following each match.

- encoding:

  A character vector. The encoding used to read each file.

- hash:

  A character vector. Hash of the searched text, used to check that it
  has not changed before replacement.

## Value

`new_seekr_match()` returns an empty or populated `seekr_match` vector.
`new_seekr_match()` is a low-level constructor intended primarily for
internal use and advanced extensions. In normal usage, create
`seekr_match` vectors with
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md),
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md),
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md),
or
[`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md).

## Fields

Access any field with
[`vctrs::field()`](https://vctrs.r-lib.org/reference/fields.html) which
is re-exported by seekr:

    field(x, "path")
    field(x, "match")

## Methods and functions

`seekr_match` objects support the following S3 methods:

- [print()](https://smartiing.github.io/seekr/reference/print.seekr_match.md):
  displays matches in a formatted view with optional context and
  replacement preview.

- [summary()](https://smartiing.github.io/seekr/reference/summary.seekr_match.md):
  summarizes matches by file, matched text, replacement, extension, and
  encoding.

- [str()](https://smartiing.github.io/seekr/reference/str.seekr_match.md):
  shows the internal field structure with types and sample values.

- [tibble::as_tibble()](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md):
  converts to a tibble for advanced manipulation.

The following functions are also commonly used with `seekr_match`
vectors:

- [`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md):
  converts a tibble back to a `seekr_match` vector.

- [`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md):
  subsets matches using dplyr-style expressions.

- [`sort_within_files()`](https://smartiing.github.io/seekr/reference/sort_within_files.md):
  reorders matches within each file while preserving file order.

## Attributes

In addition to its fields, a `seekr_match` vector returned by
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md) or
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) may
carry two attributes:

- `empty_stage`: when the vector is empty, indicates which pipeline step
  produced no output. Retrieve with
  [`empty_stage()`](https://smartiing.github.io/seekr/reference/empty_stage.md).

- `exclusions`: when files were removed during filtering, a data frame
  detailing which files were excluded and by which function. Retrieve
  with
  [`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md).

These attributes are dropped when combining `seekr_match` vectors.

## See also

- [`seek()`](https://smartiing.github.io/seekr/reference/seek.md) and
  [`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) to
  search for matches and produce `seekr_match` vectors.

- [`print.seekr_match()`](https://smartiing.github.io/seekr/reference/print.seekr_match.md)
  and
  [`summary.seekr_match()`](https://smartiing.github.io/seekr/reference/summary.seekr_match.md)
  to inspect results.

- [`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
  to subset matches before replacing.

- [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  to apply staged replacements.

- [`empty_stage()`](https://smartiing.github.io/seekr/reference/empty_stage.md)
  and
  [`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md)
  to diagnose empty results.

## Examples

``` r
# Produce a seekr_match vector
ext_path <- system.file("extdata", package = "seekr")
x <- seekr("function", toupper, path = ext_path)

# Access a field
field(x, "path")
#> [1] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"
#> [2] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"
#> [3] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"
#> [4] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"
#> [5] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"
#> [6] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"
#> [7] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"
field(x, "match")
#> [1] "function" "function" "function" "function" "function" "function" "function"

# Subset
head(x, 3)
#> <seekr::match[3]> 1 source
#> /home/runner/work/_temp/Library/seekr/extdata/script1.R [3]
#> [1] -- 1 | add_one <- function(x) {
#>     ++ 1 | add_one <- FUNCTION(x) {
#> [2] -- 5 | capitalize <- function(txt) {
#>     ++ 5 | capitalize <- FUNCTION(txt) {
#> [3] -- 9 | say_hello <- function(name) {
#>     ++ 9 | say_hello <- FUNCTION(name) {
#> 

# Combine two seekr_match vectors
y <- seekr("Hello", path = ext_path)
c(x, y)
#> <seekr::match[8]> 2 sources
#> ℹ Matches were reordered by file and position for printing. Use `sort()` to order matches globally by file and location, Use `sort_within_files()` to preserve the file order of appearance.
#> Common Path: /home/runner/work/_temp/Library/seekr/extdata
#> 
#> script1.R [4]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | add_one <- FUNCTION(x) {
#> [2] --  5 | capitalize <- function(txt) {
#>     ++  5 | capitalize <- FUNCTION(txt) {
#> [3] --  9 | say_hello <- function(name) {
#>     ++  9 | say_hello <- FUNCTION(name) {
#> [8] -> 10 |   paste('Hello', name)
#> 
#> script2.R [4]
#> [4] --  1 | # TODO: optimize this function
#>     ++  1 | # TODO: optimize this FUNCTION
#> [5] --  2 | mean_safe <- function(x) {
#>     ++  2 | mean_safe <- FUNCTION(x) {
#> [6] --  7 | sd_safe <- function(x) {
#>     ++  7 | sd_safe <- FUNCTION(x) {
#> [7] -- 12 | print_vector <- function(v) {
#>     ++ 12 | print_vector <- FUNCTION(v) {
#> 
```
