#' Print matches with context and replacement preview
#'
#' @description
#' `print()` displays a [`seekr_match`] vector in a readable console format,
#' grouped by source. Each printed match is shown with its source, match index,
#' line number, matched text, and, when available, its planned replacement.
#'
#' The amount of output can be controlled with `n`, which limits the number of
#' matches printed. `context` controls how many surrounding lines are
#' shown.
#'
#' @param x A [`seekr_match`] vector.
#'
#' @param ... Not used. Present for compatibility with the `print()` generic.
#'
#' @param n Maximum number of matches to print. If `NULL`, a compact default is
#'   used: all matches are printed for small vectors, and only the first matches
#'   are printed for larger vectors. Use `Inf` to print all matches.
#'
#' @param context Number of context lines to print around each match. Either:
#'   - A single non-negative integer: print that many lines before and after
#'     each match.
#'   - A pair of non-negative integers `c(before, after)`: print `before`
#'     lines before and `after` lines after each match.
#'
#'   Only context lines captured when the [`seekr_match`] vector was created can
#'   be printed.
#'
#' @return
#' Invisibly returns the original [`seekr_match`] vector `x`.
#'
#' @seealso
#' [summary()][summary.seekr_match()] for a compact summary of matches,
#' [filter_match()] to subset matches before printing, and [seek()] for the
#' `context` argument that controls how many surrounding lines are captured.
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' x <- seekr(
#'   pattern = "(\\w+)(?= <- function)",
#'   replacement = toupper,
#'   path = ext_path
#' )
#'
#' # Print up to 10 matches (default)
#' print(x)
#'
#' # Print all matches
#' print(x, n = Inf)
#'
#' # Print only 3 matches
#' print(x, n = 3L)
#'
#' # Reduce context to 1 line around each match
#' print(x, context = 1L)
#'
#' # Show 3 lines before and 1 line after each match
#' print(x, context = c(3L, 1L))
#'
#' @export
print.seekr_match = function(
  x,
  ...,
  n = NULL,
  context = 0L
) {
  # --- Check args
  rlang::check_dots_empty()
  assert_n_print(n)
  assert_context(context)
  missing_n = missing(n)
  context = normalize_context(context)
  n = compute_n_print(x, n)
  N = length(x)
  width = max(cli::console_width(), 30L)
  original_x = x

  # --- Print vctrs header
  vctrs_header = prepare_vctrs_header_ansi(
    n_matches = N,
    n_files = length(unique(field(x, "path")))
  )

  cli::cat_line(vctrs_header)

  # --- Return early if empty
  if (rlang::is_empty(x) || n == 0L) {
    return(invisible(x))
  }

  # --- Take the subset of elements to print and assert the vector
  x = x[seq_len(n)]
  x_idx = order_within_files(x)

  if (!identical(seq_along(x), x_idx)) {
    cli::cli_alert_info(
      paste(
        "Matches were reordered by file and position for printing.",
        "Use {.fn sort} to order matches globally by file and location,",
        "Use {.fn sort_within_files} to preserve the file order of appearance."
      )
    )

    x = x[x_idx]
  }

  assert_match(x)

  # --- Precompute widths, n_of per file and the match indexes in case matches
  # needed to be sorted.
  widths = compute_printing_widths(x, context, width)
  n_ofs = compute_n_ofs_for_printing(original_x, x)
  xs_idx = split(
    x_idx,
    f = factor(field(x, "path"), levels = unique(field(x, "path")))
  )

  # --- Compute potential common path
  unique_paths = unique(field(original_x, "path"))
  common_path = fs::path_common(fs::path_dir(unique_paths))
  common_path_relevant = stringr::str_length(common_path) > 10
  more_than_one_file = length(unique_paths) > 1
  has_common_path = common_path_relevant && more_than_one_file

  if (has_common_path) {
    cli::cat_line(glue::glue('Common Path: {create_osc8_dir(common_path)}'))
    cli::cat_line()
  }

  # --- Split matches by source and print
  context_to_print = sum(unlist(context)) > 0L
  xs = split_match_by_source(x)

  for (i in seq_along(xs)) {
    if (has_common_path) {
      abs_path = abs_path = field(xs[[i]], "path")[[1L]]
      rel_path = fs::path_rel(abs_path, common_path)
      osc8_file = create_osc8_file(rel_path, abs_path, n_of = n_ofs[[i]])
    } else {
      osc8_file = create_osc8_file(field(xs[[i]], "path")[[1]], n_of = n_ofs[[i]])
    }

    cli::cat_line(osc8_file)

    print_df = compute_print_df_by_source(
      xi = xs[[i]],
      xi_idx = xs_idx[[i]],
      context = context,
      widths = widths
    )

    max_line = NA

    for (j in seq_len(nrow(print_df))) {
      if (context_to_print && print_df$line_type[[j]] != "replacement") {
        if (!is.na(max_line)) {
          distance_to_last_line = print_df$line_number[[j]] - max_line

          if (distance_to_last_line > 1L) {
            cli::cat_line()
          }
        }

        max_line = max(max_line, print_df$line_number[[j]], na.rm = TRUE)
      }

      cli::cat_line(print_df$line[[j]])
    }

    cli::cat_line() # empty rows between files
  }

  # --- print see more match
  if (n < N) {
    msg = glue::glue("# {cli::symbol$info} {N - n} more matches")
    cli::cat_line(ansi_option(msg, "dim"))
    if (missing_n) {
      msg = glue::glue("# {cli::symbol$info} Use `print(n = ...)` to see more matches")
      cli::cat_line(ansi_option(msg, "dim"))
    }
  }

  return(invisible(original_x))
}


#' @keywords internal
compute_print_df_by_source = function(
  xi,
  xi_idx,
  context,
  widths
) {
  context_df = compute_print_context_df(xi, context, widths)
  matchrepl_df = compute_print_matchrepl_df(xi, xi_idx, widths)
  print_df = rbind(context_df, matchrepl_df)

  print_order = order(
    print_df$match_number,
    print_df$line_type,
    print_df$line_number
  )

  print_df = print_df[print_order, ]
  print_df$line = replace_all_tabs_for_printing(print_df$line)
  print_df$line = glue::as_glue(print_df$line)

  return(print_df)
}


#' @keywords internal
compute_print_context_df = function(xi, context, widths) {
  line_type_levels = c("before", "match", "replacement", "after")
  no_context_to_print = identical(sum(unlist(context)), 0L)

  if (no_context_to_print) {
    return(NULL)
  }

  context_df = compute_context_df(xi, context)
  left_part = stringr::str_pad(context_df$line_number, widths$left - 3L, "left")
  left_part = glue::glue('{left_part} | ')
  right_part = truncate_right(context_df$line, width = widths$right)
  context_df$line = glue::glue("{left_part}{right_part}")
  context_df$line = glue::as_glue(ansi_option(context_df$line, "dim"))

  return(context_df)
}


#' @keywords internal
compute_context_df = function(xi, context) {
  line_type_levels = c("before", "match", "replacement", "after")

  df = tibble::as_tibble(xi)

  after_split = split_at_newlines(df$after)
  after = vector("list", length(after_split))

  for (i in seq_along(after)) {
    after_split[[i]] = utils::head(after_split[[i]], context$after)
    after[[i]] = tibble::tibble(
      line_type = factor("after", levels = line_type_levels),
      match_number = i,
      line_number = df$end_line[[i]] + seq_along(after_split[[i]]),
      line = after_split[[i]]
    )

    has_next_match = i < length(after)
    if (has_next_match) {
      next_match_start_line = df$start_line[[i + 1]]
      after[[i]] = after[[i]][after[[i]]$line_number < next_match_start_line, ]
    }
  }

  before_split = split_at_newlines(df$before)
  before = vector("list", length(before_split))

  for (i in seq_along(before)) {
    before_split[[i]] = utils::tail(before_split[[i]], context$before)
    before[[i]] = tibble::tibble(
      line_type = factor("before", levels = line_type_levels),
      match_number = i,
      line_number = df$start_line[[i]] - rev(seq_along(before_split[[i]])),
      line = before_split[[i]]
    )

    first_match = i == 1L
    if (!first_match) {
      previous_match_end_line = df$end_line[[i - 1]]
      previous_after_end_line = utils::tail(after[[i - 1]]$line_number, n = 1L)
      previous_end_line = max(previous_match_end_line, previous_after_end_line)
      before[[i]] = before[[i]][before[[i]]$line_number > previous_end_line, ]
    }
  }

  do.call(rbind, c(before, after))
}


#' @keywords internal
compute_print_matchrepl_df = function(xi, xi_idx, widths) {
  df = tibble::as_tibble(xi)

  # --- Correct for match finishing with a newline
  ends_with_nl_pattern = "(\\r\\n|\\n|\\r)$"
  match_ends_with_nl = stringr::str_detect(df$match, ends_with_nl_pattern)
  replacement_ends_with_nl = stringr::str_detect(df$replacement, ends_with_nl_pattern)

  df$replacement = ifelse(
    match_ends_with_nl & !replacement_ends_with_nl,
    paste0(df$replacement, "-", seekr_option("seekr.print.newline")),
    df$replacement
  )

  df$match = stringr::str_remove(df$match, ends_with_nl_pattern)

  # --- Create a df per match
  dfs_match = compute_print_dfs_match_or_replacement(
    df = df,
    xi_idx = xi_idx,
    line_type = "match",
    widths = widths
  )

  # --- Create a df per replacement
  dfs_repl = compute_print_dfs_match_or_replacement(
    df = df,
    xi_idx = xi_idx,
    line_type = "replacement",
    widths = widths
  )

  # --- Merge the dfs of matches and replacements
  matchrepl_df = do.call(rbind, c(dfs_match, dfs_repl))
  matchrepl_df$right = purrr::map_chr(
    matchrepl_df$right,
    \(x) truncate_right_ansi(x, widths$right)
  )
  matchrepl_df$line = glue::glue("{matchrepl_df$left}{matchrepl_df$right}")
  matchrepl_df = matchrepl_df[, c("line_type", "match_number", "line_number", "line")]

  return(matchrepl_df)
}


#' @keywords internal
compute_print_dfs_match_or_replacement = function(
  df,
  xi_idx,
  line_type,
  widths
) {
  line_type_levels = c("before", "match", "replacement", "after")
  sep = ansi_option("|", "dim")
  has_replacement = !is.na(df$replacement)
  line_number = stringr::str_pad(df$start_line, widths$line_number, "left")
  line = df$line

  # --- Compute first left part element
  if (line_type == "match") {
    idx = glue::glue("[{xi_idx}]")
    idx = create_osc8_match(idx, df$path, df$start_line, df$start_col)
    idx_pad = stringr::str_dup(" ", widths$idx - cli::ansi_nchar(idx))
    idx = glue::glue("{idx_pad}{idx}")
    symbol = ifelse(has_replacement, "--", "->")
    first_left = glue::glue("{idx} {symbol} {line_number} {sep} ")
    style = ifelse(!has_replacement, "match_only", "match")
  } else if (line_type == "replacement") {
    symbol = ifelse(has_replacement, "++", NA_character_)
    first_left = glue::glue("{symbol} {line_number} {sep} ")
    first_left_pad = stringr::str_dup(" ", widths$left - cli::ansi_nchar(first_left))
    first_left = glue::glue("{first_left_pad}{first_left}")
    style = rep("replacement", nrow(df))
  }

  # --- Color the match/replacement and replace it in line
  if (line_type == "match") {
    colored = purrr::map2_chr(
      df$match,
      style,
      \(match, style) ansi_option(match, style)
    )
  } else if (line_type == "replacement") {
    colored = ansi_option(df$replacement, "replacement")
  }

  for (i in seq_along(line)) {
    stringr::str_sub(
      line[[i]],
      df$start_col[[i]],
      df$start_col[[i]] + (df$end[[i]] - df$start[[i]])
    ) = colored[[i]]
  }

  # --- Use `line` to create a unique df of lines to print for each match/replacement
  dfs = vector("list", nrow(df))
  split = split_at_newlines(line)

  for (i in seq_along(dfs)) {
    if (is.na(line[[i]])) {
      next
    }

    line_number = df$start_line[[i]] + seq_along(split[[i]]) - 1L
    left = stringr::str_pad(line_number, width = widths$left - 3, "left")
    left = glue::glue("{left} {sep} ")
    left[[1]] = first_left[[i]]

    tmp = tibble::tibble(
      line_type = factor(line_type, levels = line_type_levels),
      match_number = i,
      line_number = line_number,
      left = left,
      right = split[[i]]
    )

    n_lines = nrow(tmp)
    singleline = n_lines == 1L
    multiline = n_lines > 1L

    if (singleline) {
      if (line_type == "match") {
        end_col = df$end_col[[i]]
        len = cli::ansi_nchar(df$match[[i]])
      } else if (line_type == "replacement") {
        end_col = df$start_col[[i]] + cli::ansi_nchar(df$replacement[[i]]) - 1L
        len = cli::ansi_nchar(df$replacement[[i]])
      }

      match_or_replacement_fit = end_col <= widths$right
      if (!match_or_replacement_fit) {
        if (len < widths$right) {
          center = floor((df$start_col[[i]] + end_col) / 2L)
        } else {
          center = df$start_col[[i]]
        }

        tmp$right = center_match_or_replacement_line(
          line = tmp$right,
          width = widths$right,
          center = center
        )
      }
    }

    if (multiline) {
      if (line_type == "match") {
        end_col = df$end_col[[i]]
      } else if (line_type == "replacement") {
        last_line_replacement = stringr::str_extract(df$replacement[[i]], ".*$")
        end_col = cli::ansi_nchar(last_line_replacement)
      }

      style_code = seekr_option(glue::glue("seekr.style.{style[[i]]}"))

      for (j in seq_len(n_lines)) {
        first_line = j == 1L
        middle_line = j > 1 && j < n_lines
        last_line = j == n_lines

        if (first_line) {
          tmp$right[[j]] = glue::glue("{tmp$right[[j]]}\033[0m") # first line, close ansi
          match_or_replacement_start_fit = df$start_col[[i]] <= widths$right
          if (!match_or_replacement_start_fit) {
            tmp$right[[j]] = center_match_or_replacement_line(
              line = tmp$right[[j]],
              width = widths$right,
              center = df$start_col[[i]]
            )
          }
        } else if (middle_line) {
          tmp$right[[j]] = glue::glue("\033[{style_code}m{tmp$right[[j]]}\033[0m") # middle line, open & close ansi
        } else if (last_line) {
          tmp$right[[j]] = glue::glue("\033[{style_code}m{tmp$right[[j]]}") # last line, open ansi
          match_or_replacement_end_fit = end_col <= widths$right
          if (!match_or_replacement_end_fit) {
            tmp$right[[j]] = center_match_or_replacement_line(
              line = tmp$right[[j]],
              width = widths$right,
              center = end_col
            )
          }
        }
      }
    }

    dfs[[i]] = tmp
  }

  return(dfs)
}


#' @keywords internal
center_match_or_replacement_line = function(line, width, center) {
  line_len = cli::ansi_nchar(line)
  half_width = floor(width / 2L)

  to = min(center + half_width, line_len)
  used_center = 1L
  used_right_of_center = to - center
  remaining_left_of_center = width - used_center - used_right_of_center
  from = center - remaining_left_of_center

  if (from > 1) {
    from = from + 1L
  }

  line = cli::ansi_substr(line, start = from, stop = line_len)

  if (from > 1L) {
    sgr_start_pattern = "^(\033\\[[0-9;]*m)*"
    line = stringr::str_replace(line, sgr_start_pattern, "\\1\u2026")
  }

  return(line)
}


#' @keywords internal
compute_printing_widths = function(x, context, width) {
  if (context$after == 0L) {
      max_line_number = max(field(x, "end_line"))
  } else {
    context_after_length_lines = purrr::map_int(field(x, "after"), \(x) length(split_at_newlines(x)[[1]]))
    context_after_length_lines = pmin(context$after, context_after_length_lines)
    last_line_number_per_match = field(x, "end_line") + context_after_length_lines
    max_line_number = max(last_line_number_per_match)
  }

  idx_width = stringr::str_length(length(x)) + 2 # "[idx]"
  line_number_width = stringr::str_length(max_line_number)
  # format is : <[14] -> 172 | >
  #              12345678901234
  left_width =
    idx_width +
    1 + # space
    2 + # symbol, either: -> / -- / ++
    1 + # space
    line_number_width +
    1 + # space
    1 + # separator |
    1 # space

  widths = list(
    idx = idx_width,
    line_number = line_number_width,
    left = left_width,
    right = width - left_width
  )

  return(widths)
}


#' @keywords internal
split_at_newlines = function(x) {
  s = stringr::str_split(x, "\\r\\n|\\n|\\r")
  s = purrr::modify_if(s, \(x) is.na(x[[1]]), \(x) character())

  return(s)
}


#' @keywords internal
compute_n_ofs_for_printing = function(original_x, x) {
  path_order = unique(field(x, "path"))

  n_subset = table(factor(field(x, "path"), levels = path_order))
  n_original = table(factor(field(original_x, "path"), levels = path_order))

  n_ofs = ifelse(
    n_subset < n_original,
    glue::glue("[{n_subset}/{n_original}]"),
    glue::glue("[{n_subset}]")
  )

  return(n_ofs)
}
