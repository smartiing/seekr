# filter_files -------------------------------------------------------------

test_that("filter_files() filters files correctly given extensions", {
  tmp = withr::local_tempdir()
  file1 = file.path(tmp, "script.R")
  file2 = file.path(tmp, "image.png")
  file3 = file.path(tmp, "data.csv")
  file4 = file.path(tmp, "filename")
  writeLines("print('hello')", file1)
  writeBin(as.raw(0:255), file2)
  writeLines("col1,col2", file3)
  writeLines("blabla", file4)

  files = c(file1, file2, file3, file4)
  result = filter_files(files, filter = NULL)

  expect_true(file1 %in% result)
  expect_false(file2 %in% result) # PNG should be excluded
  expect_true(file3 %in% result)
  expect_true(file4 %in% result)
})


test_that("filter_files() throws error if no text files found", {
  local_mocked_bindings(print_cli = function() TRUE)
  local_mocked_bindings(
    cli_progress_step = function(...) invisible(),
    .package = "cli"
  )

  tmp = withr::local_tempdir()
  file1 = file.path(tmp, "photo.png")
  writeBin(as.raw(0:255), file1)

  expect_error(filter_files(file1, filter = NULL))
})


test_that("filter_files() throws a different error if a filter is provided", {
  tmp = withr::local_tempdir()
  file1 = file.path(tmp, "photo.png")
  writeBin(as.raw(0:255), file1)

  expect_error(filter_files(file1, filter = "\\.txt$"))
})


test_that("filter_files() filters based on pattern", {
  tmp = withr::local_tempdir()
  file1 = file.path(tmp, "notes.txt")
  file2 = file.path(tmp, "todo.md")
  file3 = file.path(tmp, "todo.csv")
  writeLines("hello", file1)
  writeLines("world", file2)
  writeLines("blabl", file3)

  files = c(file1, file2, file3)
  result = filter_files(files, filter = "\\.md$", FALSE)

  expect_equal(basename(result), "todo.md")
})


test_that("filter_files() can exclude files using negate = TRUE", {
  tmp = withr::local_tempdir()
  file1 = file.path(tmp, "script.R")
  file2 = file.path(tmp, "notes.txt")
  file3 = file.path(tmp, "README.md")
  writeLines("some code", file1)
  writeLines("some text", file2)
  writeLines("documentation", file3)

  files = c(file1, file2, file3)

  # Exclude files ending with .txt
  result = filter_files(files, filter = "\\.txt$", negate = TRUE)

  # Should keep script.R and README.md
  expect_true(file1 %in% result)
  expect_false(file2 %in% result)
  expect_true(file3 %in% result)
})


# is_in_gitfolder ----------------------------------------------------------

test_that("is_in_gitfolder() detects .git folders correctly", {
  paths = c(
    "project/.git/config",
    NA_character_,
    "project/data/file.csv",
    "project/.git/hooks/pre-commit"
  )
  expect_equal(is_in_gitfolder(paths), c(TRUE, NA, FALSE, TRUE))
})

# has_known_nontext_extension ----------------------------------------------

test_that("has_known_nontext_extension() identifies non-text files", {
  files = c("image.png", "archive.zip", "notes.txt", "script.R")
  expect_equal(has_known_nontext_extension(files), c(TRUE, TRUE, FALSE, FALSE))
})

# has_known_text_extension -------------------------------------------------

test_that("has_known_text_extension() identifies text files", {
  files = c("notes.txt", "data.csv", "program.R", "archive.zip")
  expect_equal(has_known_text_extension(files), c(TRUE, TRUE, TRUE, FALSE))
})

# has_null_bytes -----------------------------------------------------------

test_that("has_null_bytes() detects null bytes correctly", {
  tmp = withr::local_tempfile()
  tmp2 = withr::local_tempfile()
  writeBin(c(as.raw(c(0x48, 0x00, 0x65, 0x6C, 0x6C, 0x6F))), tmp)
  writeLines("hello", tmp2)

  expect_true(has_null_bytes(tmp))
  expect_false(has_null_bytes(tmp2))
})

test_that("has_null_bytes() returns TRUE on read warning", {
  expect_true(has_null_bytes("nonexistent_file.txt"))
})

test_that("has_null_bytes() returns TRUE on read error", {
  local_mocked_bindings(readBin = function(...) stop())
  expect_true(has_null_bytes("nonexistent_file.txt"))
})
