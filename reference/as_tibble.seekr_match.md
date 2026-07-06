# Convert `seekr_match` vectors to and from data frames

`as_tibble()` and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) convert a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector into a tibble or plain data frame, with one row per match and one
column per field.

`as_match()` is the reverse: it converts a data frame back into a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector, validating all fields and checking for overlapping matches
within each file before returning.

Together, these functions unlock the full tidyverse toolkit for
manipulating match metadata. A typical pattern is to convert to a
tibble, use
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
or
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
to derive or modify columns, including the `replacement` field, and then
convert back with `as_match()` before calling
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).

## Usage

``` r
# S3 method for class 'seekr_match'
as_tibble(x, ...)

# S3 method for class 'seekr_match'
as.data.frame(x, ...)

as_match(x)
```

## Arguments

- x:

  For
  [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  and [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html): a
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  vector.

  For `as_match()`: a data frame with at least the columns listed in the
  **Fields** section of
  [seekr_match](https://smartiing.github.io/seekr/reference/seekr_match.md).
  Additional columns are silently ignored. All required columns must
  have the correct type: `character` for string fields, `integer` for
  position fields.

- ...:

  Not used. Present for compatibility with S3 generics.

## Value

[`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
returns a `tbl_df`.
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns a
plain `data.frame`. In both cases the result has one row per match and
one column per field (see the **Fields** section of
[seekr_match](https://smartiing.github.io/seekr/reference/seekr_match.md)).

`as_match()` returns a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector. Matches within each file are sorted by position. Overlapping or
incoherent matches within the same file cause an error.

Note: the `empty_stage` and `exclusions` attributes of the original
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
vector are not preserved through the conversion.

## See also

- [seekr_match](https://smartiing.github.io/seekr/reference/seekr_match.md)
  for the list of available fields.

- [`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
  for simpler subsetting that does not require conversion.

- [`vctrs::field()`](https://vctrs.r-lib.org/reference/fields.html) to
  access or modify a single field in place.

- [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  to apply staged replacements after converting back.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)
ext_path <- system.file("extdata", package = "seekr")
x <- seekr("TODO", path = ext_path)

# Convert to tibble
df <- as_tibble(x)
df

# Convert to plain data frame
as.data.frame(x)

# Convert back to seekr_match
as_match(df)

# Set a replacement for all matches
df$replacement <- "DONE"
as_match(df)

# Suppose you want to replace `"foo"` with `"bar"`, but only for the last
# match in each file, and only in files with at least three matches:
x <- seekr("foo", "bar", path = ext_path)

y <-
  x |>
  as_tibble() |>
  mutate(
    ith_match_per_file_rev = n():1L,
    n_match_per_file = n(),
    .by = path
  ) |>
  filter(ith_match_per_file_rev == 1L, n_match_per_file >= 3L) |>
  as_match()

# replace_files(y)
} # }
```
