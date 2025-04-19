#' @title Read Files and Return Content as Data Frames
#'
#' @description
#' Reads a list of files and returns a list of data frames, one per file, each containing
#' the content of the file by line.
#'
#' @inheritParams base::readLines
#' @param files A character vector of file paths to read.
#'
#' @return A list of data frames, each representing the content of a file. Each data frame includes columns for file index, path, line number, and content.
#'
#' @keywords internal
parse_files_to_dfs = function(files, warn, n) {
  content = mapply(readLines_safe, files, warn, n)
  dfs = mapply(create_file_df, seq_along(files), files, content, SIMPLIFY = FALSE)

  return(dfs)
}


#' @title Safe File Reading
#'
#' @description
#' Reads a file using [base::readLines()] with error handling. If an error occurs
#' (e.g., file unreadable), returns \code{NULL} instead of stopping execution.
#'
#' @inheritParams base::readLines
#'
#' @return A character vector of lines from the file, or \code{NULL} if reading fails.
#'
#' @keywords internal
readLines_safe = function(con, warn, n) {
  tryCatch(
    expr = {
      readLines(con = con, n = n, warn = warn)
    },
    error = function(e) {
      NULL
    }
  )
}


#' @title Convert File Content to Data Frame
#'
#' @description
#' Converts the lines of a single file into a data frame with metadata about file index,
#' line number, and content. Handles empty or unreadable files gracefully.
#'
#' @param file_number An integer. The index of the file in the original file list.
#' @param path A character string. The path to the file.
#' @param file_content A character vector of file lines, or \code{NA_character_}.
#'
#' @returns A tibble with one row per line, containing:
#' \itemize{
#'   \item \code{file}: Integer index of the file in the list.
#'   \item \code{path}: Path to the file.
#'   \item \code{line}: Line number within the file.
#'   \item \code{content}: Content of the matching line.
#' }
#'
#' @keywords internal
create_file_df = function(file_number, path, file_content) {
  if (is.null(file_content) || length(file_content) == 0L) {
    df = tibble::tibble(
      file = file_number,
      path = path,
      line = 0L,
      content = NA_character_
    )
  } else {
    df = tibble::tibble(
      file = file_number,
      path = path,
      line = seq_along(file_content),
      content = file_content
    )
  }

  return(df)
}
