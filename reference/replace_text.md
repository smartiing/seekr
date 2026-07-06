# Replace selected matches in text

`replace_text()` is the in-memory counterpart of
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).
It applies the replacements stored in a
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
object to text and returns the modified text.

It does not read files, write files, or create backups. Use
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
for the usual file-based workflow.

## Usage

``` r
replace_text(text, x)
```

## Arguments

- text:

  Text content as a single string.

- x:

  A
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  object with replacement values. All matches in `x` must be associated
  with the same file and must refer to positions in `text`.

## Value

A single character string containing `text` after applying the
replacements stored in `x`.

## Details

`replace_text()` verifies that the current text has the same hash as the
text that was searched when the matches were created. If the text has
changed, replacement is considered unsafe and the function aborts.

Matches are replaced from the end of the file to the beginning, so
earlier replacements do not shift the recorded positions of later
replacements.

`replace_text()` requires `x` to contain matches from a single source,
the one corresponding to text.

## See also

- [`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
  to create matches from already-read text.

- [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  to apply replacements directly to files.

- [`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
  to keep only some matches before replacing.

## Examples

``` r
text <- "hello old_name\nbye old_name"

x <- match_text(
  text = text,
  path = "example.txt",
  pattern = "old_name",
  replacement = "new_name"
)

replace_text(text, x)
#> [1] "hello new_name\nbye new_name"
```
