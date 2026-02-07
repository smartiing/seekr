# Extract Matching Lines from Files

These functions search through one or more text files, extract lines
matching a regular expression pattern, and return a tibble containing
the results.

- `seek()`: Discovers files inside one or more directories (recursively
  or not), applies optional file name and text file filtering, and
  searches lines.

- `seek_in()`: Searches inside a user-provided character vector of
  files.

## Usage

``` r
seek(
  pattern,
  path = ".",
  ...,
  filter = NULL,
  negate = FALSE,
  recurse = FALSE,
  all = FALSE,
  relative_path = TRUE,
  matches = FALSE
)

seek_in(files, pattern, ..., matches = FALSE)
```

## Arguments

- pattern:

  A regular expression pattern used to match lines.

- path:

  A character vector of one or more directories where files should be
  discovered (only for `seek()`).

- ...:

  Additional arguments passed to
  [`readr::read_lines()`](https://readr.tidyverse.org/reference/read_lines.html),
  such as `skip`, `n_max`, or `locale`.

- filter:

  Optional. A regular expression pattern used to filter file paths
  before reading. If `NULL`, all text files are considered.

- negate:

  Logical. If `TRUE`, files matching the `filter` pattern are excluded
  instead of included. Useful to skip files based on name or extension.

- recurse:

  If `TRUE` recurse fully, if a positive number the number of levels to
  recurse.

- all:

  If `TRUE` hidden files are also returned.

- relative_path:

  Logical. If TRUE, file paths are made relative to the path argument.
  If multiple root paths are provided, relative_path is automatically
  ignored and absolute paths are kept to avoid ambiguity.

- matches:

  Logical. If `TRUE`, all matches per line are also returned in a
  `matches` list-column.

- files:

  A character vector of files to search (only for `seek_in()`).

## Value

A tibble with one row per matched line, containing:

- `path`: File path (relative or absolute).

- `line_number`: Line number in the file.

- `match`: The first matched substring.

- `matches`: All matched substrings (if `matches = TRUE`).

- `line`: Full content of the matching line.

## Details

**\[experimental\]**

The overall process involves the following steps:

- **File Selection**

  - `seek()`: Files are discovered using
    [`fs::dir_ls()`](https://fs.r-lib.org/reference/dir_ls.html),
    starting from one or more directories.

  - `seek_in()`: Files are directly supplied by the user (no discovery
    phase).

- **File Filtering**

  - Files located inside `.git/` folders are automatically excluded.

  - Files with known non-text extensions (e.g., `.png`, `.exe`, `.rds`)
    are excluded.

  - If a file's extension is unknown, a check is performed to detect
    embedded null bytes (binary indicator).

  - Optionally, an additional regex-based path filter (`filter`) can be
    applied.

- **Line Reading**

  - Files are read line-by-line using
    [`readr::read_lines()`](https://readr.tidyverse.org/reference/read_lines.html).

  - Only lines matching the provided regular expression `pattern` are
    retained.

  - If a file cannot be read, it is skipped gracefully without failing
    the process.

- **Data Frame Construction**

  - A tibble is constructed with one row per matched line.

These functions are particularly useful for analyzing source code,
configuration files, logs, and other structured text data.

## See also

[`fs::dir_ls()`](https://fs.r-lib.org/reference/dir_ls.html),
[`readr::read_lines()`](https://readr.tidyverse.org/reference/read_lines.html),
[`stringr::str_detect()`](https://stringr.tidyverse.org/reference/str_detect.html)

## Examples

``` r
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
#> 1 /home/runner/work/_temp/Library/seekr/extdata/iris.csv           1 Spec… "\"S…
```
