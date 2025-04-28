#' @title Read and Filter Matching Lines in Text Files
#'
#' @description
#' Reads lines from a set of text files and returns only the lines that match a specified
#' regular expression pattern. The function processes each file one-by-one to maintain
#' memory efficiency, making it suitable for reading large files. Files that cannot be
#' read (due to warnings or errors) are skipped with a warning.
#'
#' If verbosity is enabled via `seekr.verbose = TRUE` and the session is interactive,
#' the function reports progress.
#'
#' @inheritParams seek_in
#'
#' @returns A list with two elements:
#' \describe{
#'   \item{`line_number`}{A list of integer vectors giving the line numbers of matching lines, one per file.}
#'   \item{`line`}{A list of character vectors containing the matched lines, one per file.}
#' }
#'
#' @details
#' Files are processed sequentially to minimize memory usage, especially when working with
#' large files. Only the lines matching the `pattern` are retained for each file.
#'
#' If a file raises a warning or an error during reading, it is silently skipped and
#' contributes an empty entry to the result lists.
#'
#' @examples
#' \dontrun{
#' read_filter_lines(c("file1.txt", "file2.csv"), pattern = "^ERROR")
#' }
#'
#' @keywords internal

read_filter_lines = function(files, pattern, ...) {
  N = length(files)
  line_number = vector("list", N)
  line = vector("list", N)
  should_print_cli = print_cli()

  if (should_print_cli) {
    i = 1
    cli::cli_progress_step(
      msg = "Read {cli::qty(N)}file{?s} & filter lines : {i}/{N}",
      msg_done = "Read filter & filter lines",
      spinner = TRUE
    )
  }

  for (i in seq_along(files)) {
    tryCatch(
      expr = {
        tmp = character(0)
        tmp = readr::read_lines(files[[i]], ...)
      }, warning = function(w) {
        if (should_print_cli) {
          cli::cli_alert_warning("Problem reading : {files[[i]]}")
        }
      }, error = function(e) {
        if (should_print_cli) {
          cli::cli_alert_warning("Problem reading : {files[[i]]}")
        }
      }
    )

    line_number[[i]] = which(stringr::str_detect(tmp, pattern))
    line[[i]] = tmp[line_number[[i]]]

    if (should_print_cli && i %% 7 == 0L) {
      cli::cli_progress_update()
    }
  }

  return(list(line_number = line_number, line = line))
}
