#' Normalize file paths for seekr
#'
#' @description
#' `as_seekr_path()` converts paths to the normalized format used internally
#' by seekr for listing, filtering, matching, and replacement.
#'
#' This is useful when writing custom `exclude` functions, comparing paths
#' with seekr results, or building file vectors before calling
#' [filter_files()] or [match_files()].
#'
#'
#' @param x A character vector of paths.
#'
#' @details
#' A **seekr path** is a character path that has been:
#'
#' - expanded, so `~` is resolved,
#' - normalized, so redundant path components are removed,
#' - resolved to an absolute path,
#' - represented with forward slashes.
#'
#' ## Where seekr paths are created
#'
#' [list_files()] returns seekr paths: it starts from user-supplied
#' directories and returns the listed files as normalized absolute paths.
#'
#' [filter_files()] and [match_files()] normalize their input `path` before
#' filtering or matching. This means path-based filters such as
#' `path_pattern` are applied to seekr paths, regardless of whether the input
#' paths were originally relative, absolute, or written with
#' platform-specific separators.
#'
#' ## Why this matters
#'
#' Normalizing paths makes path filtering more predictable. A `path_pattern`
#' is matched against a stable representation of the file path instead of
#' depending on how the path was originally written by the user.
#'
#' @return
#' A character vector of normalized absolute paths, with the same length and
#' order as `x`.
#'
#' @seealso
#' [list_files()], [filter_files()], [match_files()]
#'
#' @examples
#' as_seekr_path(".")
#' as_seekr_path(c(".", "~"))
#'
#' @export
as_seekr_path = function(x) {
  assert_paths(x)
  normalize_path(x, deduplicate = FALSE)
}


#' @keywords internal
normalize_path = function(x, deduplicate = FALSE) {
  exclusions = attr(x, "exclusions", exact = TRUE)

  x = fs::path_expand(x)
  x = fs::path_norm(x)
  x = fs::path_abs(x)
  x = as.character(x)

  if (deduplicate) {
    x = unique(x)
  }

  attr(x, "exclusions") = exclusions

  return(x)
}


#' @keywords internal
normalize_extension = function(x) {
  if (is.null(x)) {
    return(x)
  }

  x = stringr::str_to_lower(x)
  x = stringr::str_remove(x, "^\\.+")
  x = unique(x)

  is_compound = stringr::str_detect(x, "\\w+\\.\\w+")

  if (any(is_compound)) {
    compound = x[is_compound]
    normalized = stringr::str_extract(compound, "\\w+$")

    cli::cli_warn(
      c(
        "The following {length(compound)} compound extension{?s} {.val {compound}} {?was/were} truncated to {.val {normalized}}.",
        "i" = "seekr uses only the last extension to match file extensions.",
        "i" = "This means the filter is more conservative: {.val .tar.gz} will match all {.val .gz} files, not only {.val .tar.gz} files.",
        "i" = "If this is not what you intended and want to be more restrictive, you can either:",
        "i" = " \u2022 Filter by path instead using {.arg path_pattern}.",
        "i" = " \u2022 Add your own filtering function in {.arg exclude}."
      ),
      .frequency = "once",
      .frequency_id = "seekr_compound_extension"
    )
  }

  x = stringr::str_extract(x, "\\w*$")
  x = unique(x)

  return(x)
}


#' @keywords internal
normalize_pattern = function(x) {
  if (rlang::inherits_any(x, "stringr_pattern")) {
    return(x)
  }

  x = stringr::regex(
    x,
    ignore_case = FALSE,
    multiline = TRUE,
    comments = FALSE,
    dotall = FALSE
  )

  return(x)
}


#' @keywords internal
normalize_context = function(x) {
  x = as.integer(x)

  if (length(x) == 1L) {
    x = c(x, x)
  }

  x = list(before = x[[1]], after = x[[2]])

  return(x)
}


#' @keywords internal
normalize_max_file_size = function(x) {
  x = if (x <= 0L) Inf else x

  return(x)
}
