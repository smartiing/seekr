# Compute replacement string for each match

Handles static and dynamic replacements, including capture group
references.

## Usage

``` r
compute_replacement(
  text,
  pattern,
  match,
  replacement,
  call = rlang::caller_env()
)
```

## Arguments

- text:

  Text content as a single string.

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

- match:

  Matched strings.

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

## Value

A character vector of replacements, one per match.
