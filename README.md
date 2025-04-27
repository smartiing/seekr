
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
# Search for lines containing 'particular words' in csv files within the specified folder
tmp_mtcars = tempfile("01mtcars", fileext = ".csv")
tmp_iris = tempfile("02iris", fileext = ".csv")

write.csv(mtcars, tmp_mtcars)
write.csv(iris, tmp_iris)

found = seekr::seek(
  pattern = "(?i)toyota|honda|setosa", 
  path = tempdir(), 
  filter = "\\.csv$"
)
  
print(found)
#> # A tibble: 53 × 4
#>    path                      line_number match  line                            
#>    <fs::path>                      <int> <chr>  <chr>                           
#>  1 /01mtcars1ce438082ced.csv          20 Honda  "\"Honda Civic\",30.4,4,75.7,52…
#>  2 /01mtcars1ce438082ced.csv          21 Toyota "\"Toyota Corolla\",33.9,4,71.1…
#>  3 /01mtcars1ce438082ced.csv          22 Toyota "\"Toyota Corona\",21.5,4,120.1…
#>  4 /02iris1ce4651a7270.csv             2 setosa "\"1\",5.1,3.5,1.4,0.2,\"setosa…
#>  5 /02iris1ce4651a7270.csv             3 setosa "\"2\",4.9,3,1.4,0.2,\"setosa\""
#>  6 /02iris1ce4651a7270.csv             4 setosa "\"3\",4.7,3.2,1.3,0.2,\"setosa…
#>  7 /02iris1ce4651a7270.csv             5 setosa "\"4\",4.6,3.1,1.5,0.2,\"setosa…
#>  8 /02iris1ce4651a7270.csv             6 setosa "\"5\",5,3.6,1.4,0.2,\"setosa\""
#>  9 /02iris1ce4651a7270.csv             7 setosa "\"6\",5.4,3.9,1.7,0.4,\"setosa…
#> 10 /02iris1ce4651a7270.csv             8 setosa "\"7\",4.6,3.4,1.4,0.3,\"setosa…
#> # ℹ 43 more rows
  
unlink(c(tmp_mtcars, tmp_iris))
```

## License

This package is licensed under the MIT License.
