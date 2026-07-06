# Find matches in files

`match_files()` reads each file, decodes them using `encoding`, finds
`pattern` matches, and captures surrounding `context` lines. A
`replacement` can be provided to stage changes for later application
with
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).
It is the third and final step of the
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md)
pipeline, applied after
[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md)
and
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md).

## Usage

``` r
match_files(
  path,
  pattern,
  replacement = NULL,
  ...,
  context = 5L,
  encoding = "UTF-8",
  .progress = seekr_option("seekr.progress")
)
```

## Arguments

- path:

  A character vector of file paths to read and search.

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
match positions, matched text, optional replacement, context lines,
encoding, and a hash of the searched text used for replacement safety.
Returns an empty
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector when no matches are found.

Files that no longer exist before matching are skipped with a warning.
Files that contain unsupported null bytes are also skipped with a
warning. Other read or decoding errors abort.

## Note

For advanced use cases where you want to search for a pattern in-memory
text, see
[`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md).

## See also

- [`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
  to search for a pattern in in-memory text.

- [`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
  to filter files before matching.

- [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  to apply staged replacements.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
files <- ext_path |> list_files() |> filter_files(extension = "R")

# Search for a pattern
match_files(files, "TODO")
#> <seekr::match[1]> 1 source
#> /home/runner/work/_temp/Library/seekr/extdata/script2.R [1]
#> [1] -> 1 | # TODO: optimize this function
#> 

# Capture more context lines
match_files(files, "TODO", context = 10L)
#> <seekr::match[1]> 1 source
#> /home/runner/work/_temp/Library/seekr/extdata/script2.R [1]
#> [1] -> 1 | # TODO: optimize this function
#> 

# Stage a replacement
match_files(files, "old_fn", replacement = "new_fn")
#> <seekr::match[0]> 0 sources
```
