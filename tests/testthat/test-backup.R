# list_backups() ----------------------------------------------------------

test_that("list_backups() validates its argument", {
  dirs = c(withr::local_tempdir(), withr::local_tempdir())
  expect_error(list_backups(dirs), class = "seekr_error_length")
})

test_that("list_backups() returns empty tibble with correct columns when no backups exist", {
  dir = withr::local_tempdir()
  result = list_backups(backup_dir = dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
  expect_named(
    result,
    c("id", "created_at", "operation", "description", "original", "backup",
      "original_exists", "backup_exists", "size")
  )
})

test_that("list_backups() returns empty tibble for non-existent backup_dir", {
  result = list_backups(backup_dir = file.path(withr::local_tempdir(), "does_not_exist"))
  expect_equal(nrow(result), 0L)
})

test_that("list_backups() returns one row per backed-up file", {
  dir = withr::local_tempdir()

  files = character(2)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = "lines")
  }

  create_test_backup(files, dir)
  result = list_backups(backup_dir = dir)
  expect_equal(nrow(result), 2L)

  create_test_backup(files, dir)
  result = list_backups(backup_dir = dir)
  expect_equal(nrow(result), 4L)

  expect_equal(result$id, c(2L, 2L, 1L, 1L))
})

test_that("list_backups() returns rows for all backups when multiple exist", {
  dir = withr::local_tempdir()

  files = character(3)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = "lines")
  }
  create_test_backup(files[1], dir)
  create_test_backup(files[1:2], dir)
  create_test_backup(files[1:3], dir)
  result = list_backups(backup_dir = dir)
  expect_equal(nrow(result), 6L)
  expect_equal(result$id, c(3L, 3L, 3L, 2L, 2L, 1L))
})

test_that("list_backups() includes a size column with fs_bytes values", {
  dir = withr::local_tempdir()

  files = character(1)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = "lines")
  }
  create_test_backup(files, dir)
  result = list_backups(backup_dir = dir)
  expect_s3_class(result$size, "fs_bytes")
  expect_true(all(result$size > 0))
})

test_that("list_backups() ignores subdirs with non-6-digit names", {
  dir = withr::local_tempdir()
  fs::dir_create(file.path(dir, "not_backup"))

  files = character(1)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = "lines")
  }

  create_test_backup(files, dir)
  result = list_backups(backup_dir = dir)
  expect_equal(nrow(result), 1L)
})

test_that("list_backups() has correct column types", {
  dir = withr::local_tempdir()
  fs::dir_create(file.path(dir, "not_backup"))

  files = character(3)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = "lines")
  }

  create_test_backup(files, dir)
  result = list_backups(backup_dir = dir)
  expect_type(result$id, "integer")
  expect_s3_class(result$created_at, "POSIXct")
  expect_type(result$operation, "character")
  expect_type(result$description, "character")
  expect_type(result$original, "character")
  expect_type(result$backup, "character")
  expect_type(result$original_exists, "logical")
  expect_type(result$backup_exists, "logical")
})

test_that("list_backups() ignores malformed backups and returns valid backups", {
  dir = withr::local_tempdir()

  files = character(1)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = "lines")
  }

  create_test_backup(files, dir)

  bad_subdir = file.path(dir, "000002")
  fs::dir_create(bad_subdir)
  writeLines("not an rds", file.path(bad_subdir, "backup.RDS"))

  expect_warning(
    {
      result = list_backups(backup_dir = dir)
    },
    regexp = "could not be read",
    class = "seekr_warning_corrupt_backup_metadata"
  )

  expect_equal(nrow(result), 1L)
  expect_equal(result$id, 1L)
})


# last_backup() -----------------------------------------------------------

test_that("last_backup() validates its argument", {
  dirs = c(withr::local_tempdir(), withr::local_tempdir())
  expect_error(last_backup(dirs), class = "seekr_error_length")
})

test_that("last_backup() returns empty tibble when no backups exist", {
  dir = withr::local_tempdir()

  result = last_backup(backup_dir = dir)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
  expect_named(
    result,
    c(
      "id", "created_at", "operation", "description",
      "original", "backup", "original_exists", "backup_exists", "size"
    )
  )
})

test_that("last_backup() returns only the most recent backup", {
  dir = withr::local_tempdir()

  files = character(3)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = paste0("line ", i))
  }

  create_test_backup(files[1], dir, operation = "replace", description = "first")
  create_test_backup(files[1:2], dir, operation = "restore", description = "second")
  create_test_backup(files[1:3], dir, operation = "replace", description = "third")

  result = last_backup(backup_dir = dir)

  expect_equal(nrow(result), 3L)
  expect_equal(unique(result$id), 3L)
  expect_true(all(result$description == "third"))
})


# delete_backups() --------------------------------------------------------

test_that("delete_backups() rejects non-empty dots", {
  dir = withr::local_tempdir()

  expect_error(delete_backups(1L, foo = 1, backup_dir = dir, .progress = FALSE))
  expect_error(delete_backups(1L, 1L, backup_dir = dir, .progress = FALSE))
})

test_that("delete_backups() validates its arguments", {
  dir = withr::local_tempdir()

  expect_error(delete_backups(NA_integer_, backup_dir = dir, .progress = FALSE), class = "seekr_error_na")
  expect_error(delete_backups(1.5, backup_dir = dir, .progress = FALSE), class = "seekr_error_integerish")
  expect_error(delete_backups(1L, backup_dir = c(dir, dir), .progress = FALSE), class = "seekr_error_length")
  expect_error(delete_backups(1L, backup_dir = dir, .progress = NA), class = "seekr_error_na")
})

test_that("delete_backups() deletes selected ids and ignores duplicates and unknown ids", {
  dir = withr::local_tempdir()

  files = character(2)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = paste0("line ", i))
  }

  create_test_backup(files[1], dir)
  create_test_backup(files[2], dir)

  result = delete_backups(c(1L, 1L, 99L), backup_dir = dir, .progress = FALSE)

  expect_equal(basename(result), "000001")
  expect_false(fs::dir_exists(file.path(dir, "000001")))
  expect_true(fs::dir_exists(file.path(dir, "000002")))

  remaining = list_backups(backup_dir = dir)
  expect_equal(nrow(remaining), 1L)
  expect_equal(unique(remaining$id), 2L)
})

test_that("delete_backups() returns empty character when no ids match", {
  dir = withr::local_tempdir()

  files = character(1)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = "lines")
  }

  create_test_backup(files, dir)

  result = delete_backups(99L, backup_dir = dir, .progress = FALSE)

  expect_type(result, "character")
  expect_length(result, 0L)
  expect_true(fs::dir_exists(file.path(dir, "000001")))
})

test_that("delete_backups() supports progress output", {
  withr::local_message_sink(nullfile())
  dir = withr::local_tempdir()

  files = character(1)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = "lines")
  }

  create_test_backup(files, dir)
  expect_no_error(delete_backups(1L, backup_dir = dir, .progress = TRUE))
})


# open_backup_dir() -------------------------------------------------------

test_that("open_backup_dir() creates and opens the current default backup directory", {
  root = withr::local_tempdir()
  dir = file.path(root, "backup")
  withr::local_options(list(seekr.backup_dir = dir))

  local_mocked_bindings(
    file_show = function(path, ...) invisible(path),
    .package = "fs"
  )

  expect_false(fs::dir_exists(dir))
  result = open_backup_dir()
  expect_true(fs::dir_exists(dir))
  expect_equal(result, dir)
})


# create_backup() ---------------------------------------------------------

test_that("create_backup() returns empty character for empty input", {
  dir = withr::local_tempdir()

  result = create_backup(
    files = character(),
    operation = "replace",
    description = NA_character_,
    backup_dir = dir
  )

  expect_type(result, "character")
  expect_length(result, 0L)
  expect_length(list_backup_subdirs(dir), 0L)
})

test_that("create_backup() creates a numbered backup directory", {
  dir = withr::local_tempdir()

  files = character(2)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = paste0("line ", i))
  }

  result = create_test_backup(files, dir)

  expect_true(fs::dir_exists(result))
  expect_equal(basename(result), "000001")
  expect_true(fs::file_exists(file.path(result, "backup.RDS")))
})

test_that("create_backup() writes metadata and copies files", {
  dir = withr::local_tempdir()

  files = character(2)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = paste0("line ", i))
  }

  subdir = create_test_backup(files, dir, operation = "restore", description = "metadata")
  metadata = readRDS(file.path(subdir, "backup.RDS"))

  expect_named(metadata, c("created_at", "operation", "description", "original", "backup"))
  expect_s3_class(metadata$created_at, "POSIXct")
  expect_equal(metadata$operation, rep("restore", 2L))
  expect_equal(metadata$description, rep("metadata", 2L))
  expect_equal(metadata$original, normalize_path(files))
  expect_equal(metadata$backup, create_backup_file_name(files))
  expect_true(all(fs::file_exists(file.path(subdir, metadata$backup))))
})

test_that("create_backup() deduplicates normalized file paths", {
  dir = withr::local_tempdir()
  file = withr::local_tempfile(lines = "line")

  subdir = create_test_backup(c(file, file), dir)
  metadata = readRDS(file.path(subdir, "backup.RDS"))

  expect_equal(nrow(metadata), 1L)
})

test_that("create_backup() removes partial backup directory when copy fails", {
  dir = withr::local_tempdir()
  file = withr::local_tempfile(lines = "line")

  local_mocked_bindings(
    file_copy = function(...) {
      stop("copy failed")
    },
    .package = "fs"
  )

  expect_error(
    seekr:::create_backup(
      files = file,
      operation = "replace",
      description = NA_character_,
      backup_dir = dir
    ),
    regexp = "copy failed"
  )

  expect_length(list_backup_subdirs(dir), 0L)
})


# create_backup_subdir() --------------------------------------------------

test_that("create_backup_subdir() creates the first backup subdir", {
  dir = withr::local_tempdir()

  result = create_backup_subdir(dir)

  expect_true(fs::dir_exists(result))
  expect_equal(basename(result), "000001")
})

test_that("create_backup_subdir() creates sequential backup subdirs", {
  dir = withr::local_tempdir()

  first = create_backup_subdir(dir)
  second = create_backup_subdir(dir)

  expect_equal(basename(first), "000001")
  expect_equal(basename(second), "000002")
})

test_that("create_backup_subdir() retries when the first candidate already exists", {
  dir = withr::local_tempdir()
  fs::dir_create(file.path(dir, "000001"))

  local_mocked_bindings(
    list_backup_subdirs = function(backup_dir) character()
  )

  result = create_backup_subdir(dir)

  expect_true(fs::dir_exists(result))
  expect_equal(basename(result), "000002")
})

test_that("create_backup_subdir() errors when backup ids are exhausted", {
  dir = withr::local_tempdir()
  fs::dir_create(file.path(dir, "999999"))

  expect_error(
    create_backup_subdir(dir),
    class = "seekr_error_create_backup_subdir_max_id"
  )
})

test_that("create_backup_subdir() errors after repeated concurrent collisions", {
  dir = withr::local_tempdir()

  for (i in 1:10) {
    fs::dir_create(file.path(dir, pad_id(i, width = 6L)))
  }

  local_mocked_bindings(
    list_backup_subdirs = function(backup_dir) character()
  )

  expect_error(
    create_backup_subdir(dir),
    class = "seekr_error_create_backup_subdir_concurrency"
  )
})


# create_backup_dir() -----------------------------------------------------

test_that("create_backup_dir() creates nested directories", {
  dir = file.path(withr::local_tempdir(), "nested", "backup")

  result = create_backup_dir(dir)

  expect_true(fs::dir_exists(dir))
  expect_equal(as.character(result), normalize_path(dir))
})

test_that("create_backup_dir() wraps directory creation errors", {
  local_mocked_bindings(
    dir_create = function(...) stop("cannot create"),
    .package = "fs"
  )

  expect_error(
    create_backup_dir(file.path(withr::local_tempdir(), "backup")),
    class = "seekr_error_create_backup_dir"
  )
})

# create_backup_file_name() -----------------------------------------------

test_that("create_backup_file_name() prefixes basenames with padded ids", {
  files = file.path("some", "dir", c("a.txt", "b.txt", "c.txt"))
  result = create_backup_file_name(files)

  expect_equal(result, c("01_a.txt", "02_b.txt", "03_c.txt"))
})

test_that("create_backup_file_name() uses enough padding for many files", {
  files = file.path("dir", paste0("file", seq_len(100), ".txt"))

  result = create_backup_file_name(files)

  expect_equal(result[[1]], "001_file1.txt")
  expect_equal(result[[100]], "100_file100.txt")
})

# pad_id() ----------------------------------------------------------------

test_that("pad_id() left-pads ids with zeroes", {
  expect_equal(pad_id(1L, width = 6L), "000001")
  expect_equal(pad_id(12L, width = 3L), "012")
  expect_equal(pad_id(c(1L, 12L), width = 3L), c("001", "012"))
})

# read_backup() -----------------------------------------------------------

test_that("read_backup() reads a valid backup directory", {
  dir = withr::local_tempdir()

  files = character(2)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = paste0("line ", i))
  }

  subdir = create_test_backup(files, dir, operation = "replace", description = "read")
  metadata = readRDS(file.path(subdir, "backup.RDS"))
  result = read_backup(subdir)

  expect_named(result, names(empty_backup_table()))
  expect_equal(result$id, c(1L, 1L))
  expect_equal(result$operation, rep("replace", 2L))
  expect_equal(result$description, rep("read", 2L))
  expect_equal(result$original, metadata$original)
  expect_equal(result$backup, file.path(subdir, metadata$backup))
  expect_true(all(result$original_exists))
  expect_true(all(result$backup_exists))
})

test_that("read_backup() warns and returns empty table when metadata is missing", {
  dir = withr::local_tempdir()
  subdir = file.path(dir, "000001")
  fs::dir_create(subdir)

  expect_warning(
    {result = read_backup(subdir)},
    class = "seekr_warning_missing_backup_metadata"
  )

  expect_identical(result, empty_backup_table())
})

test_that("read_backup() warns and returns empty table when metadata cannot be read", {
  dir = withr::local_tempdir()
  subdir = file.path(dir, "000001")
  fs::dir_create(subdir)
  writeLines("not an rds", file.path(subdir, "backup.RDS"))

  expect_warning(
    {result = read_backup(subdir)},
    class = "seekr_warning_corrupt_backup_metadata"
  )

  expect_identical(result, empty_backup_table())
})

test_that("read_backup() warns and returns empty table when metadata is not a data frame", {
  dir = withr::local_tempdir()
  subdir = file.path(dir, "000001")
  fs::dir_create(subdir)
  saveRDS(list(a = 1), file.path(subdir, "backup.RDS"))

  expect_warning(
    {result = read_backup(subdir)},
    class = "seekr_warning_metadata_not_df"
  )

  expect_identical(result, empty_backup_table())
})

test_that("read_backup() warns and returns empty table when metadata misses required columns", {
  dir = withr::local_tempdir()
  subdir = file.path(dir, "000001")
  fs::dir_create(subdir)
  saveRDS(tibble::tibble(created_at = Sys.time()), file.path(subdir, "backup.RDS"))

  expect_warning(
    {result = read_backup(subdir)},
    class = "seekr_warning_metadata_missing_columns"
  )

  expect_identical(result, empty_backup_table())
})

test_that("read_backup() warns and returns empty table when metadata has invalid column types", {
  dir = withr::local_tempdir()
  subdir = file.path(dir, "000001")
  fs::dir_create(subdir)

  metadata = tibble::tibble(
    created_at = TRUE,
    operation = TRUE,
    description = TRUE,
    original = TRUE,
    backup = TRUE
  )

  saveRDS(metadata, file.path(subdir, "backup.RDS"))

  expect_warning(
    {result = read_backup(subdir)},
    class = "seekr_warning_metadata_invalid_columns"
  )

  expect_identical(result, empty_backup_table())
})

test_that("read_backup() warns when referenced backup files are missing", {
  dir = withr::local_tempdir()

  files = character(2)
  for (i in seq_along(files)) {
    files[[i]] = withr::local_tempfile(lines = paste0("line ", i))
  }

  subdir = create_test_backup(files, dir)
  metadata = readRDS(file.path(subdir, "backup.RDS"))
  fs::file_delete(file.path(subdir, metadata$backup[[2]]))

  expect_warning(
    {result = read_backup(subdir)},
    class = "seekr_warning_missing_backup_files"
  )

  expect_equal(unname(result$backup_exists), c(TRUE, FALSE))
  expect_true(all(result$original_exists))
})

# list_backup_subdirs() ---------------------------------------------------

test_that("list_backup_subdirs() returns empty character for non-existent backup_dir", {
  dir = file.path(withr::local_tempdir(), "does_not_exist")
  result = list_backup_subdirs(dir)

  expect_type(result, "character")
  expect_length(result, 0L)
})

test_that("list_backup_subdirs() returns only six-digit backup directories in decreasing order", {
  dir = withr::local_tempdir()

  fs::dir_create(file.path(dir, "000001"))
  fs::dir_create(file.path(dir, "000003"))
  fs::dir_create(file.path(dir, "000002"))
  fs::dir_create(file.path(dir, "not_backup"))
  fs::file_create(file.path(dir, "000004"))

  result = list_backup_subdirs(dir)

  expect_equal(basename(result), c("000003", "000002", "000001"))
})

# empty_backup_table() ----------------------------------------------------

test_that("empty_backup_table() returns an empty tibble with correct columns and types", {
  result = empty_backup_table()

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
  expect_named(
    result,
    c(
      "id", "created_at", "operation", "description",
      "original", "backup", "original_exists", "backup_exists", "size"
    )
  )
  expect_type(result$id, "integer")
  expect_s3_class(result$created_at, "POSIXct")
  expect_type(result$operation, "character")
  expect_type(result$description, "character")
  expect_type(result$original, "character")
  expect_type(result$backup, "character")
  expect_type(result$original_exists, "logical")
  expect_type(result$backup_exists, "logical")
  expect_s3_class(result$size, "fs_bytes")
})
