# Restore files from backups

`restore_files()` copies files from a backup location back to their
original paths, overwriting the current versions. By default, it creates
a new backup of the current files before overwriting, so the restore
itself can be undone.

`restore_files_interactive()` works the same way but shows a
side-by-side diff (powered by
[`diffobj::diffFile()`](https://rdrr.io/pkg/diffobj/man/diffFile.html))
for each file before asking whether to restore it. This is useful when
you want to review the difference between the current version of the
file and its backup.

The typical workflow is to call
[`list_backups()`](https://smartiing.github.io/seekr/reference/backups.md)
or
[`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md)
to find the backup you want, then pass the `backup` and `original`
columns to `restore_files()`:

    b <- last_backup()
    restore_files(from = b$backup, to = b$original)

## Usage

``` r
restore_files(
  from,
  to,
  ...,
  backup = TRUE,
  description = NA_character_,
  backup_dir = seekr_option("seekr.backup_dir"),
  .progress = seekr_option("seekr.progress")
)

restore_files_interactive(
  from,
  to,
  ...,
  backup = TRUE,
  description = NA_character_,
  backup_dir = seekr_option("seekr.backup_dir"),
  .progress = seekr_option("seekr.progress")
)
```

## Arguments

- from:

  Character vector of source file paths to copy from. Typically the
  `backup` column of
  [`list_backups()`](https://smartiing.github.io/seekr/reference/backups.md)
  or
  [`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md).
  All files must exist.

- to:

  Character vector of destination file paths to copy to. Typically the
  `original` column of
  [`list_backups()`](https://smartiing.github.io/seekr/reference/backups.md)
  or
  [`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md).
  Must be the same length as `from`, with no duplicates. Destination
  files do not need to exist.

- ...:

  For `restore_files()`: these dots are for future extensions and must
  be empty.

  For `restore_files_interactive()`: additional arguments passed to
  [`diffobj::diffFile()`](https://rdrr.io/pkg/diffobj/man/diffFile.html),
  allowing you to customize the diff display. For example,
  `mode = "unified"` switches to a unified diff format.

- backup:

  Whether to create a backup of the current files before overwriting the
  files. Default is `TRUE`. Set to `FALSE` to skip the backup, for
  example if the files are already tracked by another version control
  system.

- description:

  Optional character string stored in the backup metadata when
  `backup = TRUE`. Use it to describe why the backup was created.
  Defaults to `NA`.

- backup_dir:

  Path to the backup directory. Defaults to
  `seekr_option("seekr.backup_dir")`, which resolves to a
  platform-specific user data directory. Change the default globally
  with `options(seekr.backup_dir = "/your/path")`.

- .progress:

  Whether to display progress messages. Default is `TRUE` in interactive
  sessions and `FALSE` otherwise (see
  [`rlang::is_interactive()`](https://rlang.r-lib.org/reference/is_interactive.html)).
  Can be set globally with `options(seekr.progress = FALSE)`.

## Value

Both functions invisibly return the `to` paths of the files that were
actually restored. For `restore_files()` this is always the full `to`
vector. For `restore_files_interactive()` this is only the subset of
files the user chose to restore, an empty character vector if the user
cancelled or skipped all files.

## Interactive restore

`restore_files_interactive()` iterates over each file and shows a diff
between the backup (`from`) and the current version (`to`). For each
file, it prompts with the following choices:

- **Restore this file**: restore this file and move to the next.

- **Ignore this file**: skip this file and move to the next.

- **Restore all remaining files**: restore this file and all subsequent
  ones without further prompts.

- **Ignore all remaining files**: skip this file and all subsequent
  ones.

- **Cancel all planned changes**: abort immediately without restoring
  anything, including files already confirmed in this session.

No files are modified until after the last prompt. All choices are
collected first, then applied in a single `restore_files()` call.

`restore_files_interactive()` requires the
[diffobj](https://CRAN.R-project.org/package=diffobj) package. It can
only be called in an interactive session.

## See also

- [`list_backups()`](https://smartiing.github.io/seekr/reference/backups.md)
  and
  [`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md)
  to find the backup you want to restore.

- [`delete_backups()`](https://smartiing.github.io/seekr/reference/backups.md)
  to remove backups you no longer need.

- [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  which creates a backup before writing any changes.

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
#> Common Path: /tmp/Rtmpq5soNa/seekr_project1a0c4ed31396
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
#> 1     1 2026-07-07 06:19:21 replace   NA          /tmp/Rtmpq5soNa/seekr_… /tmp/…
#> 2     1 2026-07-07 06:19:21 replace   NA          /tmp/Rtmpq5soNa/seekr_… /tmp/…
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
#> 1     2 2026-07-07 06:19:21 restore   NA          /tmp/Rtmpq5soNa/seekr_… /tmp/…
#> 2     2 2026-07-07 06:19:21 restore   NA          /tmp/Rtmpq5soNa/seekr_… /tmp/…
#> 3     1 2026-07-07 06:19:21 replace   NA          /tmp/Rtmpq5soNa/seekr_… /tmp/…
#> 4     1 2026-07-07 06:19:21 replace   NA          /tmp/Rtmpq5soNa/seekr_… /tmp/…
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
#> Common Path: /tmp/Rtmpq5soNa/seekr_project1a0c4ed31396
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
