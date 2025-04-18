seek = function(
  pattern,
  path = ".",
  file_pattern = NULL,
  recursive = FALSE,
  all.files = FALSE,
  warn = FALSE,
  relative_path = TRUE
) {
  checkmate::assert_string(pattern)
  checkmate::assert_directory_exists(path)
  checkmate::assert_string(file_pattern, null.ok = TRUE)
  checkmate::assert_flag(recursive)
  checkmate::assert_flag(all.files)
  checkmate::assert_flag(warn)
  checkmate::assert_flag(relative_path)

  path = normalizePath(path, winslash = "/")
  files = list_matching_files(path, recursive, file_pattern, all.files)
  df = process_files_lines(files, pattern, warn)

  if (relative_path) {
    df$path = sub(path, "", df$path)
  }

  return(df)
}


seek_in = function(
  pattern,
  files,
  warn = FALSE
) {
  checkmate::assert_string(pattern)
  checkmate::assert_character(files, any.missing = FALSE, min.len = 1)
  checkmate::assert_flag(warn)

  df = process_files_lines(files, pattern, warn)

  return(df)
}


process_files_lines = function(files, pattern, warn) {
  df = parse_files_to_df(files, warn)
  df = filter_matching_lines(df, pattern)
  df = add_matches_columns(df, pattern)

  df = df[, c("file", "path", "line", "content", "match", "matches")]

  return(df)
}
