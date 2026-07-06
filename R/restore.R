#' Restore files from backups
#'
#' @description
#' `restore_files()` copies files from a backup location back to their
#' original paths, overwriting the current versions. By default, it creates a
#' new backup of the current files before overwriting, so the restore itself
#' can be undone.
#'
#' `restore_files_interactive()` works the same way but shows a side-by-side
#' diff (powered by [diffobj::diffFile()]) for each file before asking whether
#' to restore it. This is useful when you want to review the difference between
#' the current version of the file and its backup.
#'
#' The typical workflow is to call [list_backups()] or [last_backup()] to find
#' the backup you want, then pass the `backup` and `original` columns to
#' `restore_files()`:
#'
#' ```r
#' b <- last_backup()
#' restore_files(from = b$backup, to = b$original)
#' ```
#'
#' @section Interactive restore:
#' `restore_files_interactive()` iterates over each file and shows a diff
#' between the backup (`from`) and the current version (`to`). For each file,
#' it prompts with the following choices:
#'
#' - **Restore this file**: restore this file and move to the next.
#' - **Ignore this file**: skip this file and move to the next.
#' - **Restore all remaining files**: restore this file and all subsequent ones
#'   without further prompts.
#' - **Ignore all remaining files**: skip this file and all subsequent ones.
#' - **Cancel all planned changes**: abort immediately without restoring
#'   anything, including files already confirmed in this session.
#'
#' No files are modified until after the last prompt. All choices are
#' collected first, then applied in a single `restore_files()` call.
#'
#' `restore_files_interactive()` requires the
#' [diffobj](https://CRAN.R-project.org/package=diffobj) package. It can only
#' be called in an interactive session.
#'
#' @param from Character vector of source file paths to copy from. Typically
#'   the `backup` column of [list_backups()] or [last_backup()]. All files
#'   must exist.
#'
#' @param to Character vector of destination file paths to copy to. Typically
#'   the `original` column of [list_backups()] or [last_backup()]. Must be the
#'   same length as `from`, with no duplicates. Destination files do not need
#'   to exist.
#'
#' @inheritParams replace_files
#' @inheritParams seek
#'
#' @param ... For `restore_files()`: these dots are for future extensions and
#'   must be empty.
#'
#'   For `restore_files_interactive()`: additional arguments passed to
#'   [diffobj::diffFile()], allowing you to customize the diff display. For
#'   example, `mode = "unified"` switches to a unified diff format.
#'
#' @return
#' Both functions invisibly return the `to` paths of the files that were
#' actually restored. For `restore_files()` this is always the full `to`
#' vector. For `restore_files_interactive()` this is only the subset of files
#' the user chose to restore, an empty character vector if the user cancelled
#' or skipped all files.
#'
#' @seealso
#' - [list_backups()] and [last_backup()] to find the backup you want to
#'   restore.
#' - [delete_backups()] to remove backups you no longer need.
#' - [replace_files()] which creates a backup before writing any changes.
#'
#' @inherit backups examples
#'
#' @name restore_files
#' @export
restore_files = function(
  from,
  to,
  ...,
  backup = TRUE,
  description = NA_character_,
  backup_dir = seekr_option("seekr.backup_dir"),
  .progress = seekr_option("seekr.progress")
) {
  rlang::check_dots_empty()
  assert_restore_from_to(from, to)
  assert_flag(backup)
  assert_backup_description(description)
  assert_paths(backup_dir, len = 1L)
  assert_flag(.progress)

  if (rlang::is_empty(from)) {
    cli::cli_inform(c(
      "i" = "No file to restore"
    ))
    return(invisible(from))
  }

  if (backup) {
    cli::cli_inform(c(
      "i" = "Creating a backup of the current version of each existing destination file before restoring it.",
      "i" = "This ensures you can revert to the state before restoration if needed."
    ))
    if (.progress) cli::cli_progress_step("Backup files: {length(to[fs::file_exists(to)])}")
    create_backup(to[fs::file_exists(to)], "restore", description, backup_dir)
  }

  if (.progress) cli::cli_progress_step("Restore files: {length(from)}")
  fs::file_copy(path = from, new_path = to, overwrite = TRUE)

  return(invisible(to))
}


#' @rdname restore_files
#' @export
restore_files_interactive = function(
  from,
  to,
  ...,
  backup = TRUE,
  description = NA_character_,
  backup_dir = seekr_option("seekr.backup_dir"),
  .progress = seekr_option("seekr.progress")
) {
  if (!rlang::is_interactive()) {
    cli::cli_abort(
      "{.fn restore_files_interactive} can only be used in an interactive session.",
      class = "seekr_error_restore_non_interactive"
    )
  }

  if (!rlang::is_installed("diffobj")) {
    cli::cli_abort(
      c(
        "{.pkg diffobj} is required to show file diffs.",
        "i" = "Install it with {.code install.packages(\"diffobj\")}."
      ),
      class = "seekr_error_dependency_not_installed"
    )
  }

  if (rlang::is_empty(from)) {
    cli::cli_inform(c(
      "i" = "No file to restore"
    ))
    return(invisible(from))
  }

  assert_restore_from_to(from, to)
  assert_flag(backup)
  assert_backup_description(description)
  assert_paths(backup_dir, len = 1L)
  assert_flag(.progress)

  N = length(from)
  restore = logical(N)

  ddd_args = list(...)
  default_args = list(
    mode = "sidebyside",
    format = "auto",
    color.mode = "rgb"
  )

  diff_obj_args = utils::modifyList(
    x = default_args,
    val = ddd_args,
    keep.null = FALSE
  )

  for (i in seq_along(restore)) {
    cli::cli_h3("Restoring {.file {to[[i]]}}")

    if (fs::file_exists(to[[i]])) {
      tmp_args = c(
        target = from[[i]],
        current = to[[i]],
        diff_obj_args
      )

      diff_obj = do.call(diffobj::diffFile, args = tmp_args)
      methods::show(diff_obj)
    } else {
      cli::cli_inform(c(
        "i" = "Destination file does not exist yet.",
        "i" = "Restoring this backup will create it.",
        "i" = "{.path {to[[i]]}}"
      ))
    }

    choice = restore_backup_menu()

    if (choice == "restore_one") {
      restore[[i]] = TRUE
    } else if (choice == "ignore_one") {
      next
    } else if (choice == "restore_remaining") {
      restore[i:N] = TRUE
      break
    } else if (choice == "ignore_remaining") {
      restore[i:N] = FALSE
      break
    } else if (choice == "cancel") {
      cli::cli_inform(c("i" = "No file restored."))
      return(invisible(to[0]))
    } else {
      cli::cli_abort(c(
        "Internal error while handling restore choice.",
        "x" = "Unknown menu choice {.val {choice}}.",
        "i" = "This is likely a bug in seekr."
      ))
    }
  }

  from = from[restore]
  to = to[restore]

  restore_files(
    from = from,
    to = to,
    backup = backup,
    description = description,
    backup_dir = backup_dir,
    .progress = .progress
  )

  return(invisible(to))
}


#' @keywords internal
restore_backup_menu = function() {
  choices = c(
    "restore_one" = "Restore this file",
    "ignore_one" = "Ignore this file",
    "restore_remaining" = "Restore all remaining files",
    "ignore_remaining" = "Ignore all remaining files",
    "cancel" = "Cancel all planned changes"
  )

  choice = 0L
  while (!choice %in% seq_along(choices)) {
    choice = utils::menu(choices, title = "How to proceed?")
  }

  names(choices)[[choice]]
}
