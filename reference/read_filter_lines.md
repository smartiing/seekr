# Read and Filter Matching Lines in Text Files

Reads lines from a set of text files and returns only the lines that
match a specified regular expression pattern. The function processes
each file one-by-one to maintain memory efficiency, making it suitable
for reading large files. Files that cannot be read (due to warnings or
errors) are skipped with a warning.

If verbosity is enabled via `seekr.verbose = TRUE` and the session is
interactive, the function reports progress.

## Usage

``` r
read_filter_lines(files, pattern, ...)
```

## Arguments

- files:

  A character vector of files to search (only for
  [`seek_in()`](https://smartiing.github.io/seekr/reference/seek.md)).

- pattern:

  A regular expression pattern used to match lines.

- ...:

  Additional arguments passed to
  [`readr::read_lines()`](https://readr.tidyverse.org/reference/read_lines.html),
  such as `skip`, `n_max`, or `locale`.

## Value

A list with two elements:

- `line_number`:

  A list of integer vectors giving the line numbers of matching lines,
  one per file.

- `line`:

  A list of character vectors containing the matched lines, one per
  file.

## Details

Files are processed sequentially to minimize memory usage, especially
when working with large files. Only the lines matching the `pattern` are
retained for each file.

If a file raises a warning or an error during reading, it is silently
skipped and contributes an empty entry to the result lists.
