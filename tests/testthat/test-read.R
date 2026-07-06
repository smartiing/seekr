# seekr_read_file() -------------------------------------------------------

test_that("ff_seekr_read_file() works", {
  expect_no_error(ff_seekr_read_file())
})

test_that("seekr_read_file() returns an empty string when n_bytes is zero", {
  path = test_path("fixtures", "read-file", "utf8.txt")
  result = seekr_read_file(path, n_bytes = 0L, encoding = "UTF-8")

  expect_identical(result, structure("", encoding = "UTF-8"))
})

test_that("seekr_read_file() returns an empty string for empty files", {
  path = test_path("fixtures", "read-file", "empty.txt")
  result = seekr_read_file(path, n_bytes = 100L, encoding = "UTF-8")

  expect_identical(result, structure("", encoding = "UTF-8"))
})

test_that("seekr_read_file() reads and decodes file content", {
  path = test_path("fixtures", "read-file", "utf8.txt")
  result = seekr_read_file(path, n_bytes = file.size(path), encoding = "UTF-8")

  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(grepl("café TODO", result, fixed = TRUE))
  expect_equal(attr(result, "encoding", exact = TRUE), "UTF-8")
})

test_that("seekr_read_file() detects encoding when encoding is NULL", {
  path = test_path("fixtures", "read-file", "utf8.txt")
  result = seekr_read_file(path, n_bytes = file.size(path), encoding = NULL)

  expect_type(result, "character")
  expect_length(result, 1L)
  expect_false(is.null(attr(result, "encoding", exact = TRUE)))
  expect_true(grepl("TODO", result, fixed = TRUE))
})

test_that("seekr_read_file() throws an error for missing file", {
  path = test_path("fixtures", "read-file", "missing.txt")

  expect_error(
    seekr_read_file(path, n_bytes = 100L, encoding = "UTF-8"),
    class = "seekr_error_read_bytes"
  )
})

test_that("seekr_read_file() warns and falls back to UTF-8 when encoding detection fails", {
  path = test_path("fixtures", "read-file", "plain.txt")

  local_mocked_bindings(
    stri_enc_detect = function(str) list(data.frame(Encoding = NA_character_)),
    .package = "stringi"
  )

  expect_warning(
    {result = seekr_read_file(path, n_bytes = file.size(path), encoding = NULL)},
    class = "seekr_warning_read_encoding_detection_failed"
  )

  expect_equal(result, structure("hello world", encoding = "UTF-8"))
})

test_that("seekr_read_file() warns and returns NA for unsupported null bytes", {
  path = test_path("fixtures", "read-file", "null-bytes.bin")

  expect_warning(
    {result = seekr_read_file(path, n_bytes = file.size(path), encoding = "UTF-8")},
    class = "seekr_warning_read_null_bytes"
  )

  expect_identical(result, structure(NA_character_, encoding = "UTF-8"))
})

test_that("seekr_read_file() wraps decoding errors", {
  path = test_path("fixtures", "read-file", "plain.txt")

  local_mocked_bindings(
    read_file = function(...) stop("decode boom"),
    .package = "readr"
  )

  expect_error(
    seekr_read_file(path, n_bytes = file.size(path), encoding = "UTF-8"),
    class = "seekr_error_read_decode"
  )
})

test_that("seekr_read_file() warns once for encoding different than UTF-8", {
  testthat::skip_on_cran()
  path = test_path("fixtures", "read-file", "plain.txt")

  expect_warning(
    seekr_read_file(path, n_bytes = file.size(path), encoding = "ASCII"),
    class = "seekr_warning_non_utf8_encoding"
  )
})
