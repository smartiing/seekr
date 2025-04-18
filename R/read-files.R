parse_files_to_df = function(files, warn) {
  content = mapply(readLines_safe, files, warn)
  dfs = mapply(create_file_df, seq_along(files), files, content, SIMPLIFY = FALSE)
  df = Reduce(rbind, dfs)

  df = tibble::as_tibble(df)

  return(df)
}


readLines_safe = function(file, warn) {
  tryCatch(
    expr = {
      readLines(file, warn = warn)
    },
    error = function(e) {
      NULL
    }
  )
}


create_file_df = function(file_number, path, file_content) {
  if (is.null(file_content) || length(file_content) == 0L) {
    df = data.frame(
      file = file_number,
      path = path,
      line = 0L,
      content = NA_character_
    )
  } else {
    df = data.frame(
      file = file_number,
      path = path,
      line = seq_along(file_content),
      content = file_content
    )
  }

  return(df)
}
