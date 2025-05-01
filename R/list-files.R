#' @title List Files in Directory
#'
#' @description
#' Lists all files from a given directory with support for recursive search and inclusion of hidden files.
#' The function throws a specific error when no files are found, based on the combination of
#' `recurse` and `all` parameters. Returned file paths are made unique and are assumed to be
#' normalized using forward slashes (`/`).
#'
#' @inheritParams fs::dir_ls
#'
#' @returns
#' A character vector of unique file paths. If no files are found, the function aborts with a
#' message suggesting how to adjust search parameters (`recurse` and `all`), and includes a
#' class-specific error identifier depending on the search mode:
#' \itemize{
#'   \item `"error_list_files_TT"` for `recurse = TRUE`, `all = TRUE`
#'   \item `"error_list_files_TF"` for `recurse = TRUE`, `all = FALSE`
#'   \item `"error_list_files_FT"` for `recurse = FALSE`, `all = TRUE`
#'   \item `"error_list_files_FF"` for `recurse = FALSE`, `all = FALSE`
#' }
#'
#' @examples
#' \dontrun{
#' list_files("myfolder", recurse = TRUE, all = FALSE)
#' }
#'
#' @keywords internal
#'
#' @export
list_files = function(path, recurse, all) {
  if (print_cli()) cli::cli_progress_step("List files")
  files = fs::dir_ls(
    path = path,
    all = all,
    recurse = recurse,
    type = "file",
    glob = NULL,
    regexp = NULL,
    invert = FALSE,
    fail = TRUE
  )

  files = unique(files)

  if (length(files) == 0L) {
    if (recurse & all) {
      cli::cli_abort(
        c(
          "!" = "No files found in {.path {path}}.",
          "i" = "Check the folder path."
        ),
        class = "error_list_files_TT"
      )
    } else if (recurse & !all) {
      cli::cli_abort(
        c(
          "!" = "No files found in {.path {path}}.",
          "i" = "Check the folder path.",
          "i" = "Set {.code all = TRUE} if you want to match hidden files."
        ),
        class = "error_list_files_TF"
      )
    } else if (!recurse & all) {
      cli::cli_abort(
        c(
          "!" = "No files found in {.path {path}}.",
          "i" = "Check the folder path.",
          "i" = "Set {.code recurse = TRUE} if you want to find files recursively."
        ),
        class = "error_list_files_FT"
      )
    } else if (!recurse & !all) {
      cli::cli_abort(
        c(
          "!" = "No files found in {.path {path}}.",
          "i" = "Check the folder path.",
          "i" = "Set {.code recurse = TRUE} if you want to find files recursively.",
          "i" = "Set {.code all = TRUE} if you want to match hidden files."
        ),
        class = "error_list_files_FF"
      )
    }
  }

  return(structure(files, class = "fs_path"))
}
