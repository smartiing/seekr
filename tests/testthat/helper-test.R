filtering_files = function() {
  list_files(
    path = test_path("fixtures", "filtering"),
    recurse = TRUE,
    .progress = FALSE
  )
}

create_test_backup = function(
  files,
  backup_dir,
  operation = sample(c("replace", "restore"), size = 1L),
  description = NA_character_
) {
  create_backup(files, operation, description, backup_dir)
}
