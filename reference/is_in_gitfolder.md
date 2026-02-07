# Check if Files Are Located in a `.git` Folder

Identifies whether the provided file paths are located inside a `.git`
directory.

This function assumes that the file paths are normalized beforehand
(i.e., using forward slashes `/` even on Windows systems).

## Usage

``` r
is_in_gitfolder(files)
```

## Arguments

- files:

  A character vector of files to search (only for
  [`seek_in()`](https://smartiing.github.io/seekr/reference/seek.md)).

## Value

A logical vector indicating whether each file is located within a `.git`
folder.
