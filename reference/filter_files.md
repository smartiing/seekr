# Filter files to search

`filter_files()` keeps files matching `extension` and `path_pattern`,
and not exceeding `max_file_size`. Finally, the `exclude` functions are
applied to the remaining files, discarding common non-text or irrelevant
files by default. It is the second step of the
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md)
pipeline, applied after
[`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md)
and before
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md).

Exclusion filters are applied in this order:

1.  `extension`: keeps only files whose extension is in the provided
    list.

2.  `path_pattern`: keeps files whose normalized path matches the
    pattern.

3.  `max_file_size`: excludes files larger than the given size.

4.  [`exclude_functions`](https://smartiing.github.io/seekr/reference/exclude_functions.md):
    applies each named function to the remaining files.

Files are only passed to each subsequent filter if they have not already
been excluded by a previous one.

Details about excluded files are stored on the result and can be
retrieved with
[`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md).

## Usage

``` r
filter_files(
  path,
  ...,
  extension = NULL,
  path_pattern = NULL,
  max_file_size = Inf,
  exclude = seekr::exclude_functions,
  .progress = seekr_option("seekr.progress")
)
```

## Arguments

- path:

  A character vector of file paths to filter.

- ...:

  These dots are for future extensions and must be empty.

- extension:

  Optional character vector of file extensions to keep. Either:

  - `NULL` (default): no filtering by extension; all extensions are
    kept.

  - A character vector of extensions to keep, with or without a leading
    dot (e.g. `c("R", ".Rmd", "qmd")`).

  Extensions are normalized before matching: leading dots are stripped,
  matching is case-insensitive, and duplicates are ignored. Only the
  last component of compound extensions is used (e.g. `"tar.gz"` uses
  `"gz"`), with a warning.

- path_pattern:

  Optional pattern applied to filter normalized file paths (see
  [`as_seekr_path()`](https://smartiing.github.io/seekr/reference/as_seekr_path.md)).
  Either:

  - `NULL` (default): no filtering by path.

  - A string, interpreted as a regular expression via
    [`stringr::regex()`](https://stringr.tidyverse.org/reference/modifiers.html).

  - A `stringr_pattern` object such as
    [`stringr::regex()`](https://stringr.tidyverse.org/reference/modifiers.html)
    or
    [`stringr::fixed()`](https://stringr.tidyverse.org/reference/modifiers.html).

- max_file_size:

  Maximum file size in bytes. Files larger than this value are excluded.
  Default is `Inf`, meaning no files are excluded by size. Zero and
  negative values are treated as `Inf`.

- exclude:

  Named list of functions used to exclude unwanted files during
  filtering. Either:

  - `NULL`, to disable additional exclude functions.

  - A named list of functions, each taking a character vector of
    normalized file paths and returning a logical vector of the same
    length, where `TRUE` means the file should be excluded.

  Defaults to
  [exclude_functions](https://smartiing.github.io/seekr/reference/exclude_functions.md),
  which excludes common non-text or irrelevant files.

- .progress:

  Whether to display progress messages. Default is `TRUE` in interactive
  sessions and `FALSE` otherwise (see
  [`rlang::is_interactive()`](https://rlang.r-lib.org/reference/is_interactive.html)).
  Can be set globally with `options(seekr.progress = FALSE)`.

## Value

A character vector of normalized absolute paths that passed all filters.
Paths use the same representation as
[`as_seekr_path()`](https://smartiing.github.io/seekr/reference/as_seekr_path.md).

An attribute `"exclusions"` is always attached to the result, containing
a data frame with one row per input file and one column per exclusion
function, detailing which files were excluded and why. Retrieve it with
[`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md).

## See also

- [`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md)
  to produce the input paths.

- [`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)
  to search the filtered files for a pattern.

- [`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md)
  to inspect which files were removed and why.

- [`seek()`](https://smartiing.github.io/seekr/reference/seek.md) to run
  the full pipeline.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
files <- list_files(path = ext_path)

# Keep only R files
filter_files(files, extension = "R")
#> [1] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"
#> [2] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"
#> attr(,"exclusions")
#> # A tibble: 8 × 7
#>   path                excluded exclude_by_extension is_git_dir is_dependency_dir
#>   <chr>               <lgl>    <lgl>                <lgl>      <lgl>            
#> 1 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 2 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 3 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 4 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 5 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 6 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 7 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 8 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> # ℹ 2 more variables: is_minified_file <lgl>, is_not_text_mime <lgl>

# Keep only files in the R/ subfolder
filter_files(files, path_pattern = "/R/")
#> character(0)
#> attr(,"exclusions")
#> # A tibble: 8 × 7
#>   path              excluded exclude_by_path_patt…¹ is_git_dir is_dependency_dir
#>   <chr>             <lgl>    <lgl>                  <lgl>      <lgl>            
#> 1 /home/runner/wor… TRUE     TRUE                   NA         NA               
#> 2 /home/runner/wor… TRUE     TRUE                   NA         NA               
#> 3 /home/runner/wor… TRUE     TRUE                   NA         NA               
#> 4 /home/runner/wor… TRUE     TRUE                   NA         NA               
#> 5 /home/runner/wor… TRUE     TRUE                   NA         NA               
#> 6 /home/runner/wor… TRUE     TRUE                   NA         NA               
#> 7 /home/runner/wor… TRUE     TRUE                   NA         NA               
#> 8 /home/runner/wor… TRUE     TRUE                   NA         NA               
#> # ℹ abbreviated name: ¹​exclude_by_path_pattern
#> # ℹ 2 more variables: is_minified_file <lgl>, is_not_text_mime <lgl>

# Exclude files larger than 1 MB
filter_files(files, max_file_size = fs::fs_bytes("1MB"))
#> [1] "/home/runner/work/_temp/Library/seekr/extdata/config.yaml"
#> [2] "/home/runner/work/_temp/Library/seekr/extdata/data.json"  
#> [3] "/home/runner/work/_temp/Library/seekr/extdata/iris.csv"   
#> [4] "/home/runner/work/_temp/Library/seekr/extdata/mtcars.csv" 
#> [5] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"  
#> [6] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"  
#> [7] "/home/runner/work/_temp/Library/seekr/extdata/server1.log"
#> [8] "/home/runner/work/_temp/Library/seekr/extdata/server2.log"
#> attr(,"exclusions")
#> # A tibble: 8 × 7
#>   path                excluded exclude_by_file_size is_git_dir is_dependency_dir
#>   <chr>               <lgl>    <lgl>                <lgl>      <lgl>            
#> 1 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 2 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 3 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 4 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 5 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 6 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 7 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 8 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> # ℹ 2 more variables: is_minified_file <lgl>, is_not_text_mime <lgl>

# Inspect which files were excluded and why
filtered <- filter_files(files, extension = "R")
exclusions(filtered)
#> # A tibble: 8 × 7
#>   path                excluded exclude_by_extension is_git_dir is_dependency_dir
#>   <chr>               <lgl>    <lgl>                <lgl>      <lgl>            
#> 1 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 2 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 3 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 4 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 5 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 6 /home/runner/work/… FALSE    FALSE                FALSE      FALSE            
#> 7 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> 8 /home/runner/work/… TRUE     TRUE                 NA         NA               
#> # ℹ 2 more variables: is_minified_file <lgl>, is_not_text_mime <lgl>

# Disable default exclude functions
filter_files(files, exclude = NULL)
#> [1] "/home/runner/work/_temp/Library/seekr/extdata/config.yaml"
#> [2] "/home/runner/work/_temp/Library/seekr/extdata/data.json"  
#> [3] "/home/runner/work/_temp/Library/seekr/extdata/iris.csv"   
#> [4] "/home/runner/work/_temp/Library/seekr/extdata/mtcars.csv" 
#> [5] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"  
#> [6] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"  
#> [7] "/home/runner/work/_temp/Library/seekr/extdata/server1.log"
#> [8] "/home/runner/work/_temp/Library/seekr/extdata/server2.log"
#> attr(,"exclusions")
#> # A tibble: 8 × 2
#>   path                                                      excluded
#>   <chr>                                                     <lgl>   
#> 1 /home/runner/work/_temp/Library/seekr/extdata/config.yaml FALSE   
#> 2 /home/runner/work/_temp/Library/seekr/extdata/data.json   FALSE   
#> 3 /home/runner/work/_temp/Library/seekr/extdata/iris.csv    FALSE   
#> 4 /home/runner/work/_temp/Library/seekr/extdata/mtcars.csv  FALSE   
#> 5 /home/runner/work/_temp/Library/seekr/extdata/script1.R   FALSE   
#> 6 /home/runner/work/_temp/Library/seekr/extdata/script2.R   FALSE   
#> 7 /home/runner/work/_temp/Library/seekr/extdata/server1.log FALSE   
#> 8 /home/runner/work/_temp/Library/seekr/extdata/server2.log FALSE   

# Add a custom exclude function
my_fns <- exclude_functions
my_fns$generated <- function(path) grepl("/generated/", path)
filter_files(files, exclude = my_fns)
#> [1] "/home/runner/work/_temp/Library/seekr/extdata/config.yaml"
#> [2] "/home/runner/work/_temp/Library/seekr/extdata/data.json"  
#> [3] "/home/runner/work/_temp/Library/seekr/extdata/iris.csv"   
#> [4] "/home/runner/work/_temp/Library/seekr/extdata/mtcars.csv" 
#> [5] "/home/runner/work/_temp/Library/seekr/extdata/script1.R"  
#> [6] "/home/runner/work/_temp/Library/seekr/extdata/script2.R"  
#> [7] "/home/runner/work/_temp/Library/seekr/extdata/server1.log"
#> [8] "/home/runner/work/_temp/Library/seekr/extdata/server2.log"
#> attr(,"exclusions")
#> # A tibble: 8 × 7
#>   path   excluded is_git_dir is_dependency_dir is_minified_file is_not_text_mime
#>   <chr>  <lgl>    <lgl>      <lgl>             <lgl>            <lgl>           
#> 1 /home… FALSE    FALSE      FALSE             FALSE            FALSE           
#> 2 /home… FALSE    FALSE      FALSE             FALSE            FALSE           
#> 3 /home… FALSE    FALSE      FALSE             FALSE            FALSE           
#> 4 /home… FALSE    FALSE      FALSE             FALSE            FALSE           
#> 5 /home… FALSE    FALSE      FALSE             FALSE            FALSE           
#> 6 /home… FALSE    FALSE      FALSE             FALSE            FALSE           
#> 7 /home… FALSE    FALSE      FALSE             FALSE            FALSE           
#> 8 /home… FALSE    FALSE      FALSE             FALSE            FALSE           
#> # ℹ 1 more variable: generated <lgl>
```
