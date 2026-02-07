# Prepare Tidy Data Frame from Matched Lines

Constructs a tidy data frame from matched lines across a set of files.
This function takes the output of
[`read_filter_lines()`](https://smartiing.github.io/seekr/reference/read_filter_lines.md)
and returns one row per match, including file path, line number, full
line content, and regex match(es).

## Usage

``` r
prepare_df(files, pattern, lines, path, relative_path, matches)
```

## Arguments

- files:

  A character vector of files to search (only for
  [`seek_in()`](https://smartiing.github.io/seekr/reference/seek.md)).

- pattern:

  A regular expression pattern used to match lines.

- lines:

  A list with `line_number` and `line`, as returned by
  [`read_filter_lines()`](https://smartiing.github.io/seekr/reference/read_filter_lines.md).

- path:

  A character vector of one or more directories where files should be
  discovered (only for
  [`seek()`](https://smartiing.github.io/seekr/reference/seek.md)).

- relative_path:

  Logical. If TRUE, file paths are made relative to the path argument.
  If multiple root paths are provided, relative_path is automatically
  ignored and absolute paths are kept to avoid ambiguity.

- matches:

  Logical. If `TRUE`, all matches per line are also returned in a
  `matches` list-column.

## Value

A tibble with the following columns:

- `path`: File path (relative if specified), marked with class
  `fs_path`.

- `line_number`: Line number of the match within the file.

- `match`: The first matched substring from the line.

- `matches` (optional): All matched substrings as a list-column.

- `line`: Full content of the matching line.

## Details

All steps are executed sequentially to transform file-based pattern
matches into a structured tabular format. The function assumes that
input files and their corresponding line data are correctly aligned. It
handles path normalization, match extraction, and output column
selection according to the `matches` and `relative_path` arguments.
