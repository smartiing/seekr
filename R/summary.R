#' Summarize matches and planned replacements
#'
#' @description
#' `summary()` produces a compact overview of a [`seekr_match`] vector:
#' the most frequent files, matched texts, file extensions, and encodings.
#'
#' When replacements are planned, matched texts are displayed together with their
#' replacement preview, giving a high-level picture of what [replace_files()]
#' would change.
#'
#' @param object A [`seekr_match`] vector.
#' @param ... Not used. Present for compatibility with the `summary()` generic.
#'
#' @return
#' An object of class `summary_seekr_match`, containing summary tables for
#' files, matches/replacements, extensions, and encodings. Print it with
#' `print()` to display a formatted summary in the console.
#'
#' @seealso
#' - [print.seekr_match()] for a full match-level display with context lines.
#' - [str.seekr_match()] for the internal field structure.
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' x <- seekr("TODO", path = ext_path)
#' y <- seekr("TODO", "DONE", path = ext_path)
#' summary(x)
#' summary(y)
#' summary(c(x, y))
#'
#' @export
summary.seekr_match = function(object, ...) {
  rlang::check_dots_empty()

  if (rlang::is_empty(object)) {
    summary_seekr_match = structure(
      list(
        path = tibble::tibble(path = character(), n = integer(), share = numeric()),
        match = tibble::tibble(match = character(), replacement = character(), n = integer(), share = numeric()),
        extension = tibble::tibble(extension = character(), n = integer(), share = numeric()),
        encoding = tibble::tibble(encoding = character(), n = integer(), share = numeric())
      ),
      class = "summary_seekr_match"
    )

    return(summary_seekr_match)
  }

  xdf = tibble::as_tibble(object)
  xdf$extension = extract_lower_file_extension(xdf$path)

  summary_seekr_match = structure(
    list(
      path = prepare_summary_df(xdf, c("path")),
      match = prepare_summary_df(xdf, c("match", "replacement")),
      extension = prepare_summary_df(xdf, "extension"),
      encoding = prepare_summary_df(xdf, "encoding")
    ),
    class = "summary_seekr_match"
  )

  return(summary_seekr_match)
}


#' @rdname summary.seekr_match
#' @param x A `summary_seekr_match` object, as returned by [summary.seekr_match()].
#' @param n Maximum number of rows to print in each summary table. If `NULL`, a
#'   compact default is used. This limit is applied separately to each section of
#'   the summary, such as top files, top matches/replacements, top extensions,
#'   and top encodings.
#' @export
print.summary_seekr_match = function(x, ..., n = NULL) {
  rlang::check_dots_empty()
  assert_n_print(n)

  vctrs_header = prepare_vctrs_header_ansi(n_matches = sum(x$path$n))
  cli::cli_rule(vctrs_header)

  if (nrow(x$path) == 0L) {
    return(invisible(x))
  }

  width_for_path = compute_summary_available_width(x$path)
  unique_paths = unique(x$path$path)
  common_path = fs::path_common(fs::path_dir(unique_paths))
  common_path_relevant = stringr::str_length(common_path) > 10
  more_than_one_file = length(unique_paths) > 1
  has_common_path = common_path_relevant && more_than_one_file
  df_path = x$path

  if (has_common_path) {
    cli::cat_line(glue::glue('Common Path: {create_osc8_dir(common_path)}'))
    cli::cat_line()

    df_path$path = create_osc8_file(
      display_path = truncate_left(fs::path_rel(df_path$path, common_path), width_for_path),
      absolute_path = df_path$path
    )
  } else {
    df_path$path = create_osc8_file(truncate_left(df_path$path, width_for_path))
  }

  width_for_match = compute_summary_available_width(x$match)
  df_match = x$match
  df_match$match = escape_newlines(replace_all_tabs_for_printing(df_match$match))
  df_match$replacement = escape_newlines(replace_all_tabs_for_printing(df_match$replacement))
  df_match$match_replacement = prepare_summary_match_replacement(
    match = df_match$match,
    replacement = df_match$replacement,
    width = width_for_match
  )

  df_match = df_match[c("match_replacement", "n", "share")]
  n_of = purrr::map_chr(x, \(df) prepare_summary_n_of(df, n))

  cli::cat_line(glue::glue("Top source{plur(nrow(x$path), 's')} {n_of[['path']]}"))
  cli::cat_line(prepare_summary_df_lines(df_path, n))
  cli::cat_line()

  if (all(is.na(x$match$replacement))) {
    cli::cat_line(glue::glue("Top match{plur(nrow(x$match), 'es')} {n_of[['match']]}"))
  } else {
    cli::cat_line(glue::glue("Top match{plur(nrow(x$match), 'es')}/replacement{plur(nrow(x$match), 's')} {n_of[['match']]}"))
  }

  cli::cat_line(prepare_summary_df_lines(df_match, n))
  cli::cat_line()
  cli::cat_line(glue::glue("Top extension{plur(nrow(x$extension), 's')} {n_of[['extension']]}"))
  cli::cat_line(prepare_summary_df_lines(x$extension, n))
  cli::cat_line()
  cli::cat_line(glue::glue("Top encoding{plur(nrow(x$encoding), 's')} {n_of[['encoding']]}"))
  cli::cat_line(prepare_summary_df_lines(x$encoding, n))
  cli::cat_line()

  return(invisible(x))
}


#' @keywords internal
compute_summary_available_width = function(df) {
# Format:
# - tests/testthat/test-seekr-match.R : 89 (25.4%)
# - tests/testthat/test-cli.R         : 15 ( 4.3%)
# - <foo/bar> : 351 (100.0%)
  width = max(30L, cli::console_width())
  len_start = 3L
  len_before_n = 3L
  len_n = stringr::str_length(df$n[[1]])
  len_share = stringr::str_length(as.integer(df$share[[1]] * 100))
  len_share_additional = 5L

  available_width =
    width -
    len_start -
    len_before_n -
    len_n -
    len_share -
    len_share_additional

  if (names(df)[[1]] == "match") {
    available_width = available_width - 3L # </>
  }

  return(available_width)
}


#' @keywords internal
prepare_summary_df = function(xdf, cols) {
  df = as.data.frame(table(xdf[cols], useNA = "always"), stringsAsFactors = FALSE)
  df = tibble::as_tibble(df)
  colnames(df) = c(cols, "n")
  df = df[df$n > 0, ]
  df = df[order(df$n, decreasing = TRUE), ]
  df$share = df$n / sum(df$n)

  return(df)
}


#' @keywords internal
prepare_summary_df_lines = function(df, n) {
  n = compute_n_print(df, n)

  if (n == 0L) {
    return(glue::glue())
  }

  df = df[seq_len(n), ]
  df[[1]] = ifelse(
    is.na(df[[1]]),
    ansi_option("NA", "na"),
    df[[1]]
  )

  max_label_width = max(cli::ansi_nchar(df[[1]]))
  label_padding = purrr::map_chr(
    max_label_width - cli::ansi_nchar(df[[1]]) + 1,
    \(padding_width) stringr::str_c(rep(" ", padding_width), collapse = "")
  )

  df[[1]] = stringr::str_c(df[[1]], label_padding)
  df[[2]] = format(df[[2]])
  df[[3]] = glue::glue("({format(round(100 * df[[3]], 1), nsmall = 1)}%)")
  df[[3]] = ansi_option(df[[3]], "dim")

  glue::glue(" \u2022 {df[[1]]}: {df[[2]]} {df[[3]]}")
}


#' @keywords internal
prepare_summary_n_of = function(df, n) {
  N = nrow(df)
  n = compute_n_print(df, n)

  if (n == N) {
    return(ansi_option(glue::glue("[{n}]"), "dim"))
  } else {
    return(ansi_option(glue::glue("[{n}/{N}]"), "dim"))
  }
}


#' @keywords internal
prepare_summary_match_replacement = function(match, replacement, width = NULL) {
  lc = "<"
  rc = ">"

  has_replacement = !is.na(replacement)
  sep = ifelse(has_replacement, "/", "")
  replacement[!has_replacement] = ""

  if (!is.null(width) && width >= 10) {
    width_for_mr = width - 3L
    len_m = stringr::str_length(match)
    len_r = stringr::str_length(replacement)
    len_mr = len_m + len_r
    len_missing = len_mr > width_for_mr

    for (i in seq_along(match)) {
      if (!len_missing[[i]]) {
        next
      }

      match[[i]] = truncate_right(match[[i]], width_for_mr - min(len_r[[i]], 3L))
      remaining_width = width_for_mr - stringr::str_length(match[[i]])
      replacement[[i]] = truncate_right(replacement[[i]], remaining_width)
    }
  }

  lc = ansi_option(lc, "dim")
  rc = ansi_option(rc, "dim")
  sep = ansi_option(sep, "dim")

  match = ifelse(
    has_replacement,
    ansi_option(match, "match"),
    ansi_option(match, "match_only")
  )

  replacement = ansi_option(replacement, "replacement")

  glue::glue("{lc}{match}{sep}{replacement}{rc}")
}
