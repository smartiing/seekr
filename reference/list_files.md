# List files to search

`list_files()` starts from `path` and lists candidate files. It can
recurse into subdirectories with `recurse`, include hidden files and
directories with `all`, and optionally restrict discovery inside Git
repositories with `use_git`. It is the first step of the
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md)
pipeline.

Listing is intentionally simple: it does not know about patterns,
extensions, file sizes, or MIME types. Its only job is to turn
directories into a character vector of file paths. Filtering happens in
the next step,
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md).

If `use_git = TRUE`, Git is used for each input path independently. For
each path, `list_files()` asks Git whether that path is inside a Git
repository. If it is, `list_files()` finds the repository root by
walking upward from that path, then keeps only the files also returned
by `git ls-files --cached --others --exclude-standard` for that
repository.

Git is used to restrict the files discovered from the input path. It
does not expand the search. The `path`, `recurse`, and `all` arguments
still define the initial candidate files. For example, Git-tracked
hidden files are not returned unless `all = TRUE`, and Git-tracked files
below the requested recursion depth are not returned.

`list_files()` does not search downward for nested Git repositories. If
an input path is not inside a Git repository, it is listed normally,
even if it contains Git repositories in subdirectories. If you want
Git-aware discovery for nested repositories, pass those repository
directories explicitly in `path`.

If `use_git = TRUE`, Git must be installed and available on `PATH`.

The returned paths are normalized as described in
[`as_seekr_path()`](https://smartiing.github.io/seekr/reference/as_seekr_path.md).

## Usage

``` r
list_files(
  path = ".",
  ...,
  recurse = TRUE,
  all = FALSE,
  use_git = FALSE,
  .progress = seekr_option("seekr.progress")
)
```

## Arguments

- path:

  A character vector of one or more existing directories to search in.
  Defaults to `"."` (the current working directory).

- ...:

  These dots are for future extensions and must be empty.

- recurse:

  Controls how deep the directory traversal goes to list files. Either:

  - `TRUE` (default): recurse into all subdirectories.

  - `FALSE`: only list files at the top level of each directory in
    `path`.

  - A positive integer: limit recursion to that many levels deep.

- all:

  Whether to list hidden files and directories. Default is `FALSE`.

- use_git:

  Should Git be used to restrict file discovery inside Git repositories?
  If `TRUE`, `list_files()` keeps only files that were first discovered
  according to `path`, `recurse`, and `all`, and are also returned by
  `git ls-files --cached --others --exclude-standard`. `use_git = TRUE`
  looks for the Git root by walking upward from each supplied `path`,
  but it does not recursively search downward for Git repositories in
  subdirectories. Git must be installed and available on `PATH`.

- .progress:

  Whether to display progress messages. Default is `TRUE` in interactive
  sessions and `FALSE` otherwise (see
  [`rlang::is_interactive()`](https://rlang.r-lib.org/reference/is_interactive.html)).
  Can be set globally with `options(seekr.progress = FALSE)`.

## Value

A character vector of normalized absolute file paths. Returns an empty
character vector if no files are found or if `path` is empty.

## See also

- [`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
  to filter the listed files before searching matches.

- [`seek()`](https://smartiing.github.io/seekr/reference/seek.md) to run
  the full listing, filtering, and matching pipeline.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")

# List all files in the example directory
list_files(path = ext_path)
#> [1] "/home/runner/work/_temp/Library/seekr/extdata/config.yaml"
#> [2] "/home/runner/work/_temp/Library/seekr/extdata/data.json"  
#> [3] "/home/runner/work/_temp/Library/seekr/extdata/iris.csv"   
#> [4] "/home/runner/work/_temp/Library/seekr/extdata/mtcars.csv" 
#> [5] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"  
#> [6] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"  
#> [7] "/home/runner/work/_temp/Library/seekr/extdata/server1.log"
#> [8] "/home/runner/work/_temp/Library/seekr/extdata/server2.log"

# List only files at the top level, without recursing
list_files(path = ext_path, recurse = FALSE)
#> [1] "/home/runner/work/_temp/Library/seekr/extdata/config.yaml"
#> [2] "/home/runner/work/_temp/Library/seekr/extdata/data.json"  
#> [3] "/home/runner/work/_temp/Library/seekr/extdata/iris.csv"   
#> [4] "/home/runner/work/_temp/Library/seekr/extdata/mtcars.csv" 
#> [5] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"  
#> [6] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"  
#> [7] "/home/runner/work/_temp/Library/seekr/extdata/server1.log"
#> [8] "/home/runner/work/_temp/Library/seekr/extdata/server2.log"

# Recurse at most 2 levels deep
list_files(path = ext_path, recurse = 2L)
#> [1] "/home/runner/work/_temp/Library/seekr/extdata/config.yaml"
#> [2] "/home/runner/work/_temp/Library/seekr/extdata/data.json"  
#> [3] "/home/runner/work/_temp/Library/seekr/extdata/iris.csv"   
#> [4] "/home/runner/work/_temp/Library/seekr/extdata/mtcars.csv" 
#> [5] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"  
#> [6] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"  
#> [7] "/home/runner/work/_temp/Library/seekr/extdata/server1.log"
#> [8] "/home/runner/work/_temp/Library/seekr/extdata/server2.log"

# Include hidden files and directories
list_files(path = ext_path, all = TRUE)
#> [1] "/home/runner/work/_temp/Library/seekr/extdata/config.yaml"
#> [2] "/home/runner/work/_temp/Library/seekr/extdata/data.json"  
#> [3] "/home/runner/work/_temp/Library/seekr/extdata/iris.csv"   
#> [4] "/home/runner/work/_temp/Library/seekr/extdata/mtcars.csv" 
#> [5] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"  
#> [6] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"  
#> [7] "/home/runner/work/_temp/Library/seekr/extdata/server1.log"
#> [8] "/home/runner/work/_temp/Library/seekr/extdata/server2.log"

if (FALSE) { # \dontrun{
# Use Git to restrict discovery inside Git repositories
list_files(path = ".", use_git = TRUE)
} # }
```
