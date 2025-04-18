filter_matching_lines = function(df, pattern) {
  df$content = iconv(df$content, from = "", to = "UTF-8", sub = "byte")
  df = df[grepl(pattern, df$content, perl = TRUE), ]

  return(df)
}


add_matches_columns = function(df, pattern) {
  df$matches = regmatches(df$content, gregexpr(pattern, df$content, perl = TRUE))
  df$match = unlist(lapply(df$matches, \(x) x[[1]]))

  return(df)
}


reorder_columns = function(df) {
  df = df[, c("file", "path", "line", "content", "match", "matches")]

  return(df)
}
