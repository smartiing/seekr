#' @title Extract Matching Lines from Matching Files
#'
#' @description
#' Searches for lines matching a regular expression pattern in a set of files.
#' In `seek()`, the files are discovered within a directory (recursively or not),
#' and optionally filtered using a path pattern. In `seek_in()`, the files
#' are provided directly by the user.
#'
#' @inheritParams base::list.files
#' @inheritParams base::readLines
#' @param pattern A string. A Perl-compatible regular expression used to filter
#'  the lines of the files.
#' @param filter Optional. A Perl-compatible regular expression used to filter
#'  file names before reading them. If \code{NULL}, all files are considered.
#' @param relative_path Logical. If \code{TRUE}, returned paths are made relative to
#'  the \code{path} argument. Only applies to \code{seek()}.
#' @param files A character vector of file paths to be used directly, instead of searching
#'  a directory. Only used in \code{seek_in()}.
#'
#' @returns A tibble with one row per matching line, containing:
#' \itemize{
#'   \item \code{file}: Integer index of the file in the list.
#'   \item \code{path}: Path to the file.
#'   \item \code{line}: Line number within the file.
#'   \item \code{match}: The first matched substring.
#'   \item \code{matches}: All matched substrings.
#'   \item \code{content}: Content of the matching line.
#' }
#'
#' @details
#' These functions combine file listing (or direct input), filtering, reading,
#' and pattern extraction into a single interface. They are especially useful
#' for searching through codebases, configuration files, or logs.
#'
#' The search is case-sensitive and uses Perl-compatible regular expressions (PCRE).
#'
#' @family seek
#'
#' @examples
#' \dontrun{
#' # Find all function definitions in R files under current directory
#' seek("[^\\s]+(?= = function\\()", filter = "\\.R$", recursive = TRUE)
#'
#' # Find all package loaded using `library() in a predefined list of files
#' files = list.files(pattern = "\\.R$", recursive = TRUE)
#' seek_in("(?<=library\\()[^\\)]+", files)
#' }
#'
#' @export
seek = function(
  pattern,
  path = ".",
  filter = NULL,
  recursive = FALSE,
  all.files = FALSE,
  n = -1L,
  warn = FALSE,
  relative_path = TRUE
) {
  checkmate::assert_string(pattern)
  checkmate::assert_directory_exists(path)
  checkmate::assert_string(filter, null.ok = TRUE)
  checkmate::assert_flag(recursive)
  checkmate::assert_flag(all.files)
  checkmate::assert_integerish(n)
  checkmate::assert_flag(warn)
  checkmate::assert_flag(relative_path)

  path = normalizePath(path, winslash = "/")
  files = list_files(path, recursive, all.files)

  if (!is.null(filter)) {
    files = filter_matching_files(files, filter)
  }

  df = process_files_lines(files, pattern, warn, n, relative_path)

  if (relative_path) {
    df$path = sub(path, "", df$path)
  }

  return(df)
}


#' @export
#' @rdname seek
seek_in = function(
  pattern,
  files,
  n = -1L,
  warn = FALSE
) {
  checkmate::assert_string(pattern)
  checkmate::assert_character(files, any.missing = FALSE, min.len = 1)
  checkmate::assert_integerish(n)
  checkmate::assert_flag(warn)

  df = process_files_lines(files, pattern, warn, n, FALSE)

  return(df)
}

#' @keywords internal
#' @rdname seek
process_files_lines = function(files, pattern, warn, n, relative_path) {
  dfs = parse_files_to_dfs(files, warn, n)
  df = tibble::as_tibble(Reduce(rbind, dfs))
  df = filter_matching_lines(df, pattern)
  df = add_matches_columns(df, pattern)

  df = df[, c("file", "path", "line", "match", "matches", "content")]

  return(df)
}
