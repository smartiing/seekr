# List Files in Directory

Lists all files from a given directory with support for recursive search
and inclusion of hidden files. The function throws a specific error when
no files are found, based on the combination of `recurse` and `all`
parameters. Returned file paths are made unique and are assumed to be
normalized using forward slashes (`/`).

## Usage

``` r
list_files(path, recurse, all)
```

## Arguments

- path:

  A character vector of one or more paths.

- recurse:

  If `TRUE` recurse fully, if a positive number the number of levels to
  recurse.

- all:

  If `TRUE` hidden files are also returned.

## Value

A character vector of unique file paths. If no files are found, the
function aborts with a message suggesting how to adjust search
parameters (`recurse` and `all`), and includes a class-specific error
identifier depending on the search mode:

- `"error_list_files_TT"` for `recurse = TRUE`, `all = TRUE`

- `"error_list_files_TF"` for `recurse = TRUE`, `all = FALSE`

- `"error_list_files_FT"` for `recurse = FALSE`, `all = TRUE`

- `"error_list_files_FF"` for `recurse = FALSE`, `all = FALSE`

## Examples

``` r
if (FALSE) { # \dontrun{
list_files("myfolder", recurse = TRUE, all = FALSE)
} # }
```
