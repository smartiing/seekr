#' @title Filter Lines Matching a Pattern
#'
#' @description
#' Filters the rows of a data frame to keep only those where the line content
#' matches a given regular expression.
#'
#' @param df A data frame created by [create_file_df()].
#' @param pattern A Perl-compatible regular expression used to filter the lines.
#'
#' @return A data frame containing only the rows where \code{content} matches the pattern.
#'
#' @details
#' The function re-encodes all content lines to UTF-8 and removes any lines
#' that do not match the pattern. Encoding issues are replaced with byte representations.
#'
#' @keywords internal
filter_matching_lines = function(df, pattern) {
  df$content = iconv(df$content, from = "", to = "UTF-8", sub = "byte")
  df = df[grepl(pattern, df$content, perl = TRUE), ]

  return(df)
}


#' @title Add Match Columns to a Data Frame
#'
#' @description
#' Adds two new columns to a data frame of lines: one with all matches found
#' in each line, and one with the first match only.
#'
#' @param df A data frame created by [create_file_df()].
#' @param pattern A Perl-compatible regular expression used to extract matches from each line.
#'
#' @return A data frame with two added columns:
#' \itemize{
#'   \item \code{matches}: A list-column with all matches per line.
#'   \item \code{match}: A character vector with the first match for each line.
#' }
#'
#' @details
#' Matching is performed with [gregexpr()], and matches are extracted using [regmatches()].
#' If a line has multiple matches, only the first is stored in \code{match}.
#'
#' @keywords internal
add_matches_columns = function(df, pattern) {
  df$matches = regmatches(df$content, gregexpr(pattern, df$content, perl = TRUE))
  df$match = unlist(lapply(df$matches, \(x) x[[1]]))

  return(df)
}
