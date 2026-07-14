# Replace selected matches in files

`replace_files()` applies the replacements stored in a
[seekr_match](https://smartiing.github.io/seekr/reference/seekr_match.md)
object to the corresponding files and writes (in **UTF-8**) the modified
files back to disk.

It is the final step of the usual seekr workflow: search with
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md)/[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md),
inspect or modify the resulting matches, then apply the replacements
with `replace_files()`.

## Usage

``` r
replace_files(
  x,
  ...,
  backup = TRUE,
  description = NA_character_,
  allow_encoding_change = FALSE,
  backup_dir = seekr_option("seekr.backup_dir"),
  .progress = seekr_option("seekr.progress")
)
```

## Arguments

- x:

  A
  [`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  object with replacement values. Typically created by
  [`seek()`](https://smartiing.github.io/seekr/reference/seek.md),
  [`seekr()`](https://smartiing.github.io/seekr/reference/seek.md),
  [`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md),
  or
  [`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md).
  Replacement field must be set for all matches, either computed when
  searching for matches or modified manually before calling
  `replace_files()`.

- ...:

  These dots are for future extensions and must be empty.

- backup:

  Whether to create a backup of the current files before overwriting the
  files. Default is `TRUE`. Set to `FALSE` to skip the backup, for
  example if the files are already tracked by another version control
  system.

- description:

  Optional character string stored in the backup metadata when
  `backup = TRUE`. Use it to describe why the backup was created.
  Defaults to `NA`.

- allow_encoding_change:

  Should `replace_files()` allow files that were read with a non-UTF-8
  encoding to be written back in UTF-8? The default is `FALSE` as this
  should be intentional.

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

Invisibly returns the
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
object containing the matches that were actually replaced. If missing
files were skipped, matches from those files are not included in the
returned object.

## Details

`replace_files()` is designed to be conservative. Before any file is
modified, it checks that the replacements stored in `x` can still be
applied safely.

Missing files are detected before the replacement process starts.

This safety check is intentionally performed in two passes. In the first
pass, before creating backups, `replace_files()` re-reads every target
file and verifies that its current text has the same hash as the text
that was searched when the matches were created. If any file fails this
check, the operation aborts before backups are created and before any
file is modified. This helps avoid partial replacements, for example
replacing the first few files successfully and then failing on a later
file.

If all files pass the first check, backups are created when
`backup = TRUE`. Then `replace_files()` loops over the files again. For
each file, it re-reads the current content, verifies the hash a second
time, applies the replacements in memory, and writes the modified text
back to disk in UTF-8. This second check protects against concurrent
edits that may happen between the initial verification and the actual
write.

Missing files are skipped with a warning. In that case, the returned
[`seekr_match`](https://smartiing.github.io/seekr/reference/seekr_match.md)
object contains only the matches that were actually replaced.

Replacements are applied file by file. Within each file, matches are
replaced from the end of the file to the beginning, so earlier
replacements do not shift the recorded positions of later replacements.

By default, a backup of the current version of each modified file is
created before replacement. Use
[`list_backups()`](https://smartiing.github.io/seekr/reference/backups.md)
and
[`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md)
to inspect backups, and
[`restore_files()`](https://smartiing.github.io/seekr/reference/restore_files.md)
or
[`restore_files_interactive()`](https://smartiing.github.io/seekr/reference/restore_files.md)
to restore them.

For advanced in-memory text workflows where you do not want seekr to
read, write, or create backups, use
[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md).

## See also

- [`seek()`](https://smartiing.github.io/seekr/reference/seek.md) and
  [`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) to
  create matches with staged replacements.

- [`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
  to keep only some matches before replacing.

- [`list_backups()`](https://smartiing.github.io/seekr/reference/backups.md)
  and
  [`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md)
  to inspect backups.

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
#> Common Path: /tmp/RtmpSHbDD3/seekr_project1a275ea69a82
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
#> 1     1 2026-07-14 15:11:46 replace   NA          /tmp/RtmpSHbDD3/seekr_… /tmp/…
#> 2     1 2026-07-14 15:11:46 replace   NA          /tmp/RtmpSHbDD3/seekr_… /tmp/…
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
#> 1     2 2026-07-14 15:11:46 restore   NA          /tmp/RtmpSHbDD3/seekr_… /tmp/…
#> 2     2 2026-07-14 15:11:46 restore   NA          /tmp/RtmpSHbDD3/seekr_… /tmp/…
#> 3     1 2026-07-14 15:11:46 replace   NA          /tmp/RtmpSHbDD3/seekr_… /tmp/…
#> 4     1 2026-07-14 15:11:46 replace   NA          /tmp/RtmpSHbDD3/seekr_… /tmp/…
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
#> Common Path: /tmp/RtmpSHbDD3/seekr_project1a275ea69a82
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
