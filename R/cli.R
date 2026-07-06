#' @keywords internal
prepare_vctrs_header_ansi = function(n_matches, n_files = NULL, print_vctrs = FALSE) {
  files_part = ""
  if (!is.null(n_files)) {
    files_part = ansi_option(glue::glue(" {n_files} source{plur(n_files, 's')}"), "dim")
  }

  vctrs_part = ""
  if (print_vctrs) {
    vctrs_part = ansi_option(" vctrs::rcrd", "class")
  }

  glue::glue('<seekr::match[{n_matches}]>{files_part}{vctrs_part}')
}


#' @keywords internal
create_osc8_file = function(display_path, absolute_path = display_path, n_of = NULL) {
  print_mode = seekr_option("seekr.print.mode")

  if (print_mode == "plain") {
    x = display_path
  } else if (print_mode == "color") {
    x = ansi_option(display_path, "osc8_file")
  } else if (print_mode == "rich") {
    x = ifelse(
      !fs::file_exists(absolute_path),
      ansi_option(display_path, "osc8_file"),
      glue::glue('\033]8;;file://{absolute_path}\a{ansi_option(display_path, "osc8_file")}\033]8;;\a')
    )
  }

  if (!is.null(n_of)) {
    x = glue::glue('{x} {ansi_option(n_of, "dim")}')
  }

  return(x)
}


#' @keywords internal
create_osc8_dir = function(display_path, absolute_path = display_path) {
  print_mode = seekr_option("seekr.print.mode")

  switch(
    print_mode,
    "plain" = display_path,
    "color" = ansi_option(display_path, "osc8_dir"),
    "rich" = glue::glue('\033]8;;ide:run:fs::file_show("{absolute_path}")\a{ansi_option(display_path, "osc8_dir")}\033]8;;\a')
  )
}


#' @keywords internal
create_osc8_match = function(string, absolute_path, start_line, start_col) {
  print_mode = seekr_option("seekr.print.mode")

  if (print_mode != "rich") {
    return(string)
  }

  ifelse(
    !fs::file_exists(absolute_path),
    string,
    glue::glue('\033]8;line = {start_line}:col = {start_col};file://{absolute_path}\a{string}\033]8;;\a')
  )
}


#' @keywords internal
escape_newlines = function(x) {
  replacement_pairs = c(
    "\\r\\n" = "\\\\r\\\\n",
    "\\r" = "\\\\r",
    "\\n" = "\\\\n"
  )

  stringr::str_replace_all(x, replacement_pairs)
}


#' @keywords internal
truncate_left = function(x, width) {
  stringr::str_trunc(x, width, "left", "\u2026")
}


#' @keywords internal
truncate_center = function(x, width) {
  stringr::str_trunc(x, width, "center", "\u2026")
}


#' @keywords internal
truncate_right = function(x, width) {
  stringr::str_trunc(x, width, "right", "\u2026")
}


#' @keywords internal
truncate_right_ansi = function(x, width) {
  len = cli::ansi_nchar(x)

  if (len <= width) {
    return(x)
  }

  s = cli::ansi_substr(x, 1, width - 1L)

  sgr_end_pattern = "(\033\\[[0-9;]*m)*$"
  s = stringr::str_replace(s, sgr_end_pattern, "\u2026\\1")

  return(s)
}


#' @keywords internal
replace_all_tabs_for_printing = function(x) {
  stringr::str_replace_all(x, "\t", seekr_option("seekr.print.tab"))
}


#' @keywords internal
plur = function(x, plural) {
  if (length(x) != 1L) {
    return(plural)
  }

  if (is.numeric(x) && !is.na(x) && x != 1) {
    return(plural)
  }

  ""
}


#' @keywords internal
compute_n_print = function(x, n) {
  assert_n_print(n)

  default = 10L
  threshold = 20L

  if (is.data.frame(x)) {
    N = nrow(x)
  } else {
    N = length(x)
  }

  if (is.null(n)) {
    if (N > threshold) {
      return(default)
    }

    return(N)
  }

  min(n, N)
}
