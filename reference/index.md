# Package index

## Search workflow

High-level functions for finding matches across files, from a complete
workflow in one call to explicit file listing, filtering, and matching
steps.

- [`seek()`](https://smartiing.github.io/seekr/reference/seek.md)
  [`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) :
  Find matches in text files
- [`list_files()`](https://smartiing.github.io/seekr/reference/list_files.md)
  : List files to search
- [`filter_files()`](https://smartiing.github.io/seekr/reference/filter_files.md)
  : Filter files to search
- [`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)
  : Find matches in files

## Search customization and diagnostics

Helpers for customizing how files are excluded, preparing more advanced
replacement logic, and understanding why a search workflow did or did
not produce results.

- [`with_capture_groups_matrix()`](https://smartiing.github.io/seekr/reference/with_capture_groups_matrix.md)
  : Use capture groups in function-based replacements
- [`empty_stage()`](https://smartiing.github.io/seekr/reference/empty_stage.md)
  : Diagnose where a workflow became empty
- [`exclusions()`](https://smartiing.github.io/seekr/reference/exclusions.md)
  : Inspect why files were excluded
- [`exclude_functions`](https://smartiing.github.io/seekr/reference/exclude_functions.md)
  [`is_git_dir()`](https://smartiing.github.io/seekr/reference/exclude_functions.md)
  [`is_dependency_dir()`](https://smartiing.github.io/seekr/reference/exclude_functions.md)
  [`is_minified_file()`](https://smartiing.github.io/seekr/reference/exclude_functions.md)
  [`is_not_text_mime()`](https://smartiing.github.io/seekr/reference/exclude_functions.md)
  : Default file exclusion functions

## Match vectors

Functions for inspecting, converting, filtering, summarizing, and
ordering `seekr_match` vectors.

- [`str(`*`<seekr_match>`*`)`](https://smartiing.github.io/seekr/reference/str.seekr_match.md)
  :

  Inspect the structure of a `seekr_match` vector

- [`print(`*`<seekr_match>`*`)`](https://smartiing.github.io/seekr/reference/print.seekr_match.md)
  : Print matches with context and replacement preview

- [`summary(`*`<seekr_match>`*`)`](https://smartiing.github.io/seekr/reference/summary.seekr_match.md)
  [`print(`*`<summary_seekr_match>`*`)`](https://smartiing.github.io/seekr/reference/summary.seekr_match.md)
  : Summarize matches and planned replacements

- [`as_tibble(`*`<seekr_match>`*`)`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
  [`as.data.frame(`*`<seekr_match>`*`)`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
  [`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
  :

  Convert `seekr_match` vectors to and from data frames

- [`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
  : Filter matches

- [`sort_within_files()`](https://smartiing.github.io/seekr/reference/sort_within_files.md)
  : Sort matches within each file

- [`new_seekr_match()`](https://smartiing.github.io/seekr/reference/seekr_match.md)
  :

  Create `seekr_match` vectors

## File replacement and backups

Apply planned replacements to files, inspect automatic backups, and
restore previous file contents when needed.

- [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
  : Replace selected matches in files
- [`list_backups()`](https://smartiing.github.io/seekr/reference/backups.md)
  [`last_backup()`](https://smartiing.github.io/seekr/reference/backups.md)
  [`delete_backups()`](https://smartiing.github.io/seekr/reference/backups.md)
  [`open_backup_dir()`](https://smartiing.github.io/seekr/reference/backups.md)
  : List, inspect, open, and delete backups
- [`restore_files()`](https://smartiing.github.io/seekr/reference/restore_files.md)
  [`restore_files_interactive()`](https://smartiing.github.io/seekr/reference/restore_files.md)
  : Restore files from backups

## Text-level workflow

Lower-level helpers for matching and replacing text that has already
been read, when you want to control input and output yourself.

- [`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
  : Find matches in text
- [`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md)
  : Replace selected matches in text

## Options and path helpers

Inspect package options and normalize file paths the same way `seekr`
does.

- [`seekr_option()`](https://smartiing.github.io/seekr/reference/seekr_option.md)
  : Retrieve a seekr option
- [`seekr_options()`](https://smartiing.github.io/seekr/reference/seekr_options.md)
  : List seekr options
- [`as_seekr_path()`](https://smartiing.github.io/seekr/reference/as_seekr_path.md)
  : Normalize file paths for seekr
