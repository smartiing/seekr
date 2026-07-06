test_that("as_seekr_path() wraps normalize_path(, deduplicate = FALSE)", {
  paths = c(".", ".", "~")
  expect_equal(
    as_seekr_path(paths),
    normalize_path(paths, deduplicate = FALSE)
  )
})

test_that("normalize_path() returns absolute paths", {
  result = normalize_path(".")
  expect_true(fs::is_absolute_path(result))
})

test_that("normalize_path() expands home directory", {
  result = normalize_path("~/foo")
  expect_false(startsWith(result, "~"))
  expect_true(fs::is_absolute_path(result))
})

test_that("normalize_path() normalizes redundant path components", {
  result = normalize_path(file.path(".", "a", "..", "b", ".", "c"))
  expected = normalize_path(file.path(".", "b", "c"))
  expect_equal(result, expected)
})

test_that("normalize_path() doesn't deduplicates identical paths by default", {
  result = normalize_path(c(".", ".", "."))
  expect_length(result, 3L)
})

test_that("normalize_path() deduplicates identical paths when deduplicate = TRUE", {
  result = normalize_path(c(".", ".", "."), deduplicate = TRUE)
  expect_length(result, 1L)
})

test_that("normalize_path() deduplicates paths that resolve to the same location when deduplicate = TRUE", {
  result = normalize_path(c(file.path(".", "."), "."), deduplicate = TRUE)
  expect_length(result, 1L)
})

test_that("normalize_path() preserves the exclusions attribute", {
  x = c("/some/path", "/other/path")
  fake_exclusions = data.frame(path = "/some/path", excluded = TRUE)
  attr(x, "exclusions") = fake_exclusions

  result = normalize_path(x)
  expect_identical(attr(result, "exclusions", exact = TRUE), fake_exclusions)
})

test_that("normalize_path() returns NULL exclusions when none were set", {
  result = normalize_path("/some/path")
  expect_null(attr(result, "exclusions", exact = TRUE))
})

test_that("normalize_path() returns a plain character vector", {
  result = normalize_path("/some/path")
  expect_type(result, "character")
})


test_that("normalize_extension() returns NULL for NULL input", {
  expect_null(normalize_extension(NULL))
})

test_that("normalize_extension() returns empty string for empty string", {
  expect_equal(normalize_extension(c("csv", "")), c("csv", ""))
})

test_that("normalize_extension() lowercases extensions", {
  result = normalize_extension(c("R", "CSV", "SQL"))
  expect_equal(result, c("r", "csv", "sql"))
})

test_that("normalize_extension() removes leading dots", {
  result = suppressWarnings(normalize_extension(c(".R", ".csv")))
  expect_equal(result, c("r", "csv"))
})

test_that("normalize_extension() removes multiple leading dots", {
  result = suppressWarnings(normalize_extension("...SQL"))
  expect_equal(result, "sql")
})

test_that("normalize_extension() deduplicates after normalization", {
  result = normalize_extension(c("R", ".R", "r"))
  expect_equal(result, "r")
})

test_that("normalize_extension() deduplicates across different inputs that normalize identically", {
  result = normalize_extension(c("CSV", ".csv", "Csv"))
  expect_equal(result, "csv")
})

test_that("normalize_extension() truncates compound extensions to the last component", {
  result = suppressWarnings(normalize_extension("tar.gz"))
  expect_equal(result, "gz")

  result2 = suppressWarnings(normalize_extension(c("R", "tar.gz")))
  expect_setequal(result2, c("r", "gz"))
})

test_that("normalize_extension() does not warn on non-compound extensions", {
  expect_no_warning(normalize_extension(c("R", "csv", "sql")))
  expect_no_warning(normalize_extension(".R"))
})


test_that("normalize_pattern() wraps a plain string as stringr::regex with multiline = TRUE", {
  result = normalize_pattern("foo")
  expect_s3_class(result, "stringr_regex")
  expect_true(isTRUE(attr(result, "options")$multiline))
})

test_that("normalize_pattern() passes through stringr_regex objects unchanged", {
  x = stringr::regex("foo", multiline = FALSE)
  expect_identical(normalize_pattern(x), x)
})

test_that("normalize_pattern() passes through stringr_fixed objects unchanged", {
  x = stringr::fixed("foo")
  expect_identical(normalize_pattern(x), x)
})

test_that("normalize_pattern() passes through stringr_coll objects unchanged", {
  x = stringr::coll("foo")
  expect_identical(normalize_pattern(x), x)
})


test_that("normalize_context() expands a scalar to a symmetric pair", {
  result = normalize_context(5L)
  expect_equal(result, list(before = 5L, after = 5L))
})

test_that("normalize_context() uses first element as before and second as after", {
  result = normalize_context(c(3L, 7L))
  expect_equal(result, list(before = 3L, after = 7L))
})

test_that("normalize_context() coerces numeric to integer", {
  result = normalize_context(5.0)
  expect_type(result$before, "integer")
  expect_type(result$after, "integer")
})

test_that("normalize_context() returns a named list with 'before' and 'after'", {
  result = normalize_context(5L)
  expect_equal(result, list(before = 5L, after = 5L))
})

test_that("normalize_context() handles zero correctly", {
  result = normalize_context(0L)
  expect_equal(result, list(before = 0L, after = 0L))
})


test_that("normalize_max_file_size() returns Inf for zero", {
  expect_equal(normalize_max_file_size(0L), Inf)
})

test_that("normalize_max_file_size() returns Inf for negative values", {
  expect_equal(normalize_max_file_size(-1L), Inf)
  expect_equal(normalize_max_file_size(-100L), Inf)
})

test_that("normalize_max_file_size() returns the value unchanged for positive values", {
  expect_equal(normalize_max_file_size(1000L), 1000L)
  expect_equal(normalize_max_file_size(1L), 1L)
})

test_that("normalize_max_file_size() returns Inf unchanged", {
  expect_equal(normalize_max_file_size(Inf), Inf)
})
