#' Create `seekr_match` vectors
#'
#' @description
#' A `seekr_match` is an S3 vector built on [vctrs::new_rcrd()] that represents
#' the matches found by [seek()], [seekr()], [match_files()], or [match_text()].
#'
#' Each element corresponds to a single match and stores its source path,
#' position, matched text, optional replacement, surrounding context lines,
#' encoding, and a hash of the searched text used for replacement safety.
#'
#' @param path A character vector of source identifiers. For file workflows,
#'   these are normalized absolute file paths. For [match_text()] workflows,
#'   they may also be non-existing identifiers.
#' @param start_line,end_line Integer vectors. 1-based line numbers where each
#'   match begins and ends.
#' @param start,end Integer vectors. 1-based absolute character positions where
#'   each match begins and ends.
#' @param start_col,end_col Integer vectors. 1-based column positions of the
#'   match start and end within their respective lines.
#' @param match A character vector. The exact text matched.
#' @param replacement A character vector. The staged replacement for each
#'   match. `NA` indicates no replacement is staged.
#' @param before A character vector. Context lines preceding each match.
#' @param line A character vector. The complete line(s) containing each match.
#' @param after A character vector. Context lines following each match.
#' @param encoding A character vector. The encoding used to read each file.
#' @param hash A character vector. Hash of the searched text, used to
#'   check that it has not changed before replacement.
#'
#' @return
#' `new_seekr_match()` returns an empty or populated `seekr_match` vector.
#' `new_seekr_match()` is a low-level constructor intended primarily for internal
#' use and advanced extensions. In normal usage, create `seekr_match` vectors with
#' [seek()], [seekr()], [match_files()], or [match_text()].
#'
#' @section Fields:
#' Access any field with [vctrs::field()] which is re-exported by seekr:
#'
#' ```r
#' field(x, "path")
#' field(x, "match")
#' ```
#'
#' @section Methods and functions:
#' `seekr_match` objects support the following S3 methods:
#'
#' - [print()][print.seekr_match()]: displays matches in a formatted view with
#'   optional context and replacement preview.
#' - [summary()][summary.seekr_match()]: summarizes matches by file, matched
#'   text, replacement, extension, and encoding.
#' - [str()][str.seekr_match()]: shows the internal field structure with types
#'   and sample values.
#' - [tibble::as_tibble()][as_tibble.seekr_match()]: converts to a tibble for
#'   advanced manipulation.
#'
#' The following functions are also commonly used with `seekr_match` vectors:
#'
#' - [as_match()]: converts a tibble back to a `seekr_match` vector.
#' - [filter_match()]: subsets matches using dplyr-style expressions.
#' - [sort_within_files()]: reorders matches within each file while
#'   preserving file order.
#'
#' @section Attributes:
#' In addition to its fields, a `seekr_match` vector returned by [seek()] or [seekr()]
#' may carry two attributes:
#'
#' - `empty_stage`: when the vector is empty, indicates which pipeline step
#'   produced no output. Retrieve with [empty_stage()].
#' - `exclusions`: when files were removed during filtering, a data frame
#'   detailing which files were excluded and by which function. Retrieve with
#'   [exclusions()].
#'
#' These attributes are dropped when combining `seekr_match` vectors.
#'
#' @seealso
#' - [seek()] and [seekr()] to search for matches and produce `seekr_match`
#'   vectors.
#' - [print.seekr_match()] and [summary.seekr_match()] to inspect results.
#' - [filter_match()] to subset matches before replacing.
#' - [replace_files()] to apply staged replacements.
#' - [empty_stage()] and [exclusions()] to diagnose empty results.
#'
#' @examples
#' # Produce a seekr_match vector
#' ext_path <- system.file("extdata", package = "seekr")
#' x <- seekr("function", toupper, path = ext_path)
#'
#' # Access a field
#' field(x, "path")
#' field(x, "match")
#'
#' # Subset
#' head(x, 3)
#'
#' # Combine two seekr_match vectors
#' y <- seekr("Hello", path = ext_path)
#' c(x, y)
#'
#' @name seekr_match
#' @export
new_seekr_match = function(
  path = character(),
  start_line = integer(),
  end_line = integer(),
  start = integer(),
  end = integer(),
  start_col = integer(),
  end_col = integer(),
  match = character(),
  replacement = character(),
  before = character(),
  line = character(),
  after = character(),
  encoding = character(),
  hash = character()
) {
  new_rcrd(
    fields = list(
      path = path,
      start_line = start_line,
      end_line = end_line,
      start = start,
      end = end,
      start_col = start_col,
      end_col = end_col,
      match = match,
      replacement = replacement,
      before = before,
      line = line,
      after = after,
      encoding = encoding,
      hash = hash
    ),
    class = "seekr_match"
  )
}


#' @keywords internal
seekr_match_fields = function() {
  c(
    "path",
    "start_line",
    "end_line",
    "start",
    "end",
    "start_col",
    "end_col",
    "match",
    "replacement",
    "before",
    "line",
    "after",
    "encoding",
    "hash"
  )
}


# vctrs methods -----------------------------------------------------------

#' @export
vec_ptype2.seekr_match.seekr_match = function(x, y, ...) {
  attr(x, "exclusions") = NULL
  attr(x, "empty_stage") = NULL
  x
}


#' @export
vec_cast.seekr_match.seekr_match = function(x, to, ...) {
  attr(x, "exclusions") = NULL
  attr(x, "empty_stage") = NULL
  x
}


#' @export
vec_proxy_equal.seekr_match = function(x, ...) {
  df = vec_data(x)

  for (col in c("replacement", "before", "after", "encoding")) {
    missing = is.na(df[[col]])
    df[[paste0(col, "_missing")]] = missing
    df[[col]][missing] = ""
  }

  return(df)
}


#' @export
vec_proxy_compare.seekr_match = function(x, ...) {
  data.frame(
    path = field(x, "path"),
    start = field(x, "start"),
    end = field(x, "end"),
    match = field(x, "match")
  )
}


#' @export
vec_ptype_abbr.seekr_match = function(x, ...) {
  "seekr::match"
}


#' @export
vec_ptype_full.seekr_match = function(x, ...) {
  "seekr::match"
}


#' @export
format.seekr_match = function(x, ...) {
  path = normalize_path(field(x, "path"))
  start_line = field(x, "start_line")
  start_col = field(x, "start_col")

  match = field(x, "match")
  match = escape_newlines(match)
  match = replace_all_tabs_for_printing(match)

  repl = field(x, "replacement")
  repl = escape_newlines(repl)
  repl = replace_all_tabs_for_printing(repl)
  replacement = ifelse(is.na(repl), "", paste0("/", repl))

  out = glue::glue("{path}<{start_line}:{start_col}>: <{match}{replacement}>")
  as.character(out)
}


#' @exportS3Method pillar::type_sum
type_sum.seekr_match = function(x, ...) {
  "seekr::match"
}


#' @exportS3Method pillar::pillar_shaft
pillar_shaft.seekr_match = function(
  x,
  ...,
  min_width = 20,
  shorten = "front"
) {
  pillar::new_pillar_shaft_simple(
    format(x),
    ...,
    min_width = min_width,
    shorten = shorten
  )
}


# conversion and format ---------------------------------------------------

#' Convert `seekr_match` vectors to and from data frames
#'
#' @description
#' `as_tibble()` and `as.data.frame()` convert a [`seekr_match`] vector into a
#' tibble or plain data frame, with one row per match and one column per field.
#'
#' `as_match()` is the reverse: it converts a data frame back into a
#' [`seekr_match`] vector, validating all fields and checking for overlapping
#' matches within each file before returning.
#'
#' Together, these functions unlock the full tidyverse toolkit for manipulating
#' match metadata. A typical pattern is to convert to a tibble, use
#' [dplyr::mutate()] or [dplyr::filter()] to derive or modify columns,
#' including the `replacement` field, and then convert back with `as_match()`
#' before calling [replace_files()].
#'
#' @param x For `as_tibble()` and `as.data.frame()`: a [`seekr_match`] vector.
#'
#'   For `as_match()`: a data frame with at least the columns listed in the
#'   **Fields** section of [seekr_match]. Additional columns are silently
#'   ignored. All required columns must have the correct type: `character` for
#'   string fields, `integer` for position fields.
#'
#' @param ... Not used. Present for compatibility with S3 generics.
#'
#' @return
#' `as_tibble()` returns a `tbl_df`. `as.data.frame()` returns a plain
#' `data.frame`. In both cases the result has one row per match and one column
#' per field (see the **Fields** section of [seekr_match]).
#'
#' `as_match()` returns a [`seekr_match`] vector. Matches within each file are
#' sorted by position. Overlapping or incoherent matches within the same file
#' cause an error.
#'
#' Note: the `empty_stage` and `exclusions` attributes of the original
#' [`seekr_match`] vector are not preserved through the conversion.
#'
#' @seealso
#' - [seekr_match] for the list of available fields.
#' - [filter_match()] for simpler subsetting that does not require conversion.
#' - [vctrs::field()] to access or modify a single field in place.
#' - [replace_files()] to apply staged replacements after converting back.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#' ext_path <- system.file("extdata", package = "seekr")
#' x <- seekr("TODO", path = ext_path)
#'
#' # Convert to tibble
#' df <- as_tibble(x)
#' df
#'
#' # Convert to plain data frame
#' as.data.frame(x)
#'
#' # Convert back to seekr_match
#' as_match(df)
#'
#' # Set a replacement for all matches
#' df$replacement <- "DONE"
#' as_match(df)
#'
#' # Suppose you want to replace `"foo"` with `"bar"`, but only for the last
#' # match in each file, and only in files with at least three matches:
#' x <- seekr("foo", "bar", path = ext_path)
#'
#' y <-
#'   x |>
#'   as_tibble() |>
#'   mutate(
#'     ith_match_per_file_rev = n():1L,
#'     n_match_per_file = n(),
#'     .by = path
#'   ) |>
#'   filter(ith_match_per_file_rev == 1L, n_match_per_file >= 3L) |>
#'   as_match()
#'
#' # replace_files(y)
#' }
#' @name as_tibble.seekr_match
#' @exportS3Method tibble::as_tibble
as_tibble.seekr_match = function(x, ...) {
  tibble::as_tibble(vec_data(x))
}


#' @rdname as_tibble.seekr_match
#' @export
as.data.frame.seekr_match = function(x, ...) {
  as.data.frame(vec_data(x), ...)
}


#' @rdname as_tibble.seekr_match
#' @export
as_match = function(x) {
  assert_vector(x, classes = "data.frame", na_ok = TRUE, null_ok = FALSE)
  missing = setdiff(seekr_match_fields(), names(x))

  if (!rlang::is_empty(missing)) {
    cli::cli_abort(
      c(
        "Cannot convert the data frame to a {.cls seekr_match} vector.",
        "x" = "Missing required column{?s}: {.field {missing}}."
      ),
      class = "seekr_error_as_match_missing_columns"
    )
  }

  assert_fields_values(x)

  x = x[seekr_match_fields()]
  x = as.list(x)
  x = do.call(new_seekr_match, x)
  x = sort_within_files(x)

  assert_match(x)

  return(x)
}


# Others ------------------------------------------------------------------

#' Filter matches
#'
#' @description
#' `filter_match()` subsets a [`seekr_match`] vector using expressions
#' evaluated directly against its fields, without needing to call
#' [vctrs::field()] explicitly.
#'
#' The two calls below are equivalent:
#'
#' ```r
#' x[field(x, "start_line") > 10]
#' filter_match(x, start_line > 10)
#' ```
#'
#' `filter_match()` is modelled after [dplyr::filter()]: field names can be
#' used directly in expressions, and multiple expressions are combined with
#' `&`. This makes it easy to write readable multi-condition filters:
#'
#' ```r
#' x |> filter_match(
#'   grepl("/R/", path),
#'   match == "TODO",
#'   start_line > 10
#' )
#' ```
#'
#' @param x A [`seekr_match`] vector.
#'
#' @param ... One or more filtering expressions, evaluated against the fields
#'   of `x`. Field names (`path`, `match`, `start_line`, `replacement`, etc.)
#'   can be used directly. Each expression must return a logical vector of the
#'   same length as `x`, with no missing values. Multiple expressions are
#'   combined with `&`.
#'
#' @return
#' A [`seekr_match`] vector containing only the matches for which all
#' expressions evaluated to `TRUE`. If no expressions are supplied, `x` is
#' returned unchanged.
#'
#' @section Differences from base R subsetting:
#' Unlike `x[condition]`, `filter_match()` does not recycle logical vectors.
#' Each expression must return exactly `length(x)` values. Missing values
#' (`NA`) in any expression cause an error. This prevents silent mistakes from
#' implicit recycling or incomplete conditions.
#'
#' @seealso
#' - [vctrs::field()] to access a field directly for use in base R subsetting.
#' - [as_tibble.seekr_match()] and [as_match()] for more complex workflows that
#'   require tabular manipulation.
#' - [replace_files()] to apply staged replacements after filtering.
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' x <- seekr("TODO|FIXME", path = ext_path)
#'
#' # Filter by line number
#' filter_match(x, start_line > 10)
#'
#' # Filter by file path
#' filter_match(x, grepl("/R/", path))
#'
#' # Filter by matched text
#' filter_match(x, match == "TODO")
#'
#' # Combine multiple conditions
#' filter_match(x, match == "TODO", start_line > 10, grepl("/R/", path))
#'
#' # Equivalent base R subsetting (more verbose)
#' x[
#'   field(x, "match") == "TODO" &
#'   field(x, "start_line") > 10 &
#'   grepl("/R/", field(x, "path"))
#' ]
#'
#' @export
filter_match = function(x, ...) {
  assert_vector(x, classes = "seekr_match", na_ok = TRUE, null_ok = FALSE)
  dots = rlang::enquos(...)

  if (rlang::is_empty(dots)) {
    return(x)
  }

  N = length(x)
  data = vec_data(x)
  results = purrr::map(dots, \(expr) rlang::eval_tidy(expr, data))

  for (result in results) {
    assert_filter_match_result(result, len = N)
  }

  x[purrr::reduce(results, `&`)]
}


#' Inspect the structure of a `seekr_match` vector
#'
#' @description
#' `str()` displays the internal structure of a [`seekr_match`] vector: the
#' name, type, and sample values of each field, formatted for the console
#' width.
#'
#' This is useful for a quick overview of what a [`seekr_match`] vector
#' contains without printing the full formatted output produced by
#' [print.seekr_match()].
#'
#' @param object A [`seekr_match`] vector.
#' @param ... Not used. Present for compatibility with the `str()` generic.
#'
#' @return Invisibly returns the [`seekr_match`] vector.
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' x <- seekr("TODO", path = ext_path)
#' str(x)
#'
#' @export
str.seekr_match = function(object, ...) {
  dim_quote = ansi_option('"', "dim")
  dim_comma_space = ansi_option(", ", "dim")
  dim_ellipsis = ansi_option("\u2026", "dim")

  x = object
  width = max(30, cli::console_width())
  fields_max_width = max(cli::ansi_nchar(fields(x)))
  names_padded = stringr::str_pad(fields(x), fields_max_width, "right")

  fields_type = purrr::map_chr(unclass(x), typeof)
  fields_type = unname(ifelse(fields_type == "character", "chr", "int"))
  types = ansi_option(glue::glue("<{fields_type}>"), "class")
  fields_label = glue::glue("{names_padded} {types} ")

  left_width = cli::ansi_nchar(fields_label[[1]])
  right_width = width - left_width
  n_examples = min(100L, length(x))
  vctrs_header = prepare_vctrs_header_ansi(n_matches = length(x), print_vctrs = TRUE)

  cli::cat_line(vctrs_header)
  if (rlang::is_empty(x)) {
    return(invisible(x))
  }

  tmp_vec_data = vec_data(x[1:n_examples])
  fields_content = character(length(tmp_vec_data))
  collapsed_width = integer(length(tmp_vec_data))

  for (i in seq_along(tmp_vec_data)) {
      column = tmp_vec_data[[i]]
    if (is.character(column)) {
      column = stringr::str_replace_all(column, "\\n", "\\\\n")
      column = stringr::str_replace_all(column, "\\r", "\\\\r")
      column = stringr::str_c(dim_quote, column, dim_quote)
    }

    column[is.na(column)] = ansi_option("NA", "na")
    collapsed_column = stringr::str_c(column, collapse = dim_comma_space)
    collapsed_width[[i]] = cli::ansi_nchar(collapsed_column)
    fields_content[[i]] = cli::ansi_substr(collapsed_column, 1L, right_width)
  }

  overflow = collapsed_width > right_width
  ellipsis = ifelse(overflow, dim_ellipsis, "")
  content = glue::glue("{fields_label}{fields_content}{ellipsis}")
  content = replace_all_tabs_for_printing(content)
  cli::cat_line(content)

  return(invisible(x))
}


#' @keywords internal
split_match_by_source = function(x) {
  path = field(x, "path")
  split(x, path)[unique(path)]
}


#' @keywords internal
smash = function(x) {
  if (rlang::is_empty(x)) {
    return(new_seekr_match())
  }

  vec_c(!!!x, .name_spec = rlang::zap())
}


#' Sort matches within each file
#'
#' @description
#' `sort_within_files()` sorts matches by position within each file, while
#' preserving the order in which files appear in `x`.
#'
#' This differs from `sort()`, which sorts globally and reorders files
#' alphabetically. Use `sort_within_files()` when you want positions within
#' each file to be consistent — for example, after combining two
#' [`seekr_match`] vectors with [vctrs::vec_c()] — without changing the order
#' in which files are displayed or processed.
#'
#' @param x A [`seekr_match`] vector.
#'
#' @return A [`seekr_match`] vector with the same matches in potentially
#'   different order: files appear in their original order, and matches within
#'   each file are sorted by `start`, then `end`, then `match`, then
#'   `replacement`.
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' x <- seekr("TODO", path = ext_path)
#' y <- seekr("FIXME", path = ext_path)
#'
#' # Combine and reorder within files without changing file order
#' z <- vctrs::vec_c(x, y)
#' sort_within_files(z)
#'
#' @export
sort_within_files = function(x) {
  x[order_within_files(x)]
}

#' @keywords internal
order_within_files = function(x) {
  assert_vector(x, classes = "seekr_match", na_ok = TRUE, null_ok = FALSE)

  if (rlang::is_empty(x)) {
    return(integer())
  }

  file_levels = unique(field(x, "path"))

  order(
    factor(field(x, "path"), levels = file_levels),
    field(x, "start"),
    field(x, "end"),
    field(x, "match"),
    field(x, "replacement")
  )
}
