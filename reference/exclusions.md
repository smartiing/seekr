# Inspect why files were excluded

`exclusions()` retrieves the exclusion details stored on objects
returned by
[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md),
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md), and
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md).

## Usage

``` r
exclusions(x)
```

## Arguments

- x:

  An object containing exclusion details, typically the result of
  [`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md),
  [`seek()`](https://smartiing.github.io/seekr/reference/seek.md), or
  [`seekr()`](https://smartiing.github.io/seekr/reference/seek.md).

## Value

A data frame with one row per input file and one column per exclusion
filter, describing which files were excluded and why. If no exclusion
details are available, returns `NULL`.

## See also

[`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
for the filtering step,
[exclude_functions](https://smartiing.github.io/seekr/reference/exclude_functions.md)
for the default exclude-function pipeline.

## Examples

``` r
ext_path <- system.file("extdata", package = "seekr")
files <- list_files(path = ext_path)
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
```
