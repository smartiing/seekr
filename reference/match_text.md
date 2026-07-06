# Find matches in text

`match_text()` is a low-level helper for matching a pattern in text
directly. It does not read from disk. Use
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)
or
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md)/[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md)
for the usual workflow.

## Usage

``` r
match_text(
  text,
  path,
  pattern,
  replacement = NULL,
  ...,
  context = 5L,
  encoding = NA_character_
)
```

## Arguments

- text:

  Text content as a single string.

- path:

  Source identifier associated with `text`. This is stored in the
  resulting
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  object and used later for inspection and diagnostics. It may be a real
  file path, but it does not need to point to an existing file unless
  the result is later passed to
  [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).

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

  Optional encoding metadata associated with `text`. The default is
  `NA_character_`, meaning that no file encoding was recorded. Supply a
  concrete encoding only if the resulting matches should later be passed
  to
  [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).

## Value

A
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector.

## Examples

``` r
text <- "Commodo labore culpa ullamco TODO irure laboris FIXME Lorem sunt sint"
x <- match_text(text = text, path = "lorem.txt", pattern = "TODO")
y <- match_text(text = text, path = "lorem.txt", pattern = "FIXME")
z <- c(x, y)
z
#> <seekr::match[2]> 1 source
#> lorem.txt [2]
#> [1] -> 1 | Commodo labore culpa ullamco TODO irure laboris FIXME Lorem sunt sint
#> [2] -> 1 | Commodo labore culpa ullamco TODO irure laboris FIXME Lorem sunt sint
#> 
```
