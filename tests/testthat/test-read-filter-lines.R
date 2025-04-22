test_that("read_filter_lines() returns matching lines correctly", {
  tmp1 = withr::local_tempfile()
  tmp2 = withr::local_tempfile()
  writeLines(c("INFO Start", "ERROR Something went wrong", "INFO Done"), tmp1)
  writeLines(c("INFO Start", "Something went wrong", "ERROR Done"), tmp2)

  result = read_filter_lines(c(tmp1, tmp2), pattern = "^ERROR")

  expect_equal(result$line_number[[1]], 2)
  expect_length(result$line, 2)
  expect_length(result$line_number, 2)
  expect_equal(result$line[[1]], "ERROR Something went wrong")
})


test_that("read_filter_lines() skips files with errors gracefully", {
  bad_file = tempfile(fileext = ".txt") # does not exist

  result = read_filter_lines(bad_file, pattern = ".*")

  expect_equal(result$line_number[[1]], integer(0))
  expect_equal(result$line[[1]], character(0))
})


test_that("read_filter_lines() handles embedded null bytes with a warning", {
  tmp = withr::local_tempfile()
  writeBin(c(charToRaw("line1\n"), as.raw(0x00), charToRaw("line2\n")), tmp)

  expect_warning_or_message = function(expr) {
    tryCatch(
      expr,
      warning = function(w) expect_true(TRUE),
      error = function(e) expect_true(FALSE)
    )
  }

  expect_warning_or_message({
    result = read_filter_lines(tmp, pattern = "line")
  })

  expect_length(result$line[[1]], 1)  # fallback assumes empty match
})


test_that("read_filter_lines() returns empty vectors for non-matching patterns", {
  tmp1 = withr::local_tempfile()
  tmp2 = withr::local_tempfile()
  writeLines(c("INFO Start", "ERROR Something went wrong", "INFO Done"), tmp1)
  writeLines(c("INFO Start", "Something went wrong", "ERROR Done"), tmp2)

  files = c(tmp1, tmp2)

  result = read_filter_lines(files, pattern = "^qux")

  expect_equal(result$line_number[[1]], integer(0))
  expect_equal(result$line_number[[2]], integer(0))
  expect_equal(result$line[[1]], character(0))
  expect_equal(result$line[[2]], character(0))
})


test_that("read_filter_lines() works with multiple files", {
  tmp1 = withr::local_tempfile()
  tmp2 = withr::local_tempfile()
  writeLines(c("apple", "banana", "cherry"), tmp1)
  writeLines(c("banana split", "pineapple"), tmp2)

  result = read_filter_lines(c(tmp1, tmp2), pattern = "banana")

  expect_equal(result$line[[1]], "banana")
  expect_equal(result$line[[2]], "banana split")
})


test_that("read_filter_lines() works with empty input list", {
  result = read_filter_lines(character(0), pattern = ".*")
  expect_equal(result$line, list())
  expect_equal(result$line_number, list())
})


test_that("read_filter_lines() mocks cli", {
  local_mocked_bindings(print_cli = function() TRUE)
  local_mocked_bindings(
    cli_progress_step = function(...) invisible(),
    cli_alert_warning = function(...) invisible(),
    cli_progress_update = function(...) invisible(),
    .package = "cli"
  )

  tmp1 = withr::local_tempfile()
  tmp2 = withr::local_tempfile()
  writeLines(c("apple", "banana", "cherry"), tmp1)
  writeLines(c("banana split", "pineapple"), tmp2)

  files = c(tmp1, tmp2, tmp1, tmp2, tmp1, tmp2, tmp1, tmp2)
  result = read_filter_lines(files, pattern = "banana")
  expect_equal(result$line[[1]], "banana")
  expect_equal(result$line[[2]], "banana split")

  local_mocked_bindings(read_lines = function(...) warning("warn"), .package = "readr")
  expect_no_warning(read_filter_lines(files, pattern = "banana"))

  local_mocked_bindings(read_lines = function(...) stop("error"), .package = "readr")
  expect_no_error(read_filter_lines(files, pattern = "banana"))
})
