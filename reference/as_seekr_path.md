# Normalize file paths for seekr

`as_seekr_path()` converts paths to the normalized format used
internally by seekr for listing, filtering, matching, and replacement.

This is useful when writing custom `exclude` functions, comparing paths
with seekr results, or building file vectors before calling
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
or
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md).

## Usage

``` r
as_seekr_path(x)
```

## Arguments

- x:

  A character vector of paths.

## Value

A character vector of normalized absolute paths, with the same length
and order as `x`.

## Details

A **seekr path** is a character path that has been:

- expanded, so `~` is resolved,

- normalized, so redundant path components are removed,

- resolved to an absolute path,

- represented with forward slashes.

### Where seekr paths are created

[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md)
returns seekr paths: it starts from user-supplied directories and
returns the listed files as normalized absolute paths.

[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
and
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)
normalize their input `path` before filtering or matching. This means
path-based filters such as `path_pattern` are applied to seekr paths,
regardless of whether the input paths were originally relative,
absolute, or written with platform-specific separators.

### Why this matters

Normalizing paths makes path filtering more predictable. A
`path_pattern` is matched against a stable representation of the file
path instead of depending on how the path was originally written by the
user.

## See also

[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md),
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md),
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)

## Examples

``` r
as_seekr_path(".")
#> [1] "/home/runner/work/seekr/seekr/docs/reference"
as_seekr_path(c(".", "~"))
#> [1] "/home/runner/work/seekr/seekr/docs/reference"
#> [2] "/home/runner"                                
```
