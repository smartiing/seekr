
<!-- README.md is generated from README.Rmd. Please edit that file -->

# seekr <a href="https://smartiing.github.io/seekr/"><img src="man/figures/logo.png" align="right" height="138" alt="seekr website" /></a>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/seekr)](https://CRAN.R-project.org/package=seekr)
[![R-CMD-check](https://github.com/smartiing/seekr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/smartiing/seekr/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/smartiing/seekr/graph/badge.svg)](https://app.codecov.io/gh/smartiing/seekr)
<!-- badges: end -->

## Overview

**seekr** is an R package designed to help you search for specific
patterns within text files.

## Installation

``` r
# Install it directly from CRAN:
install.packages("seekr")

# Or the the development version from GitHub:
# install.packages("pak")
pak::pak("smartiing/seekr")
```

## Functions

**seekr** provides two main functions:

- `seek()`: Search for a pattern in files within a specified directory.
- `seek_in()`: Search for a pattern in a given list of files.

Each function returns a tibble with the following columns:

- `path`: Path to the file (relative or absolute).
- `line_number`: Line number where the pattern was found.
- `match`: The first match found in the line.
- `matches`: All matches found in the line (if matches = TRUE).
- `line`: Content of the matching line.

## Example

``` r
library(seekr)
#> 
#> Attaching package: 'seekr'
#> The following object is masked from 'package:base':
#> 
#>     seek

path = system.file("extdata", package = "seekr")

# Search all function definitions in R files
seek("[^\\s]+(?= (=|<-) function\\()", path, filter = "\\.R$")
#> # A tibble: 6 × 4
#>   path       line_number match        line                         
#>   <fs::path>       <int> <chr>        <chr>                        
#> 1 /script1.R           1 add_one      add_one <- function(x) {     
#> 2 /script1.R           5 capitalize   capitalize <- function(txt) {
#> 3 /script1.R           9 say_hello    say_hello <- function(name) {
#> 4 /script2.R           2 mean_safe    mean_safe <- function(x) {   
#> 5 /script2.R           7 sd_safe      sd_safe <- function(x) {     
#> 6 /script2.R          12 print_vector print_vector <- function(v) {

# Search for usage of "TODO" comments in source code in a case insensitive way
seek("(?i)TODO", path, filter = "\\.R$")
#> # A tibble: 1 × 4
#>   path       line_number match line                          
#>   <fs::path>       <int> <chr> <chr>                         
#> 1 /script2.R           1 TODO  # TODO: optimize this function

# Search for error/warning in log files
seek("(?i)error", path, filter = "\\.log$")
#> # A tibble: 14 × 4
#>    path        line_number match line                                           
#>    <fs::path>        <int> <chr> <chr>                                          
#>  1 /server.log           3 ERROR 2025-04-29 21:52:17 ERROR : Starting process   
#>  2 /server.log           6 ERROR 2025-04-30 04:15:43 ERROR : Retrying request   
#>  3 /server.log           7 ERROR 2025-04-29 13:59:14 ERROR : Failed to authenti…
#>  4 /server.log          10 ERROR 2025-04-30 17:20:48 ERROR : User login failed  
#>  5 /server.log          11 ERROR 2025-04-30 11:41:17 ERROR : Starting process   
#>  6 /server.log          14 ERROR 2025-04-30 00:15:59 ERROR : Connection success…
#>  7 /server.log          16 ERROR 2025-04-29 20:39:24 ERROR : User login failed  
#>  8 /server.log          19 ERROR 2025-04-29 17:51:14 ERROR : Timeout reached    
#>  9 /server.log          20 ERROR 2025-04-29 18:27:07 ERROR : Retrying request   
#> 10 /server.log          21 ERROR 2025-04-30 16:15:44 ERROR : Disk usage high    
#> 11 /server.log          23 ERROR 2025-04-30 17:14:15 ERROR : User login failed  
#> 12 /server.log          30 ERROR 2025-04-30 00:03:39 ERROR : Connection success…
#> 13 /server.log          35 ERROR 2025-04-30 17:25:05 ERROR : Connection success…
#> 14 /server.log          40 ERROR 2025-04-29 17:49:55 ERROR : Restart scheduled

# Search for config keys in YAML
seek("database:", path, filter = "\\.ya?ml$")
#> # A tibble: 1 × 4
#>   path         line_number match     line     
#>   <fs::path>         <int> <chr>     <chr>    
#> 1 /config.yaml           1 database: database:

# Looking for "length" in all types of text files
seek("(?i)length", path)
#> # A tibble: 4 × 4
#>   path       line_number match  line                                            
#>   <fs::path>       <int> <chr>  <chr>                                           
#> 1 /iris.csv            1 Length "\"Sepal.Length\",\"Sepal.Width\",\"Petal.Lengt…
#> 2 /script2.R           3 length "  if (length(x) == 0) return(NA)"              
#> 3 /script2.R           8 length "  if (length(x) <= 1) return(NA)"              
#> 4 /script2.R          13 length "  print(paste('Vector of length', length(v)))"

# Search for specific CSV headers using seek_in() and reading only the first line
csv_files <- list.files(path, "\\.csv$", full.names = TRUE)
seek_in(csv_files, "(?i)specie", n_max = 1)
#> # A tibble: 1 × 4
#>   path                                                   line_number match line 
#>   <fs::path>                                                   <int> <chr> <chr>
#> 1 …YzN7t/temp_libpath4cf462766a0b/seekr/extdata/iris.csv           1 Spec… "\"S…
```

## License

This package is licensed under the MIT License.
