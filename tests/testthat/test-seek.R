# seek --------------------------------------------------------------------

test_that("seek() input validation", {
  tmpdir = withr::local_tempdir()

  # path
  expect_error(seek(path = 123, pattern = "x"))
  expect_error(seek(path = TRUE, pattern = "x"))
  expect_error(seek(path = NA_character_, pattern = "x"))
  expect_error(seek(path = character(0), pattern = "x"))
  expect_error(seek(path = "nonexistent_dir", pattern = "x"))

  # pattern
  expect_error(seek(path = tmpdir, pattern = NULL))
  expect_error(seek(path = tmpdir, pattern = 456))
  expect_error(seek(path = tmpdir, pattern = TRUE))

  # filter
  expect_error(seek(path = tmpdir, pattern = "x", filter = 123))
  expect_error(seek(path = tmpdir, pattern = "x", filter = TRUE))
  expect_error(seek(path = tmpdir, pattern = "x", filter = NA_character_))

  # negate
  expect_error(seek(path = tmpdir, pattern = "x", negate = NULL))
  expect_error(seek(path = tmpdir, pattern = "x", negate = NA))
  expect_error(seek(path = tmpdir, pattern = "x", negate = c(TRUE, FALSE)))

  # recurse
  expect_error(seek(path = tmpdir, pattern = "x", recurse = "wrong"))
  expect_error(seek(path = tmpdir, pattern = "x", recurse = 1.5))
  expect_error(seek(path = tmpdir, pattern = "x", recurse = c(TRUE, FALSE)))

  # all
  expect_error(seek(path = tmpdir, pattern = "x", all = "wrong"))
  expect_error(seek(path = tmpdir, pattern = "x", all = c(TRUE, FALSE)))

  # relative_path
  expect_error(seek(path = tmpdir, pattern = "x", relative_path = "wrong"))
  expect_error(seek(path = tmpdir, pattern = "x", relative_path = c(TRUE, FALSE)))

  # matches
  expect_error(seek(path = tmpdir, pattern = "x", matches = "wrong"))
  expect_error(seek(path = tmpdir, pattern = "x", matches = c(TRUE, FALSE)))
})


test_that("seek() works correctly and returns a clean tibble in a mixed environment", {
  tmpdir = withr::local_tempdir()
  create_mixed_test_files(tmpdir)

  result_should_be = tibble::tibble(
    path = structure(c("/script1.R", "/script2.R"), class = "fs_path"),
    line_number = c(1L, 1L),
    match = c("myfunc", "yourfunc"),
    line = c(
      "myfunc = function(x) { x + 1 }",
      "yourfunc = function(x) { x + 1 }"
    )
  )

  # base
  result1 = seek(
    path = tmpdir,
    pattern = "[^\\s]+(?= (=|=) function\\()",
    filter = "\\.R$",
    recurse = FALSE,
    relative_path = TRUE
  )

  expect_identical(result1, result_should_be)

  # duplicate files
  result2 = seek(
    path = c(tmpdir, tmpdir),
    pattern = "[^\\s]+(?= (=|=) function\\()",
    filter = "\\.R$",
    recurse = TRUE
  )

  expect_identical(result2[, -1], result_should_be[, -1])

  # no filter
  result3 = seek(
    path = tmpdir,
    pattern = "[^\\s]+(?= (=|=) function\\()",
    relative_path = TRUE
  )

  expect_identical(result3, result_should_be)
})


# seek_in -----------------------------------------------------------------

test_that("seek_in() input validation", {
  tmpfile = withr::local_tempfile()
  writeLines("dummy line", tmpfile)

  # files
  expect_error(seek_in(files = 123, pattern = "x"))
  expect_error(seek_in(files = TRUE, pattern = "x"))
  expect_error(seek_in(files = NA_character_, pattern = "x"))
  expect_error(seek_in(files = character(0), pattern = "x"))

  # pattern
  expect_error(seek_in(files = tmpfile, pattern = NULL))
  expect_error(seek_in(files = tmpfile, pattern = 456))
  expect_error(seek_in(files = tmpfile, pattern = TRUE))

  # matches
  expect_error(seek_in(files = tmpfile, pattern = "x", matches = "wrong"))
  expect_error(seek_in(files = tmpfile, pattern = "x", matches = c(TRUE, FALSE)))
})


test_that("seek_in() works correctly and returns a clean tibble in a mixed environment", {
  tmpdir = withr::local_tempdir()
  create_mixed_test_files(tmpdir)

  files = list.files(tmpdir, pattern = "\\.R$", full.names = TRUE)

  result_should_be = tibble::tibble(
    line_number = c(1L, 1L),
    match = c("myfunc", "yourfunc"),
    line = c(
      "myfunc = function(x) { x + 1 }",
      "yourfunc = function(x) { x + 1 }"
    )
  )

  result = seek_in(
    files = files,
    pattern = "[^\\s]+(?= (=|=) function\\()"
  )

  expect_identical(result[, -1], result_should_be)
})
