#' `r lifecycle::badge("experimental")`
#'
#' @title Extract Matching Lines from Files
#'
#' @description
#' These functions search through one or more text files, extract lines matching
#' a regular expression pattern, and return a tibble containing the results.
#'
#' - `seek()`: Discovers files inside one or more directories (recursively or not),
#' applies optional file name and text file filtering, and searches lines.
#' - `seek_in()`: Searches inside a user-provided character vector of files.
#'
#' @inheritParams fs::dir_ls
#' @inheritParams stringr::str_detect
#' @param path A character vector of one or more directories where files should be
#' discovered (only for `seek()`).
#' @param files A character vector of files to search (only for `seek_in()`).
#' @param pattern A regular expression pattern used to match lines.
#' @param ... Additional arguments passed to [readr::read_lines()], such as
#' `skip`, `n_max`, or `locale`.
#' @param filter Optional. A regular expression pattern used to filter file paths
#' before reading. If `NULL`, all text files are considered.
#' @param relative_path Logical. If TRUE, file paths are made relative to the
#' path argument. If multiple root paths are provided, relative_path is
#' automatically ignored and absolute paths are kept to avoid ambiguity.
#' @param matches Logical. If `TRUE`, all matches per line are also returned in a
#' `matches` list-column.
#'
#' @returns A tibble with one row per matched line, containing:
#' \itemize{
#'   \item \code{path}: File path (relative or absolute).
#'   \item \code{line_number}: Line number in the file.
#'   \item \code{match}: The first matched substring.
#'   \item \code{matches}: All matched substrings (if \code{matches = TRUE}).
#'   \item \code{line}: Full content of the matching line.
#' }
#'
#' @details
#' The overall process involves the following steps:
#'
#' - **File Selection**
#'   - `seek()`: Files are discovered using [fs::dir_ls()], starting from one or more directories.
#'   - `seek_in()`: Files are directly supplied by the user (no discovery phase).
#'
#' - **File Filtering**
#'   - Files located inside `.git/` folders are automatically excluded.
#'   - Files with known non-text extensions (e.g., `.png`, `.exe`, `.rds`) are excluded.
#'   - If a file's extension is unknown, a check is performed to detect embedded null bytes (binary indicator).
#'   - Optionally, an additional regex-based path filter (`filter`) can be applied.
#'
#' - **Line Reading**
#'   - Files are read line-by-line using [readr::read_lines()].
#'   - Only lines matching the provided regular expression `pattern` are retained.
#'   - If a file cannot be read, it is skipped gracefully without failing the process.
#'
#' - **Data Frame Construction**
#'   - A tibble is constructed with one row per matched line.
#'
#' These functions are particularly useful for analyzing source code,
#' configuration files, logs, and other structured text data.
#'
#' @examples
#' \dontrun{
#' # Search all function definitions in R files, recursively
#' seek("[^\\s]+(?= (=|<-) function\\()", filter = "\\.R$", recurse = TRUE)
#'
#' # Search for lines containing "error" in all .log files recursively
#' seek("error", filter = "\\.log$", recurse = TRUE)
#'
#' # Search for specific headers in CSV files that may use different delimiters.
#' files = list.files(pattern = "(?i)\\.csv$", full.names = TRUE, recursive = TRUE)
#' seek_in(
#'   files = files,
#'   pattern = "(?i)^id([,;])date\\1last_name\\1first_name",
#'   n_max = 1
#' )
#'
#' # Search for specific configuration settings inside YAML files
#' seek("^database:", filter = "(?i)\\.ya?ml$", recurse = TRUE
#' )
#'
#' # Search for usage of "TODO" comments inside project source code
#' seek("TODO", path = "src/", filter = "(?i)\\.(R|py|cpp|h)$", recurse = TRUE)
#' }
#'
#' @seealso [fs::dir_ls()], [readr::read_lines()], [stringr::str_detect()]
#'
#' @export
seek = function(
  pattern,
  path = ".",
  ...,
  filter = NULL,
  negate = FALSE,
  recurse = FALSE,
  all = FALSE,
  relative_path = TRUE,
  matches = FALSE
) {
  checkmate::assert_string(pattern)
  checkmate::assert_character(path, min.chars = 1, any.missing = FALSE, min.len = 1)
  purrr::walk(path, checkmate::assert_directory_exists)
  checkmate::assert_string(filter, null.ok = TRUE)
  checkmate::assert_flag(negate)
  assert_flag_or_scalar_integerish(recurse)
  checkmate::assert_flag(all)
  checkmate::assert_flag(relative_path)
  checkmate::assert_flag(matches)

  path = normalizePath(path, winslash = "/")
  files = list_files(path, recurse, all)
  files = filter_files(files, filter, negate)
  df = seek_lines(
    files = files,
    pattern = pattern,
    ...,
    path = path,
    relative_path = relative_path,
    matches = matches
  )

  return(df)
}


#' @rdname seek
#' @export
seek_in = function(
  files,
  pattern,
  ...,
  matches = FALSE
) {
  checkmate::assert_string(pattern)
  checkmate::assert_character(files, min.chars = 1, any.missing = FALSE, min.len = 1)
  checkmate::assert_flag(matches)

  files = normalizePath(files, winslash = "/")
  files = filter_files(files, NULL, FALSE)
  df = seek_lines(
    files = files,
    pattern = pattern,
    ...,
    path = NULL,
    relative_path = FALSE,
    matches = matches
  )

  return(df)
}


#' @title Read and Prepare Matching Lines
#'
#' @description
#' Reads a set of files, filters lines based on a regular expression pattern,
#' and constructs a tidy tibble of the results.
#'
#' @inheritParams seek
#'
#' @returns A tibble with one row per matching line.
#'
#' @keywords internal
seek_lines = function(
  files,
  pattern,
  ...,
  path,
  relative_path,
  matches
) {
  lines = read_filter_lines(files, pattern, ...)
  df = prepare_df(files, pattern, lines, path, relative_path, matches)

  return(df)
}
