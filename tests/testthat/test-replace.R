# replace_files() ---------------------------------------------------------

test_that("replace_files() rejects non-empty dots", {
  file = withr::local_tempfile(lines = "hello foo")
  x = match_files(file, "foo", replacement = "bar", .progress = FALSE)

  expect_error(replace_files(x, foo = 1, backup = FALSE, .progress = FALSE), class = "rlib_error_dots_nonempty")
  expect_error(replace_files(x, 1L, backup = FALSE, .progress = FALSE), class = "rlib_error_dots_nonempty")
})

test_that("replace_files() validates its arguments", {
  file = withr::local_tempfile(lines = "hello foo")
  x = match_files(file, "foo", "bar", .progress = FALSE)
  x_without_replacement = match_files(file, "foo", .progress = FALSE)

  expect_error(replace_files("not a match", backup = FALSE, .progress = FALSE))
  expect_error(replace_files(x_without_replacement, backup = FALSE, .progress = FALSE), class = "seekr_error_replacement_na_for_replacement")
  expect_error(replace_files(x, backup = NA, .progress = FALSE), class = "seekr_error_na")
  expect_error(replace_files(x, description = 1L, backup = FALSE, .progress = FALSE))
  expect_error(replace_files(x, backup = FALSE, backup_dir = c("a", "b"), .progress = FALSE), class = "seekr_error_length")
  expect_error(replace_files(x, backup = FALSE, .progress = NA), class = "seekr_error_na")
})

test_that("replace_files() rejects NA encoding or hash in seekr_match", {
  withr::local_message_sink(nullfile())
  x = new_seekr_match(
    path = c("example1.txt", "example2.txt"),
    start_line = c(1L, 1L),
    end_line = c(1L, 1L),
    start = c(1L, 4L),
    end = c(3L, 6L),
    start_col = c(1L, 2L),
    end_col = c(3L, 4L),
    match = c("abc", "bcd"),
    replacement = c("x", "y"),
    before = c(NA_character_, NA_character_),
    line = c("abcd", "abcd"),
    after = c(NA_character_, NA_character_),
    encoding = c("UTF-8", NA_character_),
    hash = c("abc", "def")
  )

  expect_error(
    replace_files(x, backup = FALSE, .progress = FALSE),
    class = "seekr_error_replace_files_missing_encoding"
  )
})

test_that("replace_files() returns an empty seekr_match for empty matches", {
  withr::local_message_sink(nullfile())
  result = replace_files(new_seekr_match(), backup = FALSE, .progress = FALSE)

  expect_s3_class(result, "seekr_match")
  expect_length(result, 0L)
})

test_that("replace_files() returns an empty seekr_match when all files are missing", {
  withr::local_message_sink(nullfile())
  file = withr::local_tempfile(lines = "hello foo")
  x = match_files(file, "foo", "bar")
  unlink(file)

  expect_warning(
    {result <- replace_files(x, backup = FALSE, .progress = FALSE)},
    class = "seekr_warn_missing_files"
  )

  expect_s3_class(result, "seekr_match")
  expect_length(result, 0L)
})

test_that("replace_files() applies replacements to one file", {
  file = withr::local_tempfile(lines = c("hello foo", "bye foo"))
  x = match_files(file, "foo", replacement = "bar", .progress = FALSE)

  result = replace_files(x, backup = FALSE, .progress = FALSE)

  expect_s3_class(result, "seekr_match")
  expect_equal(readLines(file), c("hello bar", "bye bar"))
})

test_that("replace_files() applies replacements to multiple files", {
  file_1 = withr::local_tempfile(lines = "first foo")
  file_2 = withr::local_tempfile(lines = "second foo")
  x = match_files(c(file_1, file_2), "foo", replacement = "bar", .progress = FALSE)

  replace_files(x, backup = FALSE, .progress = FALSE)

  expect_equal(readLines(file_1), "first bar")
  expect_equal(readLines(file_2), "second bar")
})

test_that("replace_files() skips missing files", {
  files = c(
    withr::local_tempfile(lines = "hello foo 1"),
    withr::local_tempfile(lines = "hello foo 2")
  )

  x = match_files(files, "foo", "bar")
  unlink(files[[2]])

  expect_warning(
    {result = replace_files(x, backup = FALSE, .progress = FALSE)},
    class = "seekr_warn_missing_files"
  )

  expect_s3_class(result, "seekr_match")
  expect_length(result, 1L)
  expect_equal(readLines(files[[1]]), "hello bar 1")
})

test_that("replace_files() rejects non-UTF-8 matches by default", {
  file = tempfile(fileext = ".txt")
  text = "hello old_name"
  writeLines(text, file)

  text = readr::read_file(file)

  x = match_text(
    text = text,
    path = file,
    pattern = "old_name",
    replacement = "new_name"
  )

  expect_error(
    replace_files(x, backup = FALSE, .progress = FALSE),
    class = "seekr_error_replace_files_missing_encoding"
  )

  field(x, "encoding") = rep("ISO-8859-1", length(x))

  expect_error(
    replace_files(x, backup = FALSE, .progress = FALSE),
    class = "seekr_error_replace_files_encoding_change"
  )
})

test_that("replace_files() aborts before partial replacement when a file changed", {
  file_1 = withr::local_tempfile(lines = "first foo")
  file_2 = withr::local_tempfile(lines = "second foo")
  x = match_files(c(file_1, file_2), "foo", replacement = "bar", .progress = FALSE)

  writeLines("second changed", file_2)

  expect_error(
    replace_files(x, backup = FALSE, .progress = FALSE),
    class = "seekr_error_replacement_hash_changed"
  )

  expect_equal(readLines(file_1), "first foo")
  expect_equal(readLines(file_2), "second changed")
})

test_that("replace_files() creates a backup by default", {
  file = withr::local_tempfile(lines = "hello foo")
  backup_dir = withr::local_tempdir()
  x = match_files(file, "foo", replacement = "bar", .progress = FALSE)

  replace_files(
    x,
    description = "test replacement",
    backup_dir = backup_dir,
    .progress = FALSE
  )

  backups = list_backups(backup_dir = backup_dir)

  expect_equal(readLines(file), "hello bar")
  expect_equal(nrow(backups), 1L)
  expect_equal(backups$operation, "replace")
  expect_equal(backups$description, "test replacement")
})


test_that("replace_files() supports progress output", {
  withr::local_message_sink(nullfile())
  withr::local_options(seekr.backup_dir = withr::local_tempdir())
  file = withr::local_tempfile(lines = "hello foo")
  x = match_files(file, "foo", "bar")
  expect_no_error({
    replace_files(x, backup = TRUE, .progress = TRUE)
  })
})


# replace_text() ----------------------------------------------------------

test_that("replace_text() validates its arguments", {
  text = "hello foo"
  path = withr::local_tempfile()
  x = match_text(text, "example.txt", "foo", "bar")
  x_wo_replacement = match_text(text, path, "foo")

  expect_error(replace_text(NA_character_, x), class = "seekr_error_na")
  expect_error(replace_text(text, "not a match"))
  expect_error(replace_text(text, x_wo_replacement), class = "seekr_error_replacement_na_for_replacement")
})

test_that("replace_text() returns text unchanged for empty matches", {
  text = "hello foo"
  result = replace_text(text, new_seekr_match())
  expect_identical(result, text)
})

test_that("replace_text() applies replacements to already-read text", {
  text = "hello foo\nbye foo"
  x = match_text(text, "example.txt", "foo", "bar")
  result = replace_text(text, x)

  expect_identical(result, "hello bar\nbye bar")
})

test_that("replace_text() applies replacements from end to beginning", {
  text = "old old"
  path = file.path(withr::local_tempdir(), "example.txt")
  x = match_text(text, "example.txt", "old", "longer")
  result = replace_text(text, x)
  expect_identical(result, "longer longer")
})

test_that("replace_text() rejects matches from multiple files", {
  text = "hello foo"
  path_1 = file.path(withr::local_tempdir(), "one.txt")
  path_2 = file.path(withr::local_tempdir(), "two.txt")

  x = c(
    match_text(text, path = "example1.txt", "foo", "bar"),
    match_text(text, path = "example2.txt", "foo", "bar")
  )

  expect_error(replace_text(text, x), class = "seekr_error_replace_text_multiple_files")
})

test_that("replace_text() aborts when recorded matches are stale", {
  text = "hello foo"
  path = file.path(withr::local_tempdir(), "example.txt")
  x = match_text(text, "example.txt", "foo", "bar")

  expect_error(
    replace_text("hello changed", x),
    class = "seekr_error_replacement_hash_changed"
  )
})

test_that("replace_text() rejects overlapping matches", {
  x = new_seekr_match(
    path = c("example.txt", "example.txt"),
    start_line = c(1L, 1L),
    end_line = c(1L, 1L),
    start = c(1L, 2L),
    end = c(3L, 4L),
    start_col = c(1L, 2L),
    end_col = c(3L, 4L),
    match = c("abc", "bcd"),
    replacement = c("x", "y"),
    before = c(NA_character_, NA_character_),
    line = c("abcd", "abcd"),
    after = c(NA_character_, NA_character_),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  expect_error(replace_text("abcd", x), class = "seekr_error_match_order_or_overlap")
})

test_that("replace_text() replaces from right to left when matches are unordered", {
  text = "foo foo"
  x = match_text("foo foo", "example.txt", "foo")
  field(x, "replacement") = c("first", "second")
  x = x[c(2, 1)]

  out = replace_text(text, x)

  expect_identical(out, "first second")
})

test_that("replace_text() aborts cleanly when recorded positions are invalid", {
  x = match_text("hello foo", "example.txt", "foo", "bar")

  expect_error(
    replace_text("short", x),
    class = "seekr_error_replacement_hash_changed"
  )
})


# write_replaced_text_to_file() ------------------------------------------

test_that("write_replaced_text_to_file() writes text to disk", {
  file = withr::local_tempfile(lines = "old text")
  result = write_replaced_text_to_file("new text\n", file)
  expect_equal(result, file)
  expect_equal(readLines(file), "new text")
})
