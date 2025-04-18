list_matching_files = function(path, recursive, file_pattern, all.files) {
  files = list_files(path, recursive, all.files)

  if (!is.null(file_pattern)) {
    files = filter_matching_files(files, file_pattern)
  }

  return(files)
}


list_files = function(path, recursive, all.files) {
  files = list.files(
    path = path,
    pattern = NULL,
    all.files = all.files,
    full.names = TRUE,
    recursive = recursive,
    ignore.case = FALSE,
    include.dirs = FALSE,
    no.. = FALSE
  )

  if (length(files) == 0L) {
    cli::cli_abort(c(
      "!" = "No files found in {.path {path}}.",
      "i" = "Check the folder path or set {.code recursive = TRUE} if needed."
    ))
  }

  return(normalizePath(files, winslash = "/"))
}


filter_matching_files = function(files, file_pattern) {
  files = files[grepl(file_pattern, files, perl = TRUE)]

  if (length(files) == 0L) {
    cli::cli_abort(c(
      "!" = "No files matched the pattern {.val {file_pattern}}.",
      "i" = "Try a different {.code file_pattern} or check that the files exist."
    ))
  }

  return(files)
}
