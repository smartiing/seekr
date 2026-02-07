# Extract Lowercase File Extensions

Extracts the file extensions from the provided file paths, normalizes
them to lowercase, and returns them as a character vector. The extension
includes the leading period (`.`).

## Usage

``` r
extract_lower_file_extension(files)
```

## Arguments

- files:

  A character vector of files to search (only for
  [`seek_in()`](https://smartiing.github.io/seekr/reference/seek.md)).

## Value

A character vector of lowercase file extensions.
