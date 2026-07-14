#' Find matches in files
#'
#' @description
#' `match_files()` reads each file, decodes them using `encoding`, finds
#' `pattern` matches, and captures surrounding `context` lines. A `replacement`
#'  can be provided to stage changes for later application with [replace_files()].
#'  It is  the third and final step of the [`seek()`] pipeline, applied after
#'  [list_files()] and [filter_files()].
#'
#' @param path A character vector of file paths to read and search.
#' @inheritParams seek
#'
#' @return
#' A [`seekr_match`] vector. Each element represents one match and
#' carries the file path, match positions, matched text, optional replacement,
#' context lines, encoding, and a hash of the searched text used for replacement
#' safety. Returns an empty [`seekr_match`] vector when no matches are found.
#'
#' Files that no longer exist before matching are skipped with a warning.
#' Files that contain unsupported null bytes are also skipped with a warning.
#' Other read or decoding errors abort.
#'
#' @seealso
#' - [match_text()] to search for a pattern in in-memory text.
#' - [filter_files()] to filter files before matching.
#' - [replace_files()] to apply planned replacements.
#'
#' @note
#' For advanced use cases where you want to search for a pattern in text already
#' held in memory, see [match_text()].
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' files <- ext_path |> list_files() |> filter_files(extension = "R")
#'
#' # Search for a pattern
#' match_files(files, "TODO")
#'
#' # Capture more context lines
#' match_files(files, "TODO", context = 10L)
#'
#' # Prepare some replacements
#' match_files(files, "TODO", "DONE")
#'
#' @name match_files
#' @export
match_files = function(
  path,
  pattern,
  replacement = NULL,
  ...,
  context = 5L,
  encoding = "UTF-8",
  .progress = seekr_option("seekr.progress")
) {
  rlang::check_dots_empty()

  assert_paths(path)
  assert_pattern(pattern)
  assert_replacement(replacement, pattern)
  assert_context(context)
  assert_encoding(encoding, null_ok = TRUE)
  assert_flag(.progress)

  exclusions = attr(path, "exclusions", exact = TRUE)
  if (rlang::is_empty(path)) {
    x = structure(new_seekr_match(), exclusions = exclusions)
    return(x)
  }

  path = normalize_path(path, deduplicate = TRUE)
  pattern = normalize_pattern(pattern)
  context = normalize_context(context)
  missing_files = unique(path[!fs::file_exists(path)])

  if (!rlang::is_empty(missing_files)) {
    n_missing = length(missing_files)
    cli::cli_warn(
      c(
        "Cannot search all requested files.",
        "x" = "{n_missing} file{?s} no longer exist{?s/}.",
        "i" = "Missing files were skipped before matching."
      ),
      class = "seekr_warn_missing_files"
    )

    path = path[!path %in% missing_files]
  }

  if (rlang::is_empty(path)) {
    x = structure(new_seekr_match(), exclusions = exclusions)
    return(x)
  }

  N = length(path)
  data = vector("list", N)

  if (.progress) {
    i = 1L
    n_match_total = 0L
    msg = "Find matches: {n_match_total} match{?es} in {i}/{N} file{?s}"
    cli::cli_progress_step(
      msg = msg,
      msg_done = "Find matches: {n_match_total} match{?es}",
      spinner = TRUE
    )
  }

  n_bytes = seekr_file_info(path)$size

  for (i in seq_len(N)) {
    text = seekr_read_file(
      path = path[[i]],
      n_bytes = n_bytes[[i]],
      encoding = encoding
    )

    data[[i]] = match_file_impl(
      text = text,
      path = path[i],
      pattern = pattern,
      replacement = replacement,
      context = context,
      encoding = attr(text, "encoding", TRUE)
    )

    if (.progress) {
      rec_len = length(data[[i]]$path)

      if (rec_len > 0) {
        n_match_total = n_match_total + rec_len
      }

      cli::cli_progress_update()
    }
  }

  matches = structure(
    combine_raw_matches(data),
    exclusions = exclusions
  )

  return(matches)
}


#' @keywords internal
combine_raw_matches = function(data) {
  .extract = function(data, name) {
    unlist(lapply(data, `[[`, name), use.names = FALSE)
  }

  if (rlang::is_empty(.extract(data, "path"))) {
    return(new_seekr_match())
  }

  new_seekr_match(
    path = .extract(data, "path"),
    start_line = .extract(data, "start_line"),
    end_line = .extract(data, "end_line"),
    start = .extract(data, "start"),
    end = .extract(data, "end"),
    start_col = .extract(data, "start_col"),
    end_col = .extract(data, "end_col"),
    match = .extract(data, "match"),
    replacement = .extract(data, "replacement"),
    before = .extract(data, "before"),
    line = .extract(data, "line"),
    after = .extract(data, "after"),
    encoding = .extract(data, "encoding"),
    hash = .extract(data, "hash")
  )
}


#' @keywords internal
match_file_impl = function(
  text,
  path,
  pattern,
  replacement,
  context,
  encoding
) {
  if (is.na(text)) {
    return(list())
  }

  locs = unname(stringr::str_locate_all(text, pattern)[[1]])
  N = nrow(locs)

  if (N == 0L) {
    return(list())
  }

  locs_nl = compute_newline_locs(text)

  data = list()
  data$path = rep(path, N)
  data$start_line = findInterval(locs[, 1], locs_nl[, 2], left.open = TRUE, checkSorted = FALSE)
  data$end_line = findInterval(locs[, 2], locs_nl[, 2], left.open = TRUE, checkSorted = FALSE)
  data$start = locs[, 1]
  data$end = locs[, 2]
  data$start_col = data$start - as.integer(locs_nl[, 2][data$start_line])
  data$end_col = data$end - as.integer(locs_nl[, 2][data$end_line])
  data$match = stringr::str_sub(text, data$start, data$end)
  data$replacement = compute_replacement(text, pattern, data$match, replacement)
  data$before = extract_lines(text, locs_nl, data$start_line - context$before, data$start_line - 1L)
  data$line = extract_lines(text, locs_nl, data$start_line, data$end_line)
  data$after = extract_lines(text, locs_nl, data$end_line + 1L, data$end_line + context$after)
  data$encoding = rep(encoding, N)
  data$hash = rep(rlang::hash(text), N)

  return(data)
}


#' Find matches in text
#'
#' `match_text()` searches text that has already been read into R. It is the
#' text-level counterpart of [match_files()]: it does not read from disk and does
#' not record file encoding information.
#'
#' The resulting [`seekr_match`] vector can be inspected, summarized, filtered,
#' updated, and passed to [replace_text()]. It is not intended to be passed to
#' [replace_files()], because `seekr` did not read the source file and does not
#' control how the text was decoded.
#'
#' Use [match_files()] or [seek()]/[seekr()] for the usual file workflow.
#'
#' @inheritParams seek
#' @param text Text content as a single string.
#' @param path Source identifier associated with `text`. This is stored in the
#'   resulting [`seekr_match`] object and used later for inspection and
#'   diagnostics. It may be a real file path, but it does not need to point to an
#'   existing file.
#'
#' @return A [`seekr_match`] vector.
#'
#' @examples
#' text <- "Commodo labore culpa ullamco TODO irure laboris FIXME Lorem sunt sint"
#' x <- match_text(text = text, path = "lorem.txt", pattern = "TODO")
#' y <- match_text(text = text, path = "lorem.txt", pattern = "FIXME")
#' z <- c(x, y)
#' z
#'
#' @export
match_text = function(
  text,
  path,
  pattern,
  replacement = NULL,
  ...,
  context = 5L
) {
  rlang::check_dots_empty()

  assert_file_text(text)
  assert_paths(path, len = 1L)
  assert_pattern(pattern)
  assert_replacement(replacement, pattern)
  assert_context(context)

  if (fs::file_exists(path)) {
    path = normalize_path(path)
  }

  pattern = normalize_pattern(pattern)
  context = normalize_context(context)

  match_data = match_file_impl(
    path = path,
    text = text,
    pattern = pattern,
    replacement = replacement,
    context = context,
    encoding = NA_character_
  )

  do.call(new_seekr_match, match_data)
}


#' Extract lines from a string using newline position matrix
#'
#' Returns the substring(s) corresponding to line ranges defined by
#' start and end line numbers. This is used to extract match lines,
#' as well as context lines before and after the match.
#'
#' @inheritParams match_text
#' @param locs_nl An integer matrix from `compute_newline_locs()`, giving
#'   the start and end positions of each line in the file.
#' @param start_line A vector of starting line numbers (1-based).
#' @param end_line A vector of ending line numbers (inclusive).
#'
#' @return A character vector, one string per line range. Returns `NA` for
#' ranges that fall entirely outside the file.
#'
#' @keywords internal
extract_lines = function(text, locs_nl, start_line, end_line) {
  no_lines = end_line < start_line

  if (all(no_lines)) {
    return(rep(NA_character_, length(start_line)))
  }

  n_rows = nrow(locs_nl)
  start = pmax(1L, pmin(n_rows, start_line))
  end = pmax(1L, pmin(n_rows, end_line))

  last_rows = end == n_rows

  from = locs_nl[start, 2L] + 1L
  to = rep(-1L, length(from))
  to[!last_rows] = locs_nl[end[!last_rows] + 1L, 1L] - 1L

  lines = stringr::str_sub(text, from, to)
  lines[no_lines] = NA_character_
  lines[end_line < 1L] = NA_character_
  lines[start_line > n_rows] = NA_character_

  return(lines)
}


#' Locate newline character positions in a string
#'
#' Computes the ending positions of each line (handling all newline variants).
#'
#' @inheritParams match_text
#'
#' @return Integer matrix of newlines position with an additional row for the first
#' line where the start and end position are 0.
#'
#' @keywords internal
compute_newline_locs = function(text) {
  rbind(
    matrix(0L, nrow = 1L, ncol = 2L),
    stringr::str_locate_all(text, "\\r\\n|\\n|\\r")[[1]]
  )
}


#' Compute replacement string for each match
#'
#' Handles static and dynamic replacements, including capture group references.
#'
#' @inheritParams match_text
#' @param match Matched strings.
#'
#' @return A character vector of replacements, one per match.
#'
#' @keywords internal
compute_replacement = function(
  text,
  pattern,
  match,
  replacement,
  call = rlang::caller_env()
) {
  N = length(match)
  repl_is_function = checkmate::test_function(replacement)

  if (is.null(replacement) || (!repl_is_function && identical(replacement, NA_character_))) {
    return(rep(NA_character_, N))
  }

  if (repl_is_function) {
    if (isTRUE(attr(replacement, "seekr_with_capture_groups_matrix"))) {
      M = stringr::str_match_all(text, pattern)[[1]]
      repl = replacement(M)
    } else {
      repl = replacement(match)
    }

    assert_replacement_function_return(x = repl, len = N, call = call)
    return(as.character(repl))
  }

  cgp = unlist(stringr::str_extract_all(replacement, "(?<=\\\\)\\d+"))
  cg_index = sort(as.integer(unique(cgp)))

  if (rlang::is_empty(cgp)) {
    return(rep(replacement, N))
  }

  M = stringr::str_match_all(text, pattern)[[1]]
  M[is.na(M)] = ""
  M_n_groups = ncol(M) - 1L

  if (M_n_groups < max(cg_index)) {
    cli::cli_abort(
      c(
        "Replacement string refers to capture group(s) that do not exist.",
        "x" = "Your {.arg pattern} defines {.val {M_n_groups}} capture group{?s}.",
        "x" = "Your {.arg replacement} references group{?s}: {.val {cg_index}}.",
        "i" = "Please adjust {.arg pattern} or {.arg replacement}."
      ),
      class = "seekr_error_replacement_missing_capture_group",
      call = call
    )
  }

  replacement_glue = glue_escape(replacement)
  replacement_glue = stringr::str_replace_all(
    replacement_glue,
    r"-[\\(\d+)]-",
    "{M[, \\1 + 1L]}"
  )
  repl = glue::glue(replacement_glue)

  return(as.character(repl))
}


#' Use capture groups in function-based replacements
#'
#' This helper wraps a function to indicate that it should receive the full
#' capture group matrix as input, instead of the default vector of full matches.
#' This allows the replacement logic to use individual capture groups.
#'
#' The capture matrix is the result of [stringr::str_match_all()]: the first
#' column contains the full match, and subsequent columns contain capture groups.
#'
#' @param fn A function taking a single argument: a character matrix of capture groups,
#'   where each row corresponds to a match, the first column is the full match and
#'   subsequent columns are capture groups.
#'
#' @return A function identical to `fn`, but marked with an internal attribute
#'   used by [compute_replacement()] to dispatch on replacement logic.
#'
#' @examples
#' text <- "lorem ipsum foo_bar lorem ipsum bar_foo lorem ipsum"
#' fn_repl <- function(M) paste0(tolower(M[, 3L]), ".", toupper(M[, 2L]))
#' fn_repl <- with_capture_groups_matrix(fn_repl)
#' match_text(text, path = "example", pattern = "(\\w+)_(\\w+)", replacement = fn_repl)
#'
#' @export
with_capture_groups_matrix = function(fn) {
  if (!checkmate::test_function(fn)) {
    cli::cli_abort(
      c(
        "{.arg fn} must be a function.",
        "x" = "You supplied an object of class {.cls {class(fn)}}."
      ),
      class = "seekr_error_with_capture_groups_matrix_function"
    )
  }

  attr(fn, "seekr_with_capture_groups_matrix") = TRUE
  return(fn)
}


#' Escape curly braces for use in glue::glue templates
#'
#' Converts `{` to `{{` and `}` to `}}` to prevent premature evaluation in `glue::glue()`.
#'
#' @param x A character vector.
#'
#' @return Escaped character vector
#'
#' @keywords internal
glue_escape = function(x) {
  stringr::str_replace_all(x, c("\\{" = "{{", "\\}" = "}}"))
}
