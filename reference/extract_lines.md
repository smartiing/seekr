# Extract lines from a string using newline position matrix

Returns the substring(s) corresponding to line ranges defined by start
and end line numbers. This is used to extract match lines, as well as
context lines before and after the match.

## Usage

``` r
extract_lines(text, locs_nl, start_line, end_line)
```

## Arguments

- text:

  Text content as a single string.

- locs_nl:

  An integer matrix from
  [`compute_newline_locs()`](https://smartiing.github.io/seekr/reference/compute_newline_locs.md),
  giving the start and end positions of each line in the file.

- start_line:

  A vector of starting line numbers (1-based).

- end_line:

  A vector of ending line numbers (inclusive).

## Value

A character vector, one string per line range. Returns `NA` for ranges
that fall entirely outside the file.
