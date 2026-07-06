# List seekr options

`seekr_options()` returns the options that control seekr's global
behavior, along with their current user-defined value and their package
default.

These options can be changed with
[`base::options()`](https://rdrr.io/r/base/options.html). For example:

    options(seekr.progress = FALSE)
    options(seekr.print.mode = "plain")

### Option values

The `current` column reports the value currently set with
[`base::options()`](https://rdrr.io/r/base/options.html). If an option
has not been set by the user, `current` is `NA` and seekr falls back to
the value shown in `default`.

### Available options

The main options are:

- `seekr.progress`: whether seekr displays progress messages by default.

- `seekr.backup_dir`: directory where backups are stored.

- `seekr.print.mode`: print mode, either `"rich"`, `"color"`, or
  `"plain"`.

- `seekr.print.tab`: symbol used to display tab characters.

- `seekr.print.newline`: symbol used to display newline characters when
  printing deleted newlines.

- `seekr.style.*`: ANSI style codes used internally by rich printing.

The `seekr.style.*` options are intentionally low-level. They accept
ANSI SGR codes as strings, such as `"31"`, `"1;31"`, or `"38;5;243"`.

## Usage

``` r
seekr_options()
```

## Value

A tibble with one row per seekr option and the following columns:

- `name`: option name.

- `current`: value currently set by the user, or `NA` if unset.

- `default`: default value used by seekr when the option is unset.

## See also

[`seekr_option()`](https://smartiing.github.io/seekr/reference/seekr_option.md)
to retrieve the resolved value of a single option.

## Examples

``` r
seekr_options()
#> # A tibble: 13 × 3
#>    name                    current default                               
#>    <chr>                   <chr>   <chr>                                 
#>  1 seekr.progress          NA      FALSE                                 
#>  2 seekr.backup_dir        NA      /home/runner/.local/share/seekr/backup
#>  3 seekr.style.match_only  NA      36                                    
#>  4 seekr.style.match       NA      31                                    
#>  5 seekr.style.replacement NA      32                                    
#>  6 seekr.style.dim         NA      38;5;243                              
#>  7 seekr.style.class       NA      3;38;5;243                            
#>  8 seekr.style.osc8_file   NA      34                                    
#>  9 seekr.style.osc8_dir    NA      1;34                                  
#> 10 seekr.style.na          NA      31                                    
#> 11 seekr.print.mode        NA      color                                 
#> 12 seekr.print.tab         NA      →                                     
#> 13 seekr.print.newline     NA      ↵                                     

# Disable progress messages globally
options(seekr.progress = FALSE)
seekr_options()
#> # A tibble: 13 × 3
#>    name                    current default                               
#>    <chr>                   <chr>   <chr>                                 
#>  1 seekr.progress          FALSE   FALSE                                 
#>  2 seekr.backup_dir        NA      /home/runner/.local/share/seekr/backup
#>  3 seekr.style.match_only  NA      36                                    
#>  4 seekr.style.match       NA      31                                    
#>  5 seekr.style.replacement NA      32                                    
#>  6 seekr.style.dim         NA      38;5;243                              
#>  7 seekr.style.class       NA      3;38;5;243                            
#>  8 seekr.style.osc8_file   NA      34                                    
#>  9 seekr.style.osc8_dir    NA      1;34                                  
#> 10 seekr.style.na          NA      31                                    
#> 11 seekr.print.mode        NA      color                                 
#> 12 seekr.print.tab         NA      →                                     
#> 13 seekr.print.newline     NA      ↵                                     

# Reset the option
options(seekr.progress = NULL)
```
