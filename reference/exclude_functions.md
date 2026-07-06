# Default file exclusion functions

`exclude_functions` is the default named list of functions used by
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
to exclude files that are usually not useful for text search.

## Usage

``` r
exclude_functions

is_git_dir(path)

is_dependency_dir(path)

is_minified_file(path)

is_not_text_mime(path)
```

## Format

A named list of exclude functions.

## Arguments

- path:

  A character vector of file paths to filter.

## Details

Each function receives a character vector of normalized file paths and
must return a logical vector of the same length. `TRUE` means that the
corresponding file should be excluded.

The default pipeline includes:

- `is_git_dir()`: excludes files located inside `.git/`.

- `is_dependency_dir()`: excludes files in common dependency folders
  such as `node_modules/`, `renv/`, `.venv/`, `vendor/`, and
  `__pycache__/`.

- `is_minified_file()`: excludes minified or bundled files such as
  `.min.js`, `.bundle.css`, etc.

- `is_not_text_mime()`: excludes files not recognized as text based on
  their MIME type.

You can disable all exclude functions with `exclude = NULL`, remove one
of the defaults by setting it to `NULL` in a copy of exclude_functions,
or add your own named function to the list.

## See also

[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
files <- list_files(path = ext_path)
names(exclude_functions)
#> [1] "is_git_dir"        "is_dependency_dir" "is_minified_file" 
#> [4] "is_not_text_mime" 

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
