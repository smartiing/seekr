#' Filter files to search
#'
#' @description
#' [filter_files()] keeps files matching `extension` and `path_pattern`, and
#' not exceeding `max_file_size`. Finally, the `exclude` functions are applied to
#' the remaining files, discarding common non-text or irrelevant files by default.
#' It is the second step of the [seek()] pipeline, applied after [list_files()]
#' and before [match_files()].
#'
#' Exclusion filters are applied in this order:
#' 1. `extension`: keeps only files whose extension is in the provided list.
#' 2. `path_pattern`: keeps files whose normalized path matches the pattern.
#' 3. `max_file_size`: excludes files larger than the given size.
#' 4. [`exclude_functions`]: applies each named function to the remaining files.
#'
#' Files are only passed to each subsequent filter if they have not already been
#' excluded by a previous one.
#'
#' Details about excluded files are stored on the result and can be retrieved
#' with [exclusions()].
#'
#' @param path A character vector of file paths to filter.
#'
#' @inheritParams seek
#'
#' @return
#' A character vector of normalized absolute paths that passed all filters.
#' Paths use the same representation as [as_seekr_path()].
#'
#' An attribute `"exclusions"` is always attached to the result, containing
#' a data frame with one row per input file and one column per exclusion function,
#' detailing which files were excluded and why. Retrieve it with [exclusions()].
#'
#' @seealso
#' - [list_files()] to produce the input paths.
#' - [match_files()] to search the filtered files for a pattern.
#' - [exclusions()] to inspect which files were removed and why.
#' - [seek()] to run the full pipeline.
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' files <- list_files(path = ext_path)
#'
#' # Keep only R files
#' filter_files(files, extension = "R")
#'
#' Keep only script files
#' filter_files(files, path_pattern = "script")
#'
#' # Exclude files larger than 1 MB
#' filter_files(files, max_file_size = fs::fs_bytes("1MB"))
#'
#' # Inspect which files were excluded and why
#' filtered <- filter_files(files, extension = "R")
#' exclusions(filtered)
#'
#' # Disable default exclude functions
#' filter_files(files, exclude = NULL)
#'
#' # Add a custom exclude function
#' my_fns <- exclude_functions
#' my_fns$generated <- function(path) grepl("/generated/", path)
#' filter_files(files, exclude = my_fns)
#'
#' @export
filter_files = function(
  path,
  ...,
  extension = NULL,
  path_pattern = NULL,
  max_file_size = Inf,
  exclude = seekr::exclude_functions,
  .progress = seekr_option("seekr.progress")
) {
  rlang::check_dots_empty()

  assert_paths(path)
  assert_extension(extension)
  assert_pattern(path_pattern, null_ok = TRUE)
  assert_max_file_size(max_file_size)
  assert_exclude(exclude)
  assert_flag(.progress)
  path = normalize_path(path)
  extension = normalize_extension(extension)
  max_file_size = normalize_max_file_size(max_file_size)

  exclusion_functions = create_exclusion_functions(
    extension = extension,
    path_pattern = path_pattern,
    max_file_size = max_file_size,
    exclude = exclude
  )

  df = create_empty_exclusion_details_df(path, exclusion_functions)
  exclusion_names = names(exclusion_functions)

  if (.progress) {
    i = 1
    cli::cli_progress_step(
      msg = "Filter files ({exclusion_names[[i]]}): {sum(!df$excluded)} file{?s}",
      msg_done = "Filter files: {sum(!df$excluded)} file{?s}",
      spinner = TRUE
    )
  }

  if (rlang::is_empty(path)) {
    files = structure(character(), exclusions = df)
    return(files)
  }

  for (i in seq_along(exclusion_functions)) {
    if (.progress) {
      cli::cli_progress_update()
    }

    exclusion_name = exclusion_names[[i]]
    exclusion_function = exclusion_functions[[i]]

    active = !df$excluded
    fn_excluded = exclusion_function(path[active])

    assert_exclude_function_return(
      x = fn_excluded,
      len = sum(active),
      arg = exclusion_name
    )

    df[[exclusion_name]][active] = fn_excluded
    df$excluded[active] = fn_excluded
  }

  files = structure(as.character(path[!df$excluded]), exclusions = df)
  return(files)
}


#' @keywords internal
create_empty_exclusion_details_df = function(path, exclusion_functions) {
  df = tibble::tibble(path = path, excluded = FALSE)

  for (name in names(exclusion_functions)) {
    df[[name]] = NA
  }

  return(df)
}


#' @keywords internal
create_exclusion_functions = function(
  extension,
  path_pattern,
  max_file_size,
  exclude
) {
  exclude_by_extension = NULL
  exclude_by_path_pattern = NULL
  exclude_by_file_size = NULL

  if (!is.null(extension)) {
    exclude_by_extension = ff_exclude_by_extension(extension)
  }

  if (!is.null(path_pattern)) {
    exclude_by_path_pattern = ff_exclude_by_path_pattern(path_pattern)
  }

  if (!is.infinite(max_file_size)) {
    exclude_by_file_size = ff_exclude_by_file_size(max_file_size)
  }

  c(
    exclude_by_extension = exclude_by_extension,
    exclude_by_path_pattern = exclude_by_path_pattern,
    exclude_by_file_size = exclude_by_file_size,
    exclude
  )
}


#' @keywords internal
ff_exclude_by_path_pattern = function(path_pattern) {
  force(path_pattern)

  function(path) {
    !stringr::str_detect(path, path_pattern)
  }
}


#' @keywords internal
ff_exclude_by_extension = function(extension) {
  force(extension)

  function(path) {
    path_ext = extract_lower_file_extension(path)
    !path_ext %in% extension
  }
}


#' @keywords internal
ff_exclude_by_file_size = function(max_file_size) {
  force(max_file_size)

  function(path) {
    size = seekr_file_info(path)$size
    !is.na(size) & size > max_file_size
  }
}


#' @rdname exclude_functions
#' @order 2
#' @export
is_git_dir = function(path) {
  stringr::str_detect(path, "(?i)/\\.git/")
}


#' @rdname exclude_functions
#' @order 3
#' @export
is_dependency_dir = function(path) {
  dirs_to_exclude = c(
    "\\.Rproj\\.user",
    "node_modules",
    "vendor",
    "renv",
    "packrat",
    "\\.venv",
    "\\.vscode",
    "__pycache__"
  )

  pattern = stringr::str_c(dirs_to_exclude, collapse = "|")
  pattern = glue::glue("(?<=/)({pattern})(?=/)")
  stringr::str_detect(path, pattern)
}


#' @rdname exclude_functions
#' @order 4
#' @export
is_minified_file = function(path) {
  minified_pattern = "(?i)\\.(min|bundle)\\.(js|js\\.map|css|html)$"
  stringr::str_detect(path, minified_pattern)
}


#' @rdname exclude_functions
#' @order 5
#' @export
is_not_text_mime = function(path) {
  other_text_mime = c(
    "application/json",
    "application/manifest+json",
    "application/yaml",
    "application/sql",
    "application/xml",
    "application/atom+xml",
    "application/clue_info+xml",
    "application/javascript",
    "application/oebps-package+xml",
    "application/provenance+xml",
    "application/rdf+xml",
    "application/sparql-results+xml",
    "application/tei+xml",
    "application/ttml+xml",
    "application/vnd.openblox.game+xml",
    "application/vnd.openstreetmap.data+xml",
    "application/x-csh",
    "application/x-latex",
    "application/x-rss+xml",
    "application/x-sh",
    "application/xhtml+xml",
    "application/xslt+xml"
  )

  base_mime = mime::guess_type(
    file = path,
    unknown = "text/plain",
    empty = "text/plain"
  )

  text_mime = stringr::str_detect(base_mime, "text") | base_mime %in% other_text_mime

  return(!text_mime)
}


#' Default file exclusion functions
#'
#' @description
#' `exclude_functions` is the default named list of functions used by
#' [filter_files()] to exclude files that are usually not useful for text search.
#'
#' @inheritParams filter_files
#'
#' @details
#' Each function receives a character vector of normalized file paths and must
#' return a logical vector of the same length. `TRUE` means that the
#' corresponding file should be excluded.
#'
#' The default pipeline includes:
#' - `is_git_dir()`: excludes files located inside `.git/`.
#' - `is_dependency_dir()`: excludes files in common dependency folders such as
#'   `node_modules/`, `renv/`, `.venv/`, `vendor/`, and `__pycache__/`.
#' - `is_minified_file()`: excludes minified or bundled files such as `.min.js`,
#'   `.bundle.css`, etc.
#' - `is_not_text_mime()`: excludes files not recognized as text based on their
#'   MIME type.
#'
#' You can disable all exclude functions with `exclude = NULL`, remove
#' one of the defaults by setting it to `NULL` in a copy of
#' [exclude_functions], or add your own named function to the list.
#'
#' @format
#' A named list of exclude functions.
#'
#' @seealso [filter_files()]
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' files <- list_files(path = ext_path)
#' names(exclude_functions)
#'
#' # Disable default exclude functions
#' filter_files(files, exclude = NULL)
#'
#' # Add a custom exclude function
#' my_fns <- exclude_functions
#' my_fns$generated <- function(path) grepl("/generated/", path)
#' filter_files(files, exclude = my_fns)
#'
#' @rdname exclude_functions
#' @order 1
#' @export
exclude_functions = list(
  is_git_dir = is_git_dir,
  is_dependency_dir = is_dependency_dir,
  is_minified_file = is_minified_file,
  is_not_text_mime = is_not_text_mime
)


#' Inspect why files were excluded
#'
#' @description
#' `exclusions()` retrieves the exclusion details stored on objects returned by
#' [filter_files()], [seek()], and [seekr()].
#'
#' @param x An object containing exclusion details, typically the result of
#' [filter_files()], [seek()], or [seekr()].
#'
#' @return
#' A data frame with one row per input file and one column per exclusion filter,
#' describing which files were excluded and why. If no exclusion details are
#' available, returns `NULL`.
#'
#' @seealso
#' [filter_files()] for the filtering step, [exclude_functions] for the default
#' exclude-function pipeline.
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#' files <- list_files(path = ext_path)
#' filtered <- filter_files(files, extension = "R")
#' exclusions(filtered)
#'
#' @export
exclusions = function(x) {
  attr(x, "exclusions", exact = TRUE)
}


#' @keywords internal
extract_lower_file_extension = function(path) {
  stringr::str_to_lower(fs::path_ext(path))
}


#' @keywords internal
seekr_file_info = function(path) {
  suppressWarnings({
    fs::file_info(path, fail = FALSE, follow = FALSE)
  })
}
