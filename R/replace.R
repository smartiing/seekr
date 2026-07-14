#' Replace selected matches in files
#'
#' @description
#' [replace_files()] applies the replacements stored in a [seekr_match] object
#' to the corresponding files and writes (in **UTF-8**) the modified files back
#' to disk.
#'
#' It is the final step of the usual seekr workflow: search with [seek()]/[match_files()],
#' inspect or modify the resulting matches, then apply the replacements with `replace_files()`.
#'
#' @inheritParams seek
#' @inheritParams backups
#'
#' @param x A [`seekr_match`] object with replacement values created
#'   by [seek()]/[seekr()] or [match_files()]. Replacement field
#'   must be set for all matches, either computed when searching for matches or
#'   modified manually before calling `replace_files()`.
#' @param description Optional character string stored in the backup metadata
#'   when `backup = TRUE`. Use it to describe why the backup was created.
#'   Defaults to `NA`.
#' @param backup Whether to create a backup of the current files before overwriting
#' the files. Default is `TRUE`. Set to `FALSE` to skip the backup, for example if
#' the files are already tracked by another version control system.
#' @param allow_encoding_change Should `replace_files()` allow files that were
#'   read with a non-UTF-8 encoding to be written back in UTF-8? The default is
#'   `FALSE` as this should be intentional.
#'
#' @details
#' `replace_files()` is designed to be conservative. Before any file is modified,
#' it checks that the replacements stored in `x` can still be applied safely.
#'
#' Missing files are detected before the replacement process starts.
#'
#' This safety check is intentionally performed in two passes. In the first pass,
#' before creating backups, `replace_files()` re-reads every target file and
#' verifies that its current text has the same hash as the text that was searched
#' when the matches were created. If any file fails this check, the operation
#' aborts before backups are created and before any file is modified. This helps
#' avoid partial replacements, for example replacing the first few files
#' successfully and then failing on a later file.
#'
#' If all files pass the first check, backups are created when `backup = TRUE`.
#' Then `replace_files()` loops over the files again. For each file, it re-reads
#' the current content, verifies the hash a second time, applies the replacements
#' in memory, and writes the modified text back to disk in UTF-8. This second
#' check protects against concurrent edits that may happen between the initial
#' verification and the actual write.
#'
#' Missing files are skipped with a warning. In that case, the returned
#' [`seekr_match`] object contains only the matches that were actually replaced.
#'
#' Replacements are applied file by file. Within each file, matches are replaced
#' from the end of the file to the beginning, so earlier replacements do not shift
#' the recorded positions of later replacements.
#'
#' By default, a backup of the current version of each modified file is created
#' before replacement. Use [list_backups()] and [last_backup()] to inspect
#' backups, and [restore_files()] or [restore_files_interactive()] to restore
#' them.
#'
#' For advanced in-memory text workflows where you do not want seekr to read,
#' write, or create backups, use [replace_text()].
#'
#' @return
#' Invisibly returns the [`seekr_match`] object containing the matches that were
#' actually replaced. If missing files were skipped, matches from those files are
#' not included in the returned object.
#'
#' @seealso
#' - [seek()] and [seekr()] to create matches with planned replacements.
#' - [filter_match()] to keep only some matches before replacing.
#' - [list_backups()] and [last_backup()] to inspect backups.
#' - [restore_files()] and [restore_files_interactive()] to restore files.
#'
#' @inherit backups examples
#'
#' @export
replace_files = function(
  x,
  ...,
  backup = TRUE,
  description = NA_character_,
  allow_encoding_change = FALSE,
  backup_dir = seekr_option("seekr.backup_dir"),
  .progress = seekr_option("seekr.progress")
) {
  rlang::check_dots_empty()
  x = sort_within_files(x)
  assert_match_for_replacement(x)
  assert_flag(backup)
  assert_backup_description(description)
  assert_flag(allow_encoding_change)
  assert_paths(backup_dir, len = 1L)
  assert_flag(.progress)

  if (rlang::is_empty(x)) {
    cli::cli_inform(c("i" = "No replacement to perform: empty {.cls seekr_match} object."))
    return(invisible(x))
  }

  missing_encoding = is.na(field(x, "encoding"))

  if (any(missing_encoding)) {
    cli::cli_abort(
      c(
        "Cannot replace files with missing encoding information.",
        "x" = "Some matches were created without a recorded file encoding.",
        "i" = "This can happen when using {.fn match_text} on text that was already in memory.",
        "i" = "Use {.fn replace_text} for in-memory workflows, or supply {.arg encoding} to {.fn match_text} if the matches should later be passed to {.fn replace_files}.",
        "i" = "seekr needs to know how to read the file from disk."
      ),
      class = "seekr_error_replace_files_missing_encoding"
    )
  }

  missing_files = unique(field(x, "path")[!fs::file_exists(field(x, "path"))])

  if (!rlang::is_empty(missing_files)) {
    n_missing = length(missing_files)
    cli::cli_warn(
      c(
        "Some matches will not be replaced because the files no longer exist.",
        "x" = "{n_missing} file{?s} could not be found.",
        "i" = "Matches from missing files were skipped before replacement.",
        "i" = "The returned {.cls seekr_match} object contains only matches that were actually replaced."
      ),
      class = "seekr_warn_missing_files"
    )

    x = x[!field(x, "path") %in% missing_files]

    if (rlang::is_empty(x)) {
      cli::cli_inform(c("i" = "No replacement to perform: all files are missing."))
      return(invisible(x))
    }
  }

  if (!allow_encoding_change) {
    non_utf8 = !stringr::str_detect(field(x, "encoding"), "(?i)utf-?8")
    non_utf8_path = unique(field(filter_match(x, non_utf8), "path"))
    if (!rlang::is_empty(non_utf8_path)) {
      N = length(non_utf8_path)
      cli::cli_abort(
        c(
          "{.fn replace_files} would change the encoding of {N} file{?s}.",
          "x" = "{N} file{?s} {?was/were} read with a non-UTF-8 encoding but would be written in UTF-8.",
          "i" = "Set {.code allow_encoding_change = TRUE} to allow this and write these files in UTF-8.",
          "i" = "Use {.fn match_text} and {.fn replace_text} if you need to control how modified text is written to disk."
        ),
        class = "seekr_error_replace_files_encoding_change"
      )
    }
  }

  xi = split_match_by_source(x)
  N = length(xi)

  i = 1
  if (.progress) {
    cli::cli_progress_step(
      msg = "Check file{plur(N, 's')}: {i}/{N}",
      msg_done = "Check file{plur(N, 's')}: {N}",
      spinner = TRUE)
  }

  for (i in seq_along(xi)) {
    file = field(xi[[i]], "path")[[1]]
    text = seekr_read_file(
      path = file,
      n_bytes = fs::file_size(file, fail = TRUE),
      encoding = field(xi[[i]], "encoding")[[1]]
    )

    assert_hash_for_replacement(text, xi[[i]])
    if (.progress) cli::cli_progress_update()
  }

  if (backup) {
    if (.progress) cli::cli_progress_step("Backup files: {length(xi)}")
    create_backup(unique(field(x, "path")), "replace", description, backup_dir)
  }

  i = 1
  match_i = 0
  n_match_total = length(x)

  if (.progress) {
    cli::cli_progress_step(
      msg = "Replace match{plur(n_match_total, 'es')}: {match_i}/{n_match_total} match{plur(n_match_total, 'es')} in {i}/{N} file{plur(i, 's')}",
      msg_done = "Replace match{plur(n_match_total, 'es')}: {n_match_total} match{plur(n_match_total, 'es')} replaced in {N} file{plur(N, 's')}",
      spinner = TRUE
    )
  }

  for (i in seq_along(xi)) {
    file = field(xi[[i]], "path")[[1]]
    text = seekr_read_file(
      path = file,
      n_bytes = fs::file_size(file, fail = TRUE),
      encoding = field(xi[[i]], "encoding")[[1]]
    )

    assert_hash_for_replacement(text, xi[[i]])
    replaced_text = replace_text(text, xi[[i]])
    write_replaced_text_to_file(replaced_text, file)

    match_i = match_i + length(xi[[i]])
    if (.progress) cli::cli_progress_update()
  }

  return(invisible(x))
}


#' Replace selected matches in text
#'
#' @description
#' `replace_text()` is the in-memory counterpart of [replace_files()]. It applies
#' the replacements stored in a [`seekr_match`] object to text and returns the
#' modified text.
#'
#' It does not read files, write files, or create backups. Use [replace_files()]
#' for the usual file-based workflow.
#'
#' @param text Text content as a single string.
#' @param x A [`seekr_match`] object with replacement values. All matches in `x`
#'   must be associated with the same file and must refer to positions in
#'   `text`.
#'
#' @return
#' A single character string containing `text` after applying the replacements
#' stored in `x`.
#'
#' @details
#' `replace_text()` verifies that the current text has the same hash as the text
#' that was searched when the matches were created. If the text has changed,
#' replacement is considered unsafe and the function aborts.
#'
#' Matches are replaced from the end of the text to the beginning, so earlier
#' replacements do not shift the recorded positions of later replacements.
#'
#' `replace_text()` requires `x` to contain matches from a single source, the
#' one corresponding to `text`
#'
#' @seealso
#' - [match_text()] to create matches from already-read text.
#' - [replace_files()] to apply replacements directly to files.
#' - [filter_match()] to keep only some matches before replacing.
#'
#' @examples
#' text <- "hello old_name\nbye old_name"
#'
#' x <- match_text(
#'   text = text,
#'   path = "example.txt",
#'   pattern = "old_name",
#'   replacement = "new_name"
#' )
#'
#' replace_text(text, x)
#'
#' @export
replace_text = function(text, x) {
  assert_file_text(text)
  x = sort_within_files(x)
  assert_match_for_replacement(x)

  if (length(x) == 0L) {
    return(text)
  }

  paths = unique(field(x, "path"))
  if (length(paths) > 1L) {
    cli::cli_abort(
      c(
        "{.arg x} must contain matches from a single source.",
        "x" = "It contains matches from {length(paths)} sources.",
        "i" = "Call {.fn replace_text} with only the matches corresponding to the supplied text."
      ),
      class = "seekr_error_replace_text_multiple_files"
    )
  }

  assert_hash_for_replacement(text, x)

  start = field(x, "start")
  end = field(x, "end")
  repl = field(x, "replacement")

  for (i in rev(seq_along(start))) {
    stringr::str_sub(text, start[[i]], end[[i]]) = repl[[i]]
  }

  return(text)
}


#' @keywords internal
write_replaced_text_to_file = function(text, path) {
  ts_ms = stringr::str_remove(format(Sys.time(), "%Y%m%dT%H%M%OS3"), "\\.")
  path_tmp = file.path(dirname(path), glue::glue("{ts_ms}_seekr_tmp__{basename(path)}"))
  readr::write_file(text, path_tmp, append = FALSE)
  fs::file_move(path_tmp, path)

  return(invisible(path))
}
