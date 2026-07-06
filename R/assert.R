# Helpers -----------------------------------------------------------------

#' @keywords internal
assert_vector = function(
  x,
  classes = NULL,
  len = NULL,
  len_min = 0,
  len_max = Inf,
  na_ok = FALSE,
  null_ok = FALSE,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is.null(x)) {
    if (!null_ok) {
      cli::cli_abort(
        "{.arg {arg}} must not be {.val NULL}.",
        class = "seekr_error_null",
        call = call
      )
    } else {
      return(x)
    }
  }

  if (!is.null(classes) && !rlang::inherits_any(x, classes)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must inherit from {.cls {classes}}.",
        "x" = "You supplied an object of class {.cls {class(x)}}"
      ),
      class = "seekr_error_class",
      call = call
    )
  }

  len_x = length(x)
  if (!is.null(len) && len_x != len) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must contain exactly {.val {len}} element{?s}.",
        "x" = "You supplied an object with {.val {len_x}} element{?s}."
      ),
      class = "seekr_error_length",
      call = call
    )
  }

  if (len_x < len_min) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must contain at least {.val {len_min}} element{?s}.",
        "x" = "You supplied an object with {.val {len_x}} element{?s}."
      ),
      class = "seekr_error_length_min",
      call = call
    )
  }

  if (len_x > len_max) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must contain at most {.val {len_max}} element{?s}.",
        "x" = "You supplied an object with {.val {len_x}} element{?s}."
      ),
      class = "seekr_error_length_max",
      call = call
    )
  }

  if (!na_ok && anyNA(x)) {
    if (len_x == 1L) {
      cli::cli_abort(
        "{.arg {arg}} must not be {.val NA}.",
        class = "seekr_error_na",
        call = call
      )
    }

    where = which(is.na(x))
    n = length(where)
    cli::cli_abort(
      c(
        "{.arg {arg}} must not contain {.val NA} values.",
        "x" = "Missing values at {.val {n}} location{?s}: {.val {where}}."
      ),
      class = "seekr_error_na",
      call = call
    )
  }

  return(x)
}


#' @keywords internal
assert_non_empty_string = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is.null(x) || anyNA(x)) {
    cli::cli_abort(
      "Internal error: NULL and NA string not supported by assert_non_empty_string().",
      class = "internal_error",
      call = call
    )
  }

  len_x = length(x)
  empty_string = !nzchar(x)

  if (any(empty_string)) {
    if (len_x == 1L) {
      cli::cli_abort(
        "{.arg {arg}} must not be an empty string.",
        class = "seekr_error_empty_string",
        call = call
      )
    }

    where = which(empty_string)
    n = length(where)
    cli::cli_abort(
      c(
        "{.arg {arg}} must not contain empty strings.",
        "x" = "Empty strings at {.val {n}} location{?s}: {.val {where}}."
      ),
      class = "seekr_error_empty_string",
      call = call
    )
  }

  return(x)
}


#' @keywords internal
assert_integerish = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (!checkmate::test_integerish(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be integer-like (`integerish`).",
      class = "seekr_error_integerish",
      call = call
    )
  }

  return(x)
}


# Generic assertions ------------------------------------------------------

#' @keywords internal
assert_flag = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x = x,
    classes = "logical",
    len = 1L,
    na_ok = FALSE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  return(x)
}


#' @keywords internal
assert_paths = function(
  x,
  len = NULL,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x = x,
    classes = "character",
    len = len,
    na_ok = FALSE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  assert_non_empty_string(x, arg = arg, call = call)

  return(x)
}


#' @keywords internal
assert_pattern = function(
  x,
  null_ok = FALSE,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (inherits(x, "stringr_boundary")) {
    cli::cli_abort(
      "{.arg {arg}} must not be a {.cls stringr_boundary} pattern.",
      class = "seekr_error_pattern_boundary",
      call = call
    )
  }

  assert_vector(
    x = x,
    classes = c(
      "stringr_regex",
      "stringr_fixed",
      "stringr_coll",
      "character"
    ),
    len = 1L,
    na_ok = FALSE,
    null_ok = null_ok,
    arg = arg,
    call = call
  )

  return(x)
}


#' @keywords internal
assert_match = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x,
    classes = "seekr_match",
    na_ok = FALSE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  assert_fields_values(x, call = call)

  if (rlang::is_empty(x)) {
    return(x)
  }

  empty_match = which(field(x, "match") == "" & (field(x, "start") - field(x, "end") == 1L))
  start_after_end = which(field(x, "start") > field(x, "end"))
  start_after_end = start_after_end[!start_after_end %in% empty_match]

  if (!rlang::is_empty(start_after_end)) {
    cli::cli_abort(
      c(
        "Invalid range between {.var start} and {.var end}.",
        "x" = "Field {.var start} cannot be greater than field {.var end}.",
        "i" = "The only exception is for empty match (i.e., {.code start == end + 1}).",
        "i" = "Problem in matches {start_after_end}"
      ),
      class = "seekr_error_match_start_after_end",
      call = call
    )
  }

  start_after_end_line = which(field(x, "start_line") > field(x, "end_line"))
  start_after_end_line = start_after_end_line[!start_after_end_line %in% empty_match]
  if (!rlang::is_empty(start_after_end_line)) {
    cli::cli_abort(
      c(
        "Invalid range between {.var start_line} and {.var end_line}.",
        "x" = "Field {.var start_line} cannot be greater than field {.var end_line}.",
        "i" = "Problem in matches {start_after_end_line}"
      ),
      class = "seekr_error_match_start_after_end_line",
      call = call
    )
  }

  for (xi in split_match_by_source(x)) {
    overlap_or_wrong_order =
      utils::tail(field(xi, "start"), -1L) <= utils::head(field(xi, "end"), -1L)

    if (any(overlap_or_wrong_order)) {
      cli::cli_abort(
        c(
          "{.arg x} is not a valid {.cls seekr_match} vector.",
          "x" = "Within each file, matches must be ordered by location and must not overlap.",
          "i" = "Use {.fn sort} to order matches globally by file and location.",
          "i" = "Use {.fn sort_within_files} to preserve the file order of appearance."
        ),
        class = "seekr_error_match_order_or_overlap",
        call = call
      )
    }
  }

  return(x)
}


assert_fields_values = function(x, call = rlang::caller_env()) {
  if (rlang::inherits_any(x, "seekr_match")) {
    df = vctrs::vec_data(x)
  } else {
    df = x
  }

  df = df[seekr_match_fields()]

  assert_paths(df$path, arg = "path")

  check_fields = list(
    path = checkmate::check_character(df$path, any.missing = FALSE, min.chars = 1L),
    start_line = checkmate::check_integer(df$start_line, lower = 1L, any.missing = FALSE),
    end_line = checkmate::check_integer(df$end_line, lower = 1L, any.missing = FALSE),
    start = checkmate::check_integer(df$start, lower = 1L, any.missing = FALSE),
    end = checkmate::check_integer(df$end, lower = 1L, any.missing = FALSE),
    start_col = checkmate::check_integer(df$start_col, lower = 1L, any.missing = FALSE),
    end_col = checkmate::check_integer(df$end_col, lower = 1L, any.missing = FALSE),
    match = checkmate::check_character(df$match, any.missing = FALSE),
    replacement = checkmate::check_character(df$replacement, any.missing = TRUE),
    before = checkmate::check_character(df$before, any.missing = TRUE),
    line = checkmate::check_character(df$line, any.missing = FALSE),
    after = checkmate::check_character(df$after, any.missing = TRUE),
    encoding = checkmate::check_character(df$encoding, any.missing = TRUE),
    hash = checkmate::check_character(df$hash, any.missing = FALSE)
  )

  problematic_fields = purrr::keep(check_fields, is.character)

  if (!rlang::is_empty(problematic_fields)) {
    fields_errors_msg = structure(
      paste0("{.field ", names(problematic_fields), "}: ", as.character(problematic_fields)),
      names = rep("!", length(problematic_fields))
    )

    cli::cli_abort(
      c(
        "Invalid {.cls seekr_match} vector.",
        "x" = "Some fields do not have the expected type or allowed values for a {.cls seekr_match} vector.",
        "i" = "This usually happens after modifying columns or fields that should not be modified.",
        "i" = "The only field that should usually be updated manually is {.field replacement}.",
        fields_errors_msg
      ),
      call = call,
      class = "seekr_error_match_incorrect_fields"
    )
  }

  return(x)
}


# Options assertions ------------------------------------------------------

#' @keywords internal
assert_seekr_option = function(
  name,
  value,
  call = rlang::caller_env()
) {
  if (!name %in% names(seekr_options_defaults())) {
    cli::cli_abort(
      "Internal error: an unknown option should not be asserted.",
      class = "seekr_error_option_unknown",
      call = call
    )
  }

  if (name == "seekr.progress") {
    if (!checkmate::test_flag(value, na.ok = FALSE)) {
      cli::cli_abort(
        c(
          "Invalid value for option {.val {name}}.",
          "x" = "Expected either {.code TRUE} or {.code FALSE}.",
          "i" = "You can reset it with {.code options(seekr.progress = NULL)}."
        ),
        class = "seekr_error_option_progress",
        call = call
      )
    }
  }

  if (name == "seekr.backup_dir") {
    if (!checkmate::test_string(value, na.ok = FALSE)) {
      cli::cli_abort(
        c(
          "Invalid value for option {.val {name}}.",
          "x" = "Expected a single non-missing string representing the path to a backup directory.",
          "i" = "seekr checks whether this directory can be created when a backup is actually written.",
          "i" = "You can reset it with {.code options(seekr.backup_dir = NULL)}."
        ),
        class = "seekr_error_option_backup_dir",
        call = call
      )
    }
  }

  if (stringr::str_detect(name, "^seekr\\.style\\.")) {
    assert_option_ansi_style(name, value, call = call)
  }

  if (name == "seekr.print.mode") {
    if (!checkmate::test_choice(value, c("rich", "color", "plain"))) {
      cli::cli_abort(
        c(
          "Invalid value for option {.val {name}}.",
          "x" = "Current value is {.val {value}}.",
          "i" = "Expected one of {.val rich} or {.val color} or {.val plain}.",
          "i" = "You can reset it with {.code options(seekr.print.mode = NULL)}."
        ),
        class = "seekr_error_option_print_mode",
        call = call
      )
    }
  }

  if (name == "seekr.print.tab") {
    assert_option_print_symbol(
      name = name,
      value = value,
      label = "tab",
      examples = c("\u2192", ">"),
      call = call
    )
  }

  if (name == "seekr.print.newline") {
    assert_option_print_symbol(
      name = name,
      value = value,
      label = "newline",
      examples = c("\u21b5", "\u2193"),
      call = call
    )
  }

  return(value)
}


#' @keywords internal
assert_option_print_symbol = function(
  name,
  value,
  label,
  examples,
  call = rlang::caller_env()
) {
  if (!checkmate::test_string(value, na.ok = FALSE)) {
    cli::cli_abort(
      c(
        "Invalid value for option {.val {name}}.",
        "x" = "Expected a single string.",
        "i" = "Current value has type {.cls {class(value)[[1]]}}."
      ),
      class = "seekr_error_option_print_symbol",
      call = call
    )
  }

  width = cli::ansi_nchar(value)

  if (width != 1L) {
    cli::cli_abort(
      c(
        "Invalid {label} symbol for option {.val {name}}.",
        "x" = "Current value {.val {value}} spans {.strong {width}} display characters.",
        "i" = "seekr requires this symbol to occupy exactly one display character to keep printed columns aligned.",
        "i" = "Use {.code options({name} = \"<single character>\")}.",
        "i" = "For example: {.code options({name} = \"{examples[[1]]}\")} or {.code options({name} = \"{examples[[2]]}\")}."
      ),
      class = "seekr_error_option_print_symbol",
      call = call
    )
  }

  return(value)
}


#' @keywords internal
assert_option_ansi_style = function(
  name,
  value,
  call = rlang::caller_env()
) {
  if (!checkmate::test_string(value, na.ok = FALSE)) {
    cli::cli_abort(
      c(
        "Invalid ANSI style for option {.val {name}}.",
        "x" = "Expected a single string.",
        "i" = "Use ANSI SGR codes such as {.val 31}, {.val 1;31}, or {.val 38;5;243}."
      ),
      class = "seekr_error_option_ansi_style",
      call = call
    )
  }

  if (!stringr::str_detect(value, "^[0-9]+(;[0-9]+)*$")) {
    cli::cli_abort(
      c(
        "Invalid ANSI style for option {.val {name}}.",
        "x" = "Current value is {.val {value}}.",
        "i" = "Expected a semicolon-separated sequence of numeric ANSI SGR codes.",
        "i" = "Examples: {.val 31} for red, {.val 1;31} for bold red, {.val 38;5;243} for 256-color grey.",
        "!" = "seekr only checks the shape of the ANSI code, not whether the style is meaningful in every terminal."
      ),
      class = "seekr_error_option_ansi_style",
      call = call
    )
  }

  return(value)
}


# List files assertions ---------------------------------------------------

#' @keywords internal
assert_path_list_files = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x = x,
    classes = "character",
    na_ok = FALSE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  assert_non_empty_string(x, arg = arg, call = call)

  is_dir = fs::is_dir(x, follow = TRUE)

  if (any(!is_dir)) {
    n_notdir = sum(!is_dir)

    cli::cli_abort(
      c(
        "{.arg {arg}} must contain existing directories.",
        "x" = "The following {.val {n_notdir}} path{?s} {?is/are} not: {.path {x[!is_dir]}}."
      ),
      class = "seekr_error_notdir",
      call = call
    )
  }

  return(x)
}


#' @keywords internal
assert_recurse = function(
  x,
  arg  = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x = x,
    classes = c("logical", "integer", "numeric"),
    len = 1L,
    na_ok = FALSE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  if (rlang::inherits_any(x, c("integer", "numeric"))) {
    assert_integerish(x, arg = arg, call = call)

    if (x < 0L) {
      cli::cli_abort(
        c(
          "{.arg {arg}} must be a non-negative integer when a number is supplied.",
          "x" = "You supplied {.val {x}}."
        ),
        class = "seekr_error_bounds",
        call = call
      )
    }
  }

  return(x)
}


#' @keywords internal
assert_git_available = function(git = Sys.which("git")) {
  git = unname(git[[1]])

  if (!nzchar(git)) {
    cli::cli_abort(
      c(
        "{.arg use_git} requires Git to be installed and available on {.envvar PATH}.",
        "x" = "No {.code git} executable was found.",
        "i" = "Install Git or call {.fn list_files} with {.code use_git = FALSE}."
      ),
      class = "seekr_error_git_not_available",
      call = quote(list_files())
    )
  }

  invisible(TRUE)
}


# filter files assertions -------------------------------------------------

#' @keywords internal
assert_extension = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x = x,
    classes = "character",
    len_min = 1L,
    na_ok = FALSE,
    null_ok = TRUE,
    arg = arg,
    call = call
  )

  return(x)
}


#' @keywords internal
assert_max_file_size = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x,
    classes = c("integer", "numeric"),
    len = 1L,
    na_ok = FALSE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  if (!is.infinite(x)) {
    assert_integerish(x, arg = arg, call = call)
  }

  return(x)
}


#' @keywords internal
assert_exclude = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is.null(x) || identical(x, exclude_functions)) {
    return(x)
  }

  list_of_functions = checkmate::test_list(x, types = "function", any.missing = FALSE)
  fn_names = names(x)

  if (!list_of_functions || is.null(fn_names)) {
    cli::cli_abort(
      "{.arg {arg}} must be a list of named functions.",
      class = "seekr_error_exclude_functions",
      call = call
    )
  }

  names_ok = fn_names == make.names(fn_names, unique = TRUE)

  reserved_fn_names = c(
    "exclude_by_extension",
    "exclude_by_path_pattern",
    "exclude_by_file_size"
  )

  has_reserved_names = fn_names %in% reserved_fn_names

  if (any(!names_ok) || anyNA(names_ok) || any(has_reserved_names)) {
    message = c(
      "{.arg {arg}} must all have valid names.",
      "i" = "Names must not be missing ({.val NA}).",
      "i" = "Names must not be empty strings.",
      "i" = "Names must be unique.",
      "i" = "Names must be different from {.val {reserved_fn_names}}.",
      "x" = "Names must comply with R's variable name restrictions (syntactic + reserved)."
    )

    if (anyNA(fn_names)) {
      names(message)[2] = "x"
      fn_names = fn_names[!is.na(fn_names)]
    }

    if (any(fn_names == "")) {
      names(message)[3] = "x"
    }

    if (anyDuplicated(fn_names) > 0L) {
      names(message)[4] = "x"
    }

    if (any(fn_names %in% reserved_fn_names)) {
      names(message)[5] = "x"
    }

    cli::cli_abort(
      message,
      class = "seekr_error_exclude_functions_names",
      call = call
    )
  }

  fn_n_args = purrr::map_int(x, \(fn) length(formals(fn)))
  fn_only_dots = purrr::map_lgl(x, \(fn) identical(names(formals(fn)), "..."))

  if (any(fn_n_args < 1L) || any(fn_only_dots)) {
    bad = names(x)[fn_n_args < 1L | fn_only_dots]

    cli::cli_abort(
      c(
        "{.arg {arg}} must contain functions that accept at least one named argument.",
        "x" = "{.val {length(bad)}} function{?s} without arguments: {.fn {bad}}.",
        "i" = "Each exclude function must accept a vector of file paths as first argument."
      ),
      class = "seekr_error_exclude_functions_arguments",
      call = call
    )
  }

  return(x)
}


#' @keywords internal
assert_exclude_function_return = function(
  x,
  len,
  arg,
  call = rlang::caller_env()
) {
  if (is.null(x)) {
    cli::cli_abort(
      c(
        "Exclude function {.arg {arg}} returned {.val NULL}.",
        "x" = "It must return a logical vector.",
        "i" = "It must return one TRUE/FALSE value for each input path."
      ),
      class = "seekr_error_null",
      call = call
    )
  }

  if (!is.logical(x)) {
    cli::cli_abort(
      c(
        "Exclude function {.arg {arg}} must return a logical vector.",
        "x" = "It returned an object of class {.cls {class(x)}} instead.",
        "i" = "It must return one TRUE/FALSE value for each input path."
      ),
      class = "seekr_error_type",
      call = call
    )
  }

  if (anyNA(x)) {
    where = which(is.na(x))
    n = length(where)

    cli::cli_abort(
      c(
        "Exclude function {.arg {arg}} must not return {.val NA} values.",
        "x" = "Missing values at {.val {n}} location{?s}: {.val {where}}.",
        "i" = "Each value must be either TRUE or FALSE."
      ),
      class = "seekr_error_na",
      call = call
    )
  }

  len_x = length(x)

  if (len_x != len) {
    cli::cli_abort(
      c(
        "Exclude function {.arg {arg}} returned the wrong number of values.",
        "x" = "Expected {.val {len}} logical value{?s}, but got {.val {len_x}}.",
        "i" = "An exclude function is called with a character vector of file paths.",
        "i" = "It must return one TRUE/FALSE value for each input path.",
        "i" = "For an empty input vector, return {.code logical()}."
      ),
      class = "seekr_error_length",
      call = call
    )
  }

  return(x)
}


# Match files assertions --------------------------------------------------

#' @keywords internal
assert_replacement = function(
  x,
  pattern,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (checkmate::test_function(x, null.ok = FALSE)) {
    with_capture_groups_matrix = isTRUE(attr(x, "seekr_with_capture_groups_matrix"))
    not_regex = rlang::inherits_any(
      pattern,
      c("stringr_fixed", "stringr_coll", "stringr_boundary")
    )

    if (with_capture_groups_matrix && not_regex) {
      cli::cli_abort(
        c(
          "Group-based replacements require a regular expression pattern.",
          "x" = "You supplied a {.arg replacement} function created with {.fn with_capture_groups_matrix}.",
          "x" = "Your {.arg pattern} is of class {.cls {class(pattern)[1]}}.",
          "i" = 'Capture groups ("\\\\1", "\\\\2", \u2026) are only available when {.arg pattern} is:',
          "*" = "a plain string (automatically treated as {.fn regex}),",
          "*" = "an object of class {.cls stringr_regex} created by {.fn regex}.",
          "i" = "They are not available with {.fn fixed}, {.fn coll}, or {.fn boundary} patterns."
        ),
        class = "seekr_error_replacement_groups_pattern",
        call = call
      )
    }

    if (length(formals(x)) < 1L) {
      if (with_capture_groups_matrix) {
        arg_detail = "the captured groups matrix"
      } else {
        arg_detail = "the character vector of matches"
      }

      cli::cli_abort(
        c(
          "{.arg {arg}} must accept at least one argument, ({arg_detail}).",
          "x" = "You supplied a function that doesn't take any arguments."
        ),
        class = "seekr_error_replacement_noargs",
        call = call
      )
    }

    return(x)
  }

  assert_vector(
    x,
    classes = "character",
    len = 1L,
    na_ok = FALSE,
    null_ok = TRUE,
    arg = arg,
    call = call
  )

  return(x)
}


#' @keywords internal
assert_context = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x,
    classes = c("integer", "numeric"),
    len_min = 1L,
    len_max = 2L,
    na_ok = FALSE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  assert_integerish(x, arg = arg, call = call)

  if (any(x < 0L)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be either a single non-negative integer or a pair of non-negative integers.",
        "x" = "You supplied {.val {x}}."
      ),
      class = "seekr_error_bounds",
      call = call
    )
  }

  return(x)
}


#' @keywords internal
assert_encoding = function(
  x,
  null_ok = TRUE,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x,
    classes = "character",
    len = 1L,
    na_ok = FALSE,
    null_ok = null_ok,
    arg = arg,
    call = call
  )

  if (!is.null(x) && !is.na(x)) {
    assert_non_empty_string(x, arg = arg, call = call)
  }

  return(x)
}


#' @keywords internal
assert_file_text = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x,
    classes = "character",
    len = 1L,
    na_ok = FALSE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  return(x)
}


#' @keywords internal
assert_replacement_function_return = function(
  x,
  len,
  call = rlang::caller_env()
) {
  if (is.null(x)) {
    cli::cli_abort(
      c(
        "Replacement function returned {.val NULL}.",
        "x" = "It must return a character vector.",
        "i" = "It must return one replacement value for each match."
      ),
      class = "seekr_error_null",
      call = call
    )
  }

  if (!is.character(x)) {
    cli::cli_abort(
      c(
        "Replacement function must return a character vector.",
        "x" = "It returned an object of class {.cls {class(x)}} instead.",
        "i" = "It must return one replacement value for each match."
      ),
      class = "seekr_error_class",
      call = call
    )
  }

  len_x = length(x)

  if (len_x != len) {
    cli::cli_abort(
      c(
        "Replacement function returned the wrong number of values.",
        "x" = "Expected {.val {len}} replacement value{?s}, but got {.val {len_x}}.",
        "i" = "A replacement function is called with one value per match.",
        "i" = "It must return one character value for each input match.",
        "i" = "For an empty input vector, return {.code character()}."
      ),
      class = "seekr_error_length",
      call = call
    )
  }

  return(x)
}


# Backup assertions -------------------------------------------------------

#' @keywords internal
assert_backup_description = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x,
    classes = "character",
    len = 1L,
    na_ok = TRUE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  return(x)
}


#' @keywords internal
assert_id = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_vector(
    x,
    classes = c("integer", "numeric"),
    na_ok = FALSE,
    null_ok = FALSE,
    arg = arg,
    call = call
  )

  assert_integerish(x, arg = arg, call = call)

  return(x)
}


# Replacements assertions -------------------------------------------------

#' @keywords internal
assert_match_for_replacement = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  assert_match(x, arg = arg, call = call)

  replacement = field(x, "replacement")
  missing = is.na(replacement)

  if (any(missing)) {
    n_missing = sum(missing)

    cli::cli_abort(
      c(
        "Cannot replace matches because the {.cls seekr_match} vector {.arg {arg}} contains missing replacement values.",
        "x" = "{n_missing} replacement value{?s} {?is/are} missing.",
        "i" = "Every match must have a concrete replacement before calling {.fn replace_files}/{.fn replace_text}.",
        "i" = "To bypass this error, you can either:",
        "i" = " \u2022 Exclude the match without replacement with {.code x <- filter_match(x, !is.na(replacement))}",
        "i" = " \u2022 Set replacements with {.code field(x, \"replacement\") <- \"bar\"}",
        "i" = " \u2022 Provide {.arg replacement} when creating the match object using {.fn seek}/{.fn seekr} or {.fn match_files}/{.fn match_text}."
      ),
      class = "seekr_error_replacement_na_for_replacement",
      call = call
    )
  }

  for (xi in split_match_by_source(x)) {
    source = field(xi, 'path')[[1L]]
    distinct_encoding = unique(field(xi, "encoding"))
    n_distinct_encoding = length(distinct_encoding)

    if (n_distinct_encoding > 1L) {
      cli::cli_abort(
        c(
          "Cannot safely replace matches for source {.file {source}}.",
          "x" = "The matches for this source do not all use the same encoding.",
          "i" = "Each source must have a single encoding before replacements can be applied.",
          "i" = "Encodings found: {.val {distinct_encoding}}."
        ),
        class = "seekr_error_match_single_source_multiple_encoding",
        call = call
      )
    }

    distinct_hash = unique(field(xi, "hash"))
    n_distinct_hash = length(distinct_hash)

    if (n_distinct_hash > 1L) {
      cli::cli_abort(
        c(
          "Cannot safely replace matches for source {.file {source}}.",
          "x" = "The matches were not all created from the same version of the source.",
          "i" = "{.pkg seekr} records a hash of the searched text when matches are created.",
          "i" = "Multiple hashes for the same source usually mean that you searched once, modified the file or text, searched again, and then combined both match vectors."
        ),
        class = "seekr_error_match_single_source_multiple_hash",
        call = call
      )
    }

  }

  return(x)
}


#' @keywords internal
assert_hash_for_replacement = function(
  text,
  x,
  call = rlang::caller_env()
) {
  if (rlang::is_empty(x)) {
    return(invisible(x))
  }

  expected_hash = field(x, "hash")[[1]]
  current_hash = rlang::hash(text)

  if (!identical(expected_hash, current_hash)) {
    source = field(x, 'path')[[1L]]
    cli::cli_abort(
      c(
        "Cannot safely replace matches.",
        "x" = "The text has changed since these matches were created.",
        "i" = "{.pkg seekr} records a hash of the searched text when matches are created.",
        "i" = "Before replacing, the current text is hashed again and compared with the recorded hash.",
        "i" = "For source {.file {source}}, the current text no longer matches the text that was searched.",
        "i" = "Run the search again on the current version of the source before replacing."
      ),
      class = "seekr_error_replacement_hash_changed",
      call = call
    )
  }

  invisible(x)
}


# Restore files assertions ------------------------------------------------

#' @keywords internal
assert_restore_from_to = function(
  from,
  to,
  call = rlang::caller_env()
) {
  assert_paths(from, call = call)
  assert_paths(to, call = call)

  if (length(from) != length(to)) {
    cli::cli_abort(
      c(
        "Cannot restore files because {.arg from} and {.arg to} have different lengths.",
        "x" = "{.arg from} has length {length(from)}.",
        "x" = "{.arg to} has length {length(to)}.",
        "i" = "Each backup file in {.arg from} must correspond to exactly one destination file in {.arg to}."
      ),
      class = "seekr_error_restore_from_to_lengths",
      call = call
    )
  }

  if (any(!fs::file_exists(from))) {
    missing = from[!fs::file_exists(from)]
    n_missing = length(missing)

    cli::cli_abort(
      c(
        "Cannot restore files because some backup files are missing.",
        "x" = "{n_missing} file{?s} in {.arg from} could not be found.",
        "i" = "See column {.val backup_exists} in {.fun list_backups}"
      ),
      class = "seekr_error_restore_missing_backup",
      call = call
    )
  }

  if (any(!fs::is_file(from))) {
    cli::cli_abort(
      "Cannot restore files because some backup paths are not regular files.",
      class = "seekr_error_restore_from_is_directory",
      call = call
    )
  }


  to_normalized = fs::path_norm(fs::path_abs(fs::path_expand(to)))
  duplicated_to = unique(to_normalized[duplicated(to_normalized)])

  if (length(duplicated_to) > 0L) {
    cli::cli_abort(
      c(
        "Cannot restore multiple backups to the same destination file.",
        "x" = "{length(duplicated_to)} duplicate destination file{?s} detected in {.arg to}.",
        "i" = "Each destination file must appear only once."
      ),
      class = "seekr_error_restore_duplicate_destination",
      call = call
    )
  }

  if (any(fs::file_exists(to) & fs::is_dir(to))) {
    cli::cli_abort(
      "Cannot restore files because some destination files {.arg to} are directories instead of files.",
      class = "seekr_error_restore_to_is_directory",
      call = call
    )
  }

  return(list(from = from, to = to))
}


# Others assertions -------------------------------------------------------

#' @keywords internal
assert_filter_match_result = function(
  x,
  len,
  call = rlang::caller_env()
) {
  if (is.null(x)) {
    cli::cli_abort(
      c(
        "Filter expression returned {.val NULL}.",
        "x" = "It must return a logical vector.",
        "i" = "It must return one TRUE/FALSE value for each match."
      ),
      class = "seekr_error_filter_match_result_null",
      call = call
    )
  }

  if (!is.logical(x)) {
    cli::cli_abort(
      c(
        "Filter expression must return a logical vector.",
        "x" = "It returned an object of class {.cls {class(x)}} instead.",
        "i" = "It must return one TRUE/FALSE value for each match."
      ),
      class = "seekr_error_filter_match_result_type",
      call = call
    )
  }

  if (anyNA(x)) {
    where = which(is.na(x))
    n = length(where)

    cli::cli_abort(
      c(
        "Filter expression must not return {.val NA} values.",
        "x" = "Missing values at {.val {n}} location{?s}: {.val {where}}.",
        "i" = "Each value must be either TRUE or FALSE."
      ),
      class = "seekr_error_filter_match_result_na",
      call = call
    )
  }

  len_x = length(x)

  if (len_x != len) {
    cli::cli_abort(
      c(
        "Filter expression returned the wrong number of values.",
        "x" = "Expected {.val {len}} logical value{?s}, but got {.val {len_x}}.",
        "i" = "It must return one TRUE/FALSE value for each match."
      ),
      class = "seekr_error_filter_match_result_length",
      call = call
    )
  }

  return(x)
}

#' @keywords internal
assert_n_print = function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (is.null(x)) {
    return(x)
  }

  assert_vector(
    x,
    classes = c("integer", "numeric"),
    len_min = 1L,
    len_max = 1L,
    na_ok = FALSE,
    null_ok = TRUE,
    arg = arg,
    call = call
  )

  if (x < 0L) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a single non-negative integer.",
        "x" = "You supplied {.val {x}}."
      ),
      class = "seekr_error_bounds",
      call = call
    )
  }

  if (is.infinite(x)) {
    return(x)
  }

  assert_integerish(x, arg = arg, call = call)

  return(x)
}
