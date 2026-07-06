# list-files.R -----------------------------------------------------------

#' List files to search
#'
#' @description
#' [list_files()] starts from `path` and lists candidate files. It can recurse
#' into subdirectories with `recurse`, include hidden files and directories with
#' `all`, and optionally restrict discovery inside Git repositories with
#' `use_git`. It is the first step of the [`seek()`] pipeline.
#'
#' Listing is intentionally simple: it does not know about patterns, extensions,
#' file sizes, or MIME types. Its only job is to turn directories into a
#' character vector of file paths. Filtering happens in the next step,
#' [filter_files()].
#'
#' If `use_git = TRUE`, Git is used for each input path independently.
#' For each path, [list_files()] asks Git whether that path is inside a Git
#' repository. If it is, [list_files()] finds the repository root by walking
#' upward from that path, then keeps only the files also returned by
#' `git ls-files --cached --others --exclude-standard` for that repository.
#'
#' Git is used to restrict the files discovered from the input path. It does not
#' expand the search. The `path`, `recurse`, and `all` arguments still define the
#' initial candidate files. For example, Git-tracked hidden files are not
#' returned unless `all = TRUE`, and Git-tracked files below the requested
#' recursion depth are not returned.
#'
#' [list_files()] does not search downward for nested Git repositories. If an
#' input path is not inside a Git repository, it is listed normally, even if it
#' contains Git repositories in subdirectories. If you want Git-aware discovery
#' for nested repositories, pass those repository directories explicitly in
#' `path`.
#'
#' If `use_git = TRUE`, Git must be installed and available on `PATH`.
#'
#' The returned paths are normalized as described in [as_seekr_path()].
#'
#' @inheritParams seek
#'
#' @return A character vector of normalized absolute file paths. Returns an
#'   empty character vector if no files are found or if `path` is empty.
#'
#' @seealso
#' - [filter_files()] to filter the listed files before searching matches.
#' - [seek()] to run the full listing, filtering, and matching pipeline.
#'
#' @examples
#' ext_path <- system.file("extdata", package = "seekr")
#'
#' # List all files in the example directory
#' list_files(path = ext_path)
#'
#' # List only files at the top level, without recursing
#' list_files(path = ext_path, recurse = FALSE)
#'
#' # Recurse at most 2 levels deep
#' list_files(path = ext_path, recurse = 2L)
#'
#' # Include hidden files and directories
#' list_files(path = ext_path, all = TRUE)
#'
#' \dontrun{
#' # Use Git to restrict discovery inside Git repositories
#' list_files(path = ".", use_git = TRUE)
#' }
#'
#' @export
list_files = function(
  path = ".",
  ...,
  recurse = TRUE,
  all = FALSE,
  use_git = FALSE,
  .progress = seekr_option("seekr.progress")
) {
  rlang::check_dots_empty()
  assert_path_list_files(path)
  assert_recurse(recurse)
  assert_flag(all)
  assert_flag(use_git)
  if (use_git) assert_git_available()
  assert_flag(.progress)

  path = normalize_path(path, deduplicate = TRUE)

  if (.progress) {
    files = character()
    cli::cli_progress_step(
      msg = "List files",
      msg_done = "List files: {length(files)} file{?s}"
    )
  }

  if (rlang::is_empty(path)) {
    return(character())
  }

  files = purrr::map(path, \(path) seekr_dir_ls(path, recurse, all))

  if (use_git) {
    roots = purrr::map_chr(path, find_git_root)
    unique_roots = unique(roots[!is.na(roots)])
    git_files_by_root = purrr::map(unique_roots, git_ls_files)
    names(git_files_by_root) = unique_roots

    for (i in seq_along(roots)) {
      if (!is.na(roots[[i]])) {
        files[[i]] = files[[i]][files[[i]] %in% git_files_by_root[[roots[[i]]]]]
      }
    }
  }

  files = unlist(files, use.names = FALSE)
  files = normalize_path(files, deduplicate = TRUE)

  return(files)
}


#' @keywords internal
seekr_dir_ls = function(path, recurse, all) {
  files = tryCatch(
    fs::dir_ls(
      path = path,
      recurse = recurse,
      all = all,
      type = "file",
      glob = NULL,
      regexp = NULL,
      invert = FALSE,
      fail = TRUE
    ),
    error = function(cnd) {
      cli::cli_abort(
        c(
          "Cannot list files in {.arg path}.",
          "x" = "One or more directories could not be listed.",
          "i" = "The directory may have been deleted, moved, or become unreadable."
        ),
        class = "seekr_error_list_files",
        call = quote(list_files())
      )
    }
  )

  normalize_path(files, deduplicate = FALSE)
}


#' @keywords internal
find_git_root = function(path) {
  res = processx::run(
    command = "git",
    args = c(
      "-C", path,
      "rev-parse",
      "--show-toplevel"
    ),
    error_on_status = FALSE,
    echo = FALSE
  )

  if (res$status != 0L) {
    return(NA_character_)
  }

  root = trimws(res$stdout)

  if (!nzchar(root)) {
    return(NA_character_)
  }

  normalize_path(root, deduplicate = FALSE)
}


#' @keywords internal
git_ls_files = function(root) {
  if (is.na(root)) {
    return(character())
  }

  res = processx::run(
    command = "git",
    args = c(
      "-C", root,
      "ls-files",
      "--cached",
      "--others",
      "--exclude-standard"
    ),
    error_on_status = FALSE,
    echo = FALSE
  )

  if (res$status != 0L) {
    cli::cli_abort(
      c(
        "Cannot list files with Git.",
        "x" = "Git failed while listing files in {.path {root}}.",
        "i" = "Try running {.code git ls-files --cached --others --exclude-standard} in that repository."
      ),
      class = "seekr_error_git_list_files",
      call = quote(list_files())
    )
  }

  git_files = split_at_newlines(res$stdout)[[1]]
  git_files = git_files[nzchar(git_files)]

  if (length(git_files) == 0L) {
    return(character())
  }

  normalize_path(file.path(root, git_files), deduplicate = TRUE)
}

