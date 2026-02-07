# Filter Files by Pattern and Content Type

Filters a character vector of file paths using a user-defined pattern
and additional content-based criteria to ensure only likely text files
are retained.

This function applies multiple filters:

- A regex-based path filter (if provided).

- Exclusion of files located within `.git` folders.

- Exclusion of files with known binary or non-text extensions.

- A fallback scan for embedded null bytes to detect binary content in
  ambiguous files.

The function returns a filtered character vector of file paths likely to
be valid text files.

## Usage

``` r
filter_files(files, filter, negate, n = 1000L)
```

## Arguments

- files:

  A character vector of files to search (only for
  [`seek_in()`](https://smartiing.github.io/seekr/reference/seek.md)).

- filter:

  Optional. A regular expression pattern used to filter file paths
  before reading. If `NULL`, all text files are considered.

- negate:

  Logical. If `TRUE`, files matching the `filter` pattern are excluded
  instead of included. Useful to skip files based on name or extension.

- n:

  The number of bytes to read for binary detection in files with unknown
  extensions. Defaults to 1000.

## Value

A character vector of file paths identified as potential text files. If
no matching files are found, an informative error is thrown.
