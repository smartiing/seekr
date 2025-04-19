
<!-- README.md is generated from README.Rmd. Please edit that file -->

# seekr

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/seekr)](https://CRAN.R-project.org/package=seekr)

<!-- badges: end -->

**seekr** is an R package designed to help you search for specific
patterns within **text** files.

## Installation

You can install the development version of **seekr** from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("smartiing/seekr")
```

## Example

Here’s a basic example of how to use **seekr**:

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
#> # A tibble: 53 × 6
#>     file path                      line match  matches   content                
#>    <int> <chr>                    <int> <chr>  <list>    <chr>                  
#>  1     1 /01mtcars5583ada6cf5.csv    20 Honda  <chr [1]> "\"Honda Civic\",30.4,…
#>  2     1 /01mtcars5583ada6cf5.csv    21 Toyota <chr [1]> "\"Toyota Corolla\",33…
#>  3     1 /01mtcars5583ada6cf5.csv    22 Toyota <chr [1]> "\"Toyota Corona\",21.…
#>  4     2 /02iris55843615516.csv       2 setosa <chr [1]> "\"1\",5.1,3.5,1.4,0.2…
#>  5     2 /02iris55843615516.csv       3 setosa <chr [1]> "\"2\",4.9,3,1.4,0.2,\…
#>  6     2 /02iris55843615516.csv       4 setosa <chr [1]> "\"3\",4.7,3.2,1.3,0.2…
#>  7     2 /02iris55843615516.csv       5 setosa <chr [1]> "\"4\",4.6,3.1,1.5,0.2…
#>  8     2 /02iris55843615516.csv       6 setosa <chr [1]> "\"5\",5,3.6,1.4,0.2,\…
#>  9     2 /02iris55843615516.csv       7 setosa <chr [1]> "\"6\",5.4,3.9,1.7,0.4…
#> 10     2 /02iris55843615516.csv       8 setosa <chr [1]> "\"7\",4.6,3.4,1.4,0.3…
#> # ℹ 43 more rows
  
unlink(c(tmp_mtcars, tmp_iris))
```

## Functions

**seekr** provides two main functions:

- `seek()`: Search for a pattern in files within a specified directory.
- `seek_in()`: Search for a pattern in a given list of files.

Each function returns a tibble with the following columns:

- `file`: Index of the file in the list.
- `path`: Path to the file.
- `line`: Line number where the pattern was found.
- `content`: Content of the matching line.
- `match`: The first match found in the line.
- `matches`: All matches found in the line.

## License

This package is licensed under the MIT License.
