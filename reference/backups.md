# List, inspect, open, and delete backups

By default, seekr creates a backup before
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
and
[`restore_files()`](https://smartiing.github.io/seekr/reference/restore_files.md)
modify files. These functions let you inspect and manage existing
backups in a particular `backup_dir`.

- `list_backups()` returns a tibble of all existing backups.

- `last_backup()` returns only the most recent backup.

- `delete_backups()` permanently deletes one or more backups by their
  `id`.

- `open_backup_dir()` opens the current default backup directory.

## Usage

``` r
list_backups(backup_dir = seekr_option("seekr.backup_dir"))

last_backup(backup_dir = seekr_option("seekr.backup_dir"))

delete_backups(
  id,
  ...,
  backup_dir = seekr_option("seekr.backup_dir"),
  .progress = seekr_option("seekr.progress")
)

open_backup_dir(backup_dir = seekr_option("seekr.backup_dir"))
```

## Arguments

- backup_dir:

  Path to the backup directory. Defaults to
  `seekr_option("seekr.backup_dir")`, which resolves to a
  platform-specific user data directory. Change the default globally
  with `options(seekr.backup_dir = "/your/path")`.

- id:

  Integer vector of backup ids to delete, as found in the `id` column of
  `list_backups()`. Duplicate ids are silently deduplicated. Ids that do
  not correspond to any existing backup are silently ignored.

- ...:

  These dots are for future extensions and must be empty.

- .progress:

  Whether to display progress messages. Default is `TRUE` in interactive
  sessions and `FALSE` otherwise (see
  [`rlang::is_interactive()`](https://rlang.r-lib.org/reference/is_interactive.html)).
  Can be set globally with `options(seekr.progress = FALSE)`.

## Value

- `list_backups()` and `last_backup()` return a tibble as described in
  the **Backup table columns** section. An empty tibble with the correct
  columns is returned when no backups exist. `last_backup()` returns all
  rows belonging to the most recent backup operation.

- `delete_backups()` invisibly returns the paths of the deleted backup
  subdirectories.

- `open_backup_dir()` invisibly returns the path to the backup
  directory.

## Backups

Backups are stored under `backup_dir`, which defaults to a
platform-specific user data directory managed by
[`rappdirs::user_data_dir()`](https://rappdirs.r-lib.org/reference/user_data_dir.html).
Each backup occupies its own numbered subdirectory (`000001/`,
`000002/`, etc.) containing a copy of each file and a `backup.RDS`
metadata file.

The default backup directory can be changed globally with:

    options(seekr.backup_dir = "/your/preferred/path")

## Backup table columns

`list_backups()` and `last_backup()` return a tibble with one row per
backed-up file and the following columns:

- `id`: integer backup identifier, derived from the subdirectory name.
  All rows belonging to the same backup operation share the same `id`.

- `created_at`: date-time when the backup was created.

- `operation`: either `"replace"` (backup created by
  [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md))
  or `"restore"` (backup created by
  [`restore_files()`](https://smartiing.github.io/seekr/reference/restore_files.md)).

- `description`: optional description provided at backup time, or `NA`.

- `original`: absolute path to the original file.

- `backup`: absolute path to the backup copy.

- `original_exists`: whether the original file still exists on disk.

- `backup_exists`: whether the backup copy still exists on disk.

- `size`: size of the backup copy, as an `fs_bytes` value.

## See also

- [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  to apply replacements and create backups.

- [`restore_files()`](https://smartiing.github.io/seekr/reference/restore_files.md)
  and
  [`restore_files_interactive()`](https://smartiing.github.io/seekr/reference/restore_files.md)
  to restore files.

## Examples

``` r
# Set up a temporary project with two files
project_dir <- tempfile("seekr_project")
dir.create(project_dir)

backup_dir <- tempfile("seekr_backups")
dir.create(backup_dir)

file1 <- file.path(project_dir, "script1.R")
file2 <- file.path(project_dir, "script2.R")
writeLines("old_name <- function(x) x + 1", file1)
writeLines("y <- old_name(2)", file2)

# Search for the pattern we want to replace
x <- seekr("old_name", replacement = "new_name", path = project_dir)
x
#> <seekr::match[2]> 2 sources
#> Common Path: /tmp/RtmpKTGDR6/seekr_project1a066ca51b12
#> 
#> script1.R [1]
#> [1] -- 1 | old_name <- function(x) x + 1
#>     ++ 1 | new_name <- function(x) x + 1
#> 
#> script2.R [1]
#> [2] -- 1 | y <- old_name(2)
#>     ++ 1 | y <- new_name(2)
#> 

# No backup exists yet
list_backups(backup_dir = backup_dir)
#> # A tibble: 0 × 9
#> # ℹ 9 variables: id <int>, created_at <dttm>, operation <chr>,
#> #   description <chr>, original <chr>, backup <chr>, original_exists <lgl>,
#> #   backup_exists <lgl>, size <fs::bytes>

# Apply the replacement; a backup is created automatically
replace_files(x, backup_dir = backup_dir)

# The backup now contains the original (pre-replacement) version
# of both files, under id = 1
list_backups(backup_dir = backup_dir)
#> # A tibble: 2 × 9
#>      id created_at          operation description original                backup
#>   <int> <dttm>              <chr>     <chr>       <chr>                   <chr> 
#> 1     1 2026-07-10 22:33:13 replace   NA          /tmp/RtmpKTGDR6/seekr_… /tmp/…
#> 2     1 2026-07-10 22:33:13 replace   NA          /tmp/RtmpKTGDR6/seekr_… /tmp/…
#> # ℹ 3 more variables: original_exists <lgl>, backup_exists <lgl>,
#> #   size <fs::bytes>

# The files on disk have changed
readLines(file1)
#> [1] "new_name <- function(x) x + 1"
readLines(file2)
#> [1] "y <- new_name(2)"

# Searching for the original pattern no longer finds anything
seekr("old_name", path = project_dir)
#> <seekr::match[0]> 0 sources

# Restore the files from the backup; this itself creates a second
# backup (id = 2) of the current (replaced) version, before overwriting
b <- last_backup(backup_dir = backup_dir)
restore_files(from = b$backup, to = b$original, backup_dir = backup_dir)
#> ℹ Creating a backup of the current version of each existing destination file
#>   before restoring it.
#> ℹ This ensures you can revert to the state before restoration if needed.

# We now have two backups: id = 1 is the state before replace_files(),
# id = 2 is the state before restore_files() (i.e. the replaced version)
list_backups(backup_dir = backup_dir)
#> # A tibble: 4 × 9
#>      id created_at          operation description original                backup
#>   <int> <dttm>              <chr>     <chr>       <chr>                   <chr> 
#> 1     2 2026-07-10 22:33:13 restore   NA          /tmp/RtmpKTGDR6/seekr_… /tmp/…
#> 2     2 2026-07-10 22:33:13 restore   NA          /tmp/RtmpKTGDR6/seekr_… /tmp/…
#> 3     1 2026-07-10 22:33:13 replace   NA          /tmp/RtmpKTGDR6/seekr_… /tmp/…
#> 4     1 2026-07-10 22:33:13 replace   NA          /tmp/RtmpKTGDR6/seekr_… /tmp/…
#> # ℹ 3 more variables: original_exists <lgl>, backup_exists <lgl>,
#> #   size <fs::bytes>

# The files are back to their original content
readLines(file1)
#> [1] "old_name <- function(x) x + 1"
readLines(file2)
#> [1] "y <- old_name(2)"

# The original pattern is found again
seekr("old_name", path = project_dir)
#> <seekr::match[2]> 2 sources
#> Common Path: /tmp/RtmpKTGDR6/seekr_project1a066ca51b12
#> 
#> script1.R [1]
#> [1] -> 1 | old_name <- function(x) x + 1
#> 
#> script2.R [1]
#> [2] -> 1 | y <- old_name(2)
#> 

if (FALSE) { # \dontrun{
# open_backup_dir() opens a file browser, so it is not run here
open_backup_dir()

# Review each file interactively before restoring
restore_files_interactive(from = b$backup, to = b$original)

# Customize the diff display (unified format)
restore_files_interactive(
  from = b$backup,
  to = b$original,
  mode = "unified",
  color.mode = "yb"
)

# Finally, particular backups in a backup_dir can be deleted
b <- list_backups(backup_dir = backup_dir)
b
delete_backups(id = b$id, backup_dir = backup_dir)
} # }


unlink(project_dir, recursive = TRUE)
unlink(backup_dir, recursive = TRUE)
```
