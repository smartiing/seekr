# Exported ----------------------------------------------------------------

#' List, inspect, open, and delete backups
#'
#' @description
#' By default, seekr creates a backup before [replace_files()] and
#' [restore_files()] modify files. These functions let you inspect and manage
#' existing backups in a particular `backup_dir`.
#'
#' - `list_backups()` returns a tibble of all existing backups.
#' - `last_backup()` returns only the most recent backup.
#' - `delete_backups()` permanently deletes one or more backups by their `id`.
#' - `open_backup_dir()` opens the current default backup directory.
#'
#' @section Backups:
#' Backups are stored under `backup_dir`, which defaults to a platform-specific
#' user data directory managed by [rappdirs::user_data_dir()]. Each backup
#' occupies its own numbered subdirectory (`000001/`, `000002/`, etc.)
#' containing a copy of each file and a `backup.RDS` metadata file.
#'
#' The default backup directory can be changed globally with:
#'
#' ```r
#' options(seekr.backup_dir = "/your/preferred/path")
#' ```
#'
#' @section Backup table columns:
#' `list_backups()` and `last_backup()` return a tibble with one row per
#' backed-up file and the following columns:
#'
#' - `id`: integer backup identifier, derived from the subdirectory name.
#'   All rows belonging to the same backup operation share the same `id`.
#' - `created_at`: date-time when the backup was created.
#' - `operation`: either `"replace"` (backup created by [replace_files()])
#'   or `"restore"` (backup created by [restore_files()]).
#' - `description`: optional description provided at backup time, or `NA`.
#' - `original`: absolute path to the original file.
#' - `backup`: absolute path to the backup copy.
#' - `original_exists`: whether the original file still exists on disk.
#' - `backup_exists`: whether the backup copy still exists on disk.
#' - `size`: size of the backup copy, as an `fs_bytes` value.
#'
#' @param backup_dir Path to the backup directory. Defaults to
#'   `seekr_option("seekr.backup_dir")`, which resolves to a
#'   platform-specific user data directory. Change the default globally with
#'   `options(seekr.backup_dir = "/your/path")`.
#'
#' @param id Integer vector of backup ids to delete, as found in the `id`
#'   column of `list_backups()`. Duplicate ids are silently deduplicated.
#'   Ids that do not correspond to any existing backup are silently ignored.
#'
#' @inheritParams seek
#'
#' @return
#' - `list_backups()` and `last_backup()` return a tibble as described in the
#' **Backup table columns** section. An empty tibble with the correct columns
#' is returned when no backups exist. `last_backup()` returns all rows belonging
#' to the most recent backup operation.
#'
#' - `delete_backups()` invisibly returns the paths of the deleted backup
#' subdirectories.
#'
#' - `open_backup_dir()` invisibly returns the path to the backup directory.
#'
#' @seealso
#' - [replace_files()] to apply replacements and create backups.
#' - [restore_files()] and [restore_files_interactive()] to restore files.
#'
#' @examples
#' # Set up a temporary project with two files
#' project_dir <- tempfile("seekr_project")
#' dir.create(project_dir)
#'
#' backup_dir <- tempfile("seekr_backups")
#' dir.create(backup_dir)
#'
#' file1 <- file.path(project_dir, "script1.R")
#' file2 <- file.path(project_dir, "script2.R")
#' writeLines("old_name <- function(x) x + 1", file1)
#' writeLines("y <- old_name(2)", file2)
#'
#' # Search for the pattern we want to replace
#' x <- seekr("old_name", replacement = "new_name", path = project_dir)
#' x
#'
#' # No backup exists yet
#' list_backups(backup_dir = backup_dir)
#'
#' # Apply the replacement; a backup is created automatically
#' replace_files(x, backup_dir = backup_dir)
#'
#' # The backup now contains the original (pre-replacement) version
#' # of both files, under id = 1
#' list_backups(backup_dir = backup_dir)
#'
#' # The files on disk have changed
#' readLines(file1)
#' readLines(file2)
#'
#' # Searching for the original pattern no longer finds anything
#' seekr("old_name", path = project_dir)
#'
#' # Restore the files from the backup; this itself creates a second
#' # backup (id = 2) of the current (replaced) version, before overwriting
#' b <- last_backup(backup_dir = backup_dir)
#' restore_files(from = b$backup, to = b$original, backup_dir = backup_dir)
#'
#' # We now have two backups: id = 1 is the state before replace_files(),
#' # id = 2 is the state before restore_files() (i.e. the replaced version)
#' list_backups(backup_dir = backup_dir)
#'
#' # The files are back to their original content
#' readLines(file1)
#' readLines(file2)
#'
#' # The original pattern is found again
#' seekr("old_name", path = project_dir)
#'
#' \dontrun{
#' # open_backup_dir() opens a file browser, so it is not run here
#' open_backup_dir()
#'
#' # Review each file interactively before restoring
#' restore_files_interactive(from = b$backup, to = b$original)
#'
#' # Customize the diff display (unified format)
#' restore_files_interactive(
#'   from = b$backup,
#'   to = b$original,
#'   mode = "unified",
#'   color.mode = "yb"
#' )
#'
#' # Finally, particular backups in a backup_dir can be deleted
#' b <- list_backups(backup_dir = backup_dir)
#' b
#' delete_backups(id = b$id, backup_dir = backup_dir)
#' }
#'
#'
#' unlink(project_dir, recursive = TRUE)
#' unlink(backup_dir, recursive = TRUE)
#'
#' @name backups
#' @export
list_backups = function(backup_dir = seekr_option("seekr.backup_dir")) {
  assert_paths(backup_dir, len = 1L)
  subdirs = list_backup_subdirs(backup_dir)

  if (rlang::is_empty(subdirs)) {
    return(empty_backup_table())
  }

  backup_tables = purrr::map(subdirs, read_backup)
  backups = purrr::list_rbind(backup_tables)
  backups$size = seekr_file_info(backups$backup)$size

  return(backups)
}


#' @rdname backups
#' @export
last_backup = function(backup_dir = seekr_option("seekr.backup_dir")) {
  assert_paths(backup_dir, len = 1L)
  backups = list_backups(backup_dir)

  if (nrow(backups) == 0L) {
    return(backups)
  }

  backups[backups$id == max(backups$id), ]
}


#' @rdname backups
#' @export
delete_backups = function(
  id,
  ...,
  backup_dir = seekr_option("seekr.backup_dir"),
  .progress = seekr_option("seekr.progress")
) {
  rlang::check_dots_empty()
  assert_id(id)
  assert_paths(backup_dir, len = 1L)
  assert_flag(.progress)

  subdirs = list_backup_subdirs(backup_dir)
  to_delete = subdirs[as.integer(basename(subdirs)) %in% unique(id)]

  if (.progress) {
    i = 1
    N = length(to_delete)

    cli::cli_progress_step(
      msg = "Delete backup{plur(N, 's')}: {i}/{N}",
      msg_done = "Delete backup{plur(N, 's')}: {N}",
      spinner = TRUE
    )
  }

  for (i in seq_along(to_delete)) {
    fs::dir_delete(to_delete[[i]])
    if (.progress) cli::cli_progress_update()
  }

  return(invisible(to_delete))
}


#' @rdname backups
#' @export
open_backup_dir = function(backup_dir = seekr_option("seekr.backup_dir")) {
  create_backup_dir(backup_dir)
  fs::file_show(backup_dir)
  return(invisible(backup_dir))
}


# Create backup internals -------------------------------------------------

#' @keywords internal
create_backup = function(
  files,
  operation,
  description,
  backup_dir
) {
  if (rlang::is_empty(files)) {
    return(invisible(character()))
  }

  files = normalize_path(files, deduplicate = TRUE)
  subdir = create_backup_subdir(backup_dir)

  tryCatch(
    expr = {
      backup = tibble::tibble(
        created_at = Sys.time(),
        operation = operation,
        description = description,
        original = files,
        backup = create_backup_file_name(files)
      )

      fs::file_copy(
        path = backup$original,
        new_path = file.path(subdir, backup$backup),
        overwrite = FALSE
      )

      saveRDS(backup, file.path(subdir, "backup.RDS"))
    }, error = function(cnd){
      if (fs::dir_exists(subdir)) {
        try(fs::dir_delete(subdir), silent = TRUE)
      }

      stop(cnd)
    }
  )

  return(invisible(subdir))
}


#' @keywords internal
create_backup_subdir = function(backup_dir, call = rlang::caller_env()) {
  create_backup_dir(backup_dir)
  subdirs = list_backup_subdirs(backup_dir)

  if (rlang::is_empty(subdirs)) {
    max_id = 0L
  } else {
    max_id = max(as.integer(basename(subdirs)))
  }

  attempt = 0L

  while (attempt < 10) {
    attempt = attempt + 1L
    id = max_id + attempt

    if (id >= 1e6) {
      cli::cli_abort(
        c(
          "Cannot create a new backup directory.",
          "x" = "Backup directory ids are limited to six digits, from {.val 000001} to {.val 999999}.",
          "i" = "The current backup directory already contains a backup >= {.val 999999}.",
          "i" = "You can remove old backups, change the argument {.arg backup_dir} or change the option {.code seekr.backup_dir}."
        ),
        call = call,
        class = "seekr_error_create_backup_subdir_max_id"
      )
    }

    id_str = pad_id(id, width = 6L)
    subdir = file.path(backup_dir, id_str)

    created = dir.create(subdir, showWarnings = FALSE)

    if (created) {
      return(subdir)
    }

    Sys.sleep(0.1)
  }

  cli::cli_abort(
    c(
      "Cannot create a new backup directory.",
      "x" = "seekr could not find an available backup id after 10 attempts.",
      "i" = "This may happen if several R processes are creating backups at the same time.",
      "i" = "Please try again."
    ),
    call = call,
    class = "seekr_error_create_backup_subdir_concurrency"
  )
}


#' @keywords internal
create_backup_dir = function(backup_dir, call = rlang::caller_env()) {
  tryCatch(
    expr = {
      fs::dir_create(backup_dir, recurse = TRUE)
    }, error = function(e) {
      cli::cli_abort(
        c(
          "Cannot create backup directory.",
          "x" = "seekr could not create {.path {backup_dir}}."
        ),
        call = call,
        class = "seekr_error_create_backup_dir"
      )
    }
  )
}


#' @keywords internal
create_backup_file_name = function(files) {
  width = max(2L, stringr::str_length(length(files)))
  file_name = glue::glue("{pad_id(seq_along(files), width)}_{basename(files)}")
  as.character(file_name)
}


#' @keywords internal
pad_id = function(id, width) {
  stringr::str_pad(id, width = width, side = "left", pad = "0")
}


# List backup internals ---------------------------------------------------

#' @keywords internal
read_backup = function(subdir, call = rlang::caller_env()) {
  id = as.integer(basename(subdir))
  rds_path = file.path(subdir, "backup.RDS")

  if (!fs::file_exists(rds_path)) {
    cli::cli_warn(
      c(
        "Ignoring backup directory {.path {subdir}}.",
        "x" = "Missing metadata file {.file backup.RDS}.",
        "i" = "This directory may be incomplete or was not created by seekr."
      ),
      class = "seekr_warning_missing_backup_metadata"
    )

    return(empty_backup_table())
  }

  df = tryCatch(
    expr = {
      readRDS(rds_path)
    }, error = function(cnd) {
      cli::cli_warn(
        c(
          "Ignoring backup directory {.path {subdir}}.",
          "x" = "Metadata file {.file backup.RDS} could not be read.",
          "i" = "This directory may be incomplete or corrupted."
        ),
        call = call,
        class = "seekr_warning_corrupt_backup_metadata"
      )

      return(NULL)
    }
  )

  if (is.null(df)) {
    return(empty_backup_table())
  }

  if (!inherits(df, "data.frame")) {
    cli::cli_warn(
      c(
        "Ignoring backup directory {.path {subdir}}.",
        "x" = "Metadata file {.file backup.RDS} does not contain a data frame.",
        "i" = "This directory may be incomplete, corrupted, or was not created by seekr."
      ),
      class = "seekr_warning_metadata_not_df"
    )

    return(empty_backup_table())
  }

  required_cols = c(
    "created_at",
    "operation",
    "description",
    "original",
    "backup"
  )

  missing_cols = setdiff(required_cols, names(df))

  if (!rlang::is_empty(missing_cols)) {
    cli::cli_warn(
      c(
        "Ignoring backup directory {.path {subdir}}.",
        "x" = "Metadata file {.file backup.RDS} is missing required column{?s}: {.val {missing_cols}}.",
        "i" = "This directory may be incomplete, corrupted, or was not created by seekr."
      ),
      class = "seekr_warning_metadata_missing_columns"
    )

    return(empty_backup_table())
  }

  invalid_cols = character()

  if (!inherits(df$created_at, "POSIXct")) invalid_cols = c(invalid_cols, "created_at")
  if (!is.character(df$operation)) invalid_cols = c(invalid_cols, "operation")
  if (!is.character(df$description)) invalid_cols = c(invalid_cols, "description")
  if (!is.character(df$original)) invalid_cols = c(invalid_cols, "original")
  if (!is.character(df$backup)) invalid_cols = c(invalid_cols, "backup")

  if (!rlang::is_empty(invalid_cols)) {
    cli::cli_warn(
      c(
        "Ignoring backup directory {.path {subdir}}.",
        "x" = "Metadata file {.file backup.RDS} has {length(invalid_cols)} invalid column type{?s}: {.val {invalid_cols}}.",
        "i" = "This directory may be incomplete, corrupted, or was not created by seekr."
      ),
      class = "seekr_warning_metadata_invalid_columns"
    )

    return(empty_backup_table())
  }

  df$id = id
  df$backup = file.path(subdir, df$backup)
  df$original_exists = fs::file_exists(df$original)
  df$backup_exists = fs::file_exists(df$backup)

  if (any(!df$backup_exists)) {
    n_missing = sum(!df$backup_exists)

    cli::cli_warn(
      c(
        "Some backup files are missing in {.path {subdir}}.",
        "x" = "{n_missing} backup file{?s} referenced in {.file backup.RDS} could not be found.",
        "i" = "These entries will still be listed, but they cannot be restored."
      ),
      class = "seekr_warning_missing_backup_files"
    )
  }

  df = purrr::list_rbind(list(empty_backup_table(), df))

  return(df)
}


#' @keywords internal
list_backup_subdirs = function(backup_dir) {
  if (!fs::dir_exists(backup_dir)) {
    return(character())
  }

  subdirs = fs::dir_ls(backup_dir, type = "directory")
  subdirs = subdirs[stringr::str_detect(basename(subdirs), "^\\d{6}$")]
  sort(subdirs, decreasing = TRUE)
}


#' @keywords internal
empty_backup_table = function() {
  tibble::tibble(
    id = integer(),
    created_at = as.POSIXct(character()),
    operation = character(),
    description = character(),
    original = character(),
    backup = character(),
    original_exists = logical(),
    backup_exists = logical(),
    size = fs::fs_bytes()
  )
}
