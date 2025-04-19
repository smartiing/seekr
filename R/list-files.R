#' @title List All Files in a Directory
#'
#' @description
#' Lists all files in a specified directory using [base::list.files()], with options
#' to include subdirectories and hidden files. If no files are found, provides
#' informative error messages.
#'
#' @inheritParams base::list.files
#'
#' @return A character vector of normalized file paths.
#'
#' @keywords internal
list_files = function(path, recursive, all.files) {
  files = list.files(
    path = path,
    pattern = NULL,
    all.files = all.files,
    full.names = TRUE,
    recursive = recursive,
    ignore.case = FALSE,
    include.dirs = FALSE,
    no.. = FALSE
  )

  if (length(files) == 0L) {
    if (recursive & all.files) {
      cli::cli_abort(c(
        "!" = "No files found in {.path {path}}.",
        "i" = "Check the folder path."
      ))
    } else {
      cli::cli_abort(c(
        "!" = "No files found in {.path {path}}.",
        "i" = "Check the folder path.",
        "i" = "Set {.code recursive = TRUE} if you want to find files recursively.",
        "i" = "Set {.code all.files = TRUE} if you want to match hidden files."
      ))

    }

  }

  return(normalizePath(files, winslash = "/"))
}


#' @title Filter Files by Name Pattern
#'
#' @description
#' Filters a character vector of file paths using a Perl-compatible regular expression.
#' If no files match, an informative error message is displayed.
#'
#' @param files A character vector of file paths to filter.
#' @param filter A Perl-compatible regular expression applied to the file paths.
#'
#' @return A character vector of file paths that match the pattern.
#'
#' @keywords internal
filter_matching_files = function(files, filter) {
  files = files[grepl(filter, files, perl = TRUE)]

  if (length(files) == 0L) {
    cli::cli_abort(c(
      "!" = "No files matched the pattern {.val {filter}}.",
      "i" = "Try a different {.code filter} or check that the files exist."
    ))
  }

  return(files)
}
