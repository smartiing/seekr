#' @title Prepare Tidy Data Frame from Matched Lines
#'
#' @description
#' Constructs a tidy data frame from matched lines across a set of files.
#' This function takes the output of [read_filter_lines()] and returns one row per match,
#' including file path, line number, full line content, and regex match(es).
#'
#' @inheritParams seek
#' @param lines A list with `line_number` and `line`, as returned by [read_filter_lines()].
#'
#' @returns A tibble with the following columns:
#' \itemize{
#'   \item \code{path}: File path (relative if specified), marked with class `fs_path`.
#'   \item \code{line_number}: Line number of the match within the file.
#'   \item \code{match}: The first matched substring from the line.
#'   \item \code{matches} (optional): All matched substrings as a list-column.
#'   \item \code{line}: Full content of the matching line.
#' }
#'
#' @details
#' All steps are executed sequentially to transform file-based pattern matches into a structured tabular format.
#' The function assumes that input files and their corresponding line data are correctly aligned.
#' It handles path normalization, match extraction, and output column selection according to the `matches` and `relative_path` arguments.
#'
#' @keywords internal
prepare_df = function(files, pattern, lines, path, relative_path, matches) {
  if (print_cli()) cli::cli_progress_step("Prepare dataframe")
  df = tibble::tibble(
    path = files,
    line_number = lines$line_number,
    line = lines$line
  )

  df = tidyr::unnest_longer(df, col = c("line_number", "line"))
  df$matches = stringr::str_extract_all(df$line, pattern)
  df$match = purrr::map_chr(df$matches, function(x) x[[1]])

  if (!is.null(path) && length(path) == 1L && relative_path) {
    df$path = stringr::str_remove(df$path, path)
  }

  df$path = structure(df$path, class = "fs_path")

  if (matches) {
    df = df[, c("path", "line_number", "match", "matches", "line")]
  } else {
    df = df[, c("path", "line_number", "match", "line")]
  }

  return(df)
}
