#' Find matches in text files
#'
#' @description
#' `seek()` searches text files for a pattern and returns a [`seekr_match`]
#' vector. The result can be inspected, filtered, and passed to [replace_files()]
#' to apply replacements.
#'
#' `seekr()` is a convenience wrapper around `seek()` that restricts the search
#' to R, R Markdown, and Quarto files (`.R`, `.Rmd`, `.qmd`).
#'
#' [`list_files()`], [`filter_files()`], and [`match_files()`] are the three building
#' blocks of [`seek()`]. They can be called individually when you need more
#' control over each step.
#'
#' ## Steps
#'
#' - **[list_files()]** starts from `path`, optionally `use_git` to restrict file
#'   discovery, and `recurse`s into subdirectories to list files.  By default, not
#'   `all` files are listed, with hidden files and directories excluded.
#'
#' - **[filter_files()]** keeps files matching `extension` and `path_pattern` and
#'   not exceeding `max_file_size`. Finally, the `exclude` functions are applied to
#'   the remaining files, discarding common non-text or irrelevant files by default.
#'
#' - **[match_files()]** reads each file, decodes them using `encoding`, finds
#'   `pattern` matches, and captures surrounding `context` lines. A `replacement`
#'    can be provided to stage changes for later application with [replace_files()].
#'
#' @param pattern Pattern to search for, matched using [stringr] (ICU regular
#'   expressions). Either:
#'   - A string, automatically wrapped as `stringr::regex()` with
#'     `ignore_case = FALSE`, `multiline = TRUE`, `comments = FALSE`, and
#'     `dotall = FALSE`.
#'   - A `stringr_pattern` object such as [stringr::regex()],
#'     [stringr::fixed()], or [stringr::coll()], used as-is for more control.
#'
#' @param replacement Replacement to associate with each match. Replacements are
#'   computed immediately during the search and stored in the result. Either:
#'   - `NULL` (default): no replacement. [replace_files()] cannot be called
#'     without setting replacements first.
#'   - A plain string, used literally as replacement text.
#'   - A string with backreferences of the form `\1`, `\2`, etc., replaced
#'     with the corresponding capture group from `pattern`.
#'   - A function, called once per file with a character vector of all matches
#'     found in that file, and expected to return a character vector of the same
#'     length (e.g. [toupper]).
#'   - A function wrapped with [with_capture_groups_matrix()], called once per file with a
#'     character matrix where the first column is the full match and the
#'     remaining columns are the capture groups.
#'
#' @param ... These dots are for future extensions and must be empty.
#'
#' @param path A character vector of one or more existing directories to
#'   search in. Defaults to `"."` (the current working directory).
#'
#' @param recurse Controls how deep the directory traversal goes to list files. Either:
#'   - `TRUE` (default): recurse into all subdirectories.
#'   - `FALSE`: only list files at the top level of each directory in `path`.
#'   - A positive integer: limit recursion to that many levels deep.
#'
#' @param all Whether to list hidden files and directories. Default is `FALSE`.
#'
#' @param use_git Should Git be used to restrict file discovery inside Git
#'   repositories? If `TRUE`, [list_files()] keeps only files that were first
#'   discovered according to `path`, `recurse`, and `all`, and are also returned
#'   by `git ls-files --cached --others --exclude-standard`. `use_git = TRUE` looks
#'   for the Git root by walking upward from each supplied `path`, but it does not
#'   recursively search downward for Git repositories in subdirectories. Git must
#'   be installed and available on `PATH`.
#'
#' @param extension Optional character vector of file extensions to keep.
#'   Either:
#'   - `NULL` (default): no filtering by extension; all extensions are kept.
#'   - A character vector of extensions to keep, with or without a leading dot
#'     (e.g. `c("R", ".Rmd", "qmd")`).
#'
#'   Extensions are normalized before matching: leading dots are stripped,
#'   matching is case-insensitive, and duplicates are ignored. Only the last
#'   component of compound extensions is used (e.g. `"tar.gz"` uses `"gz"`),
#'   with a warning.
#'
#' @param path_pattern Optional pattern applied to filter normalized file paths (see
#'   [`as_seekr_path()`]). Either:
#'   - `NULL` (default): no filtering by path.
#'   - A string, interpreted as a regular expression via [stringr::regex()].
#'   - A `stringr_pattern` object such as [stringr::regex()] or
#'     [stringr::fixed()].
#'
#' @param max_file_size Maximum file size in bytes. Files larger than this
#'   value are excluded. Default is `Inf`, meaning no files are excluded by
#'   size. Zero and negative values are treated as `Inf`.
#'
#' @param exclude Named list of functions used to exclude unwanted
#'   files during filtering. Either:
#'   - `NULL`, to disable additional exclude functions.
#'   - A named list of functions, each taking a character vector of normalized
#'     file paths and returning a logical vector of the same length, where
#'     `TRUE` means the file should be excluded.
#'
#'   Defaults to [exclude_functions], which excludes common non-text or
#'   irrelevant files.
#'
#' @param context Number of surrounding lines to capture around each match.
#'   Either:
#'   - A single non-negative integer (default: `5L`): captures the same number
#'     of lines before and after each match.
#'   - A pair of non-negative integers `c(before, after)`: captures `before`
#'     lines before and `after` lines after each match.
#'
#' @param encoding Encoding used to decode file content during the matching
#'   step. Either:
#'   - A single string (default: `"UTF-8"`), applied to all files.
#'   - `NULL`: encoding is guessed for each file individually using
#'     [stringi::stri_enc_detect()], falling back to `"UTF-8"` when detection
#'     fails.
#'
#'   Note: [replace_files()] always writes files in UTF-8. A warning is issued
#'   once per session when any file is read with a non-UTF-8 encoding. By default,
#'   [replace_files()] refuses to write those matches unless
#'   `allow_encoding_change = TRUE` is set.
#'
#' @param .progress Whether to display progress messages. Default is `TRUE` in
#'   interactive sessions and `FALSE` otherwise (see [rlang::is_interactive()]).
#'   Can be set globally with `options(seekr.progress = FALSE)`.
#'
#' @return
#' A [`seekr_match`] vector. Each element represents one match and carries the
#' file path, match position, matched text, optional replacement, context
#' lines, encoding, and a hash of the searched text used for replacement safety.
#'  The vector is always returned, even when empty.
#'
#' An attribute `"exclusions"` is attached to the result after filtering, containing
#' a data frame with one row per input file and one column per exclusion function,
#' detailing which files were excluded and why. Retrieve it with [exclusions()].
#'
#' If the result is empty, use [empty_stage()] to see whether the pipeline became
#' empty during input, listing, filtering, or matching.
#'
#' @seealso
#' - [seekr_match] for the match object structure and available methods.
#' - [print.seekr_match()] and [summary.seekr_match()] to inspect results.
#' - [filter_match()] to subset matches.
#' - [replace_files()] to apply replacements.
#'
#' @examples
#' # Create a small temporary project to search in
#' example_dir <- tempfile("seekr-example")
#' dir.create(example_dir)
#' dir.create(file.path(example_dir, "R"))
#' dir.create(file.path(example_dir, "tests"))
#' dir.create(file.path(example_dir, "data"))
#'
#' writeLines(
#'   c(
#'     "old_fn <- function(x) {",
#'     "  # TODO: rename foo",
#'     "  foo + x",
#'     "}"
#'   ),
#'   file.path(example_dir, "R", "code.R")
#' )
#'
#' writeLines(
#'   c(
#'     "test_that('foo works', {",
#'     "  # TODO: update test",
#'     "  expect_equal(foo, 1)",
#'     "})"
#'   ),
#'   file.path(example_dir, "tests", "test-code.R")
#' )
#'
#' writeLines(
#'   c(
#'     "name,value",
#'     "foo,1",
#'     "bar,2"
#'   ),
#'   file.path(example_dir, "data", "values.csv")
#' )
#'
#' # seek() is built from three lower-level functions
#' files <- list_files(example_dir)
#' filtered <- filter_files(files, extension = "R", path_pattern = "/R/")
#' x <- match_files(filtered, "foo", "bar")
#'
#' # These functions can be piped
#' y <-
#'   example_dir |>
#'   list_files() |>
#'   filter_files(extension = "R", path_pattern = "/R/") |>
#'   match_files("foo", "bar")
#'
#' identical(x, y)
#'
#' # This is equivalent to the seek() call below
#' z <- seek("foo", "bar", path = example_dir, extension = "R", path_pattern = "/R/")
#' identical(y, z)
#'
#' # Search for a pattern in all text files
#' x <- seek("TODO", path = example_dir)
#' print(x)
#'
#' # Search only in R files
#' seek("TODO", path = example_dir, extension = "R")
#'
#' # Search only in a specific subfolder
#' seek("TODO", path = example_dir, path_pattern = "/R/")
#'
#' # seekr() is a shortcut for searching R, R Markdown, and Quarto files
#' seekr("old_fn", path = example_dir)
#'
#' # Stage a plain string replacement
#' x <- seek("old_fn", "new_fn", path = example_dir)
#' x
#'
#' # Stage replacements with a function
#' x <- seek(
#'   "foo|bar",
#'   replacement = function(x) ifelse(x == "foo", "bar", "foo"),
#'   path = example_dir
#' )
#' x
#'
#' # Stage replacements after searching
#' x <- seekr("foo|bar", path = example_dir)
#' field(x, "replacement") <- ifelse(field(x, "match") == "foo", "bar", "foo")
#' x
#'
#' # Create a temporary backup directory
#' backup_dir <- tempfile("seekr-backup")
#' dir.create(backup_dir)
#'
#' # Apply replacements after inspection
#' replace_files(x, backup_dir = backup_dir)
#'
#' # Restore files from the latest backup
#' bck <- last_backup(backup_dir = backup_dir)
#' restore_files(from = bck$backup, to = bck$original, backup_dir = backup_dir)
#'
#' # See which files were excluded
#' exclusions(x)
#'
#' # empty_stage() explains where the pipeline became empty
#' dir.create(file.path(example_dir, "empty"))
#'
#' empty_stage(seek("foo", path = character()))
#' empty_stage(seek("foo", path = file.path(example_dir, "empty")))
#' empty_stage(seek("foo", path = example_dir, extension = "dummy"))
#' empty_stage(seek("missing_pattern", path = example_dir))
#'
#' # Remove the two temporary directories
#' unlink(backup_dir, recursive = TRUE)
#' unlink(example_dir, recursive = TRUE)
#'
#' @name seek
#' @order 1
#' @export
seek = function(
  pattern,
  replacement = NULL,
  ...,
  path = ".",
  recurse = TRUE,
  all = FALSE,
  use_git = FALSE,
  extension = NULL,
  path_pattern = NULL,
  max_file_size = Inf,
  exclude = seekr::exclude_functions,
  context = 5L,
  encoding = "UTF-8",
  .progress = seekr_option("seekr.progress")
) {
  rlang::check_dots_empty()

  assert_path_list_files(path)
  assert_recurse(recurse)
  assert_flag(all)

  assert_extension(extension)
  assert_pattern(path_pattern, null_ok = TRUE)
  assert_max_file_size(max_file_size)
  assert_exclude(exclude)

  assert_pattern(pattern)
  assert_replacement(replacement, pattern)
  assert_context(context)
  assert_encoding(encoding, null_ok = TRUE)

  assert_flag(.progress)

  if (rlang::is_empty(path)) {
    matches = structure(new_seekr_match(), empty_stage = "input")
    return(matches)
  }

  files = list_files(
    path = path,
    recurse = recurse,
    all = all,
    use_git = use_git,
    .progress = .progress
  )

  if (rlang::is_empty(files)) {
    matches = structure(new_seekr_match(), empty_stage = "list")
    return(matches)
  }

  filtered = filter_files(
    path = files,
    extension = extension,
    path_pattern = path_pattern,
    max_file_size = max_file_size,
    exclude = exclude,
    .progress = .progress
  )

  if (rlang::is_empty(filtered)) {
    cli::cli_inform(
      "Use {.fn exclusions} to understand why all files were excluded.",
      .frequency = "once",
      .frequency_id = "empty_stage_filter"
    )

    matches = structure(
      new_seekr_match(),
      empty_stage = "filter",
      exclusions = attr(filtered, "exclusions", exact = TRUE)
    )

    return(matches)
  }

  matches = match_files(
    path = filtered,
    pattern = pattern,
    replacement = replacement,
    context = context,
    encoding = encoding,
    .progress = .progress
  )

  matches = structure(
    matches,
    empty_stage = if (rlang::is_empty(matches)) "match",
    exclusions = attr(filtered, "exclusions", exact = TRUE)
  )

  return(matches)
}


#' @rdname seek
#' @order 2
#' @export
seekr = function(
  pattern,
  replacement = NULL,
  ...,
  path = ".",
  recurse = TRUE,
  all = FALSE,
  use_git = FALSE,
  path_pattern = NULL,
  max_file_size = Inf,
  exclude = seekr::exclude_functions,
  context = 5L,
  encoding = "UTF-8",
  .progress = seekr_option("seekr.progress")
) {
  rlang::check_dots_empty()

  seek(
    pattern = pattern,
    replacement = replacement,
    path = path,
    recurse = recurse,
    all = all,
    use_git = use_git,
    extension = c("R", "Rmd", "qmd"),
    path_pattern = path_pattern,
    max_file_size = max_file_size,
    exclude = exclude,
    context = context,
    encoding = encoding,
    .progress = .progress
  )
}


#' Diagnose where a workflow became empty
#'
#' @description
#' `empty_stage()` retrieves the pipeline stage that produced an empty
#' [`seekr_match`] result returned by [seek()] or [seekr()].
#'
#' Empty results can happen at different stages of the pipeline:
#'
#' - `"input"`: the input `path` was empty.
#' - `"list"`: no files were found by [list_files()].
#' - `"filter"`: all files were excluded by [filter_files()].
#' - `"match"`: files were searched, but no match was found.
#'
#' For non-empty results, `empty_stage()` returns `NULL`.
#'
#' @param x A [`seekr_match`] object, returned by either [seek()] or [seekr()].
#'
#' @return
#' Either `NULL` for non-empty results, or one of `"input"`, `"list"`,
#' `"filter"`, or `"match"` for empty results.
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' x <- seek("pattern_that_does_not_exist", path = ext_path)
#' empty_stage(x)
#'
#' @export
empty_stage = function(x) {
  if (!inherits(x, "seekr_match")) {
    return(NULL)
  }

  attr(x, "empty_stage", exact = TRUE)
}
