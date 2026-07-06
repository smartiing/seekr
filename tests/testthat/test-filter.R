# filter_files() ----------------------------------------------------------

test_that("filter_files() rejects non-empty dots", {
  path = filtering_files()
  expect_error(filter_files(path, foo = 1), class = "rlib_error_dots_nonempty")
  expect_error(filter_files(path, 1L), class = "rlib_error_dots_nonempty")
})

test_that("filter_files() validates its arguments", {
  path = filtering_files()

  expect_error(filter_files(path = NA_character_), class = "seekr_error_na")
  expect_error(filter_files(path, extension = NA_character_), class = "seekr_error_na")
  expect_error(filter_files(path, max_file_size = NA_real_), class = "seekr_error_na")
  expect_error(filter_files(path, exclude = list(function(x) FALSE)), class = "seekr_error_exclude_functions")
  expect_error(filter_files(path, .progress = NA), class = "seekr_error_na")
})

test_that("filter_files() returns an empty character vector for empty paths", {
  result = filter_files(character())

  expect_type(result, "character")
  expect_length(result, 0L)
  expect_s3_class(exclusions(result), "data.frame")
  expect_equal(nrow(exclusions(result)), 0L)
})

test_that("filter_files() returns normalized character file paths", {
  path = filtering_files()
  result = filter_files(path, exclude = NULL)

  expect_type(result, "character")
  expect_setequal(result, normalize_path(path))
})

test_that("filter_files() attaches exclusion details", {
  path = filtering_files()
  result = filter_files(path, extension = "R", exclude = NULL)
  details = exclusions(result)

  expect_s3_class(details, "data.frame")
  expect_named(details, c("path", "excluded", "exclude_by_extension"))
  expect_equal(details$path, normalize_path(path))
  expect_type(details$excluded, "logical")
})

test_that("filter_files() filters by extension", {
  path = filtering_files()
  result = filter_files(
    path,
    extension = c("R", ".csv", ""),
    exclude = NULL
  )

  expected = normalize_path(c(
    test_path("fixtures", "filtering", "root-r.R"),
    test_path("fixtures", "filtering", "upper.CSV"),
    test_path("fixtures", "filtering", "no-extension"),
    test_path("fixtures", "filtering", "keep", "keep-r.R"),
    test_path("fixtures", "filtering", "skip", "skip-r.R")
  ))

  expect_setequal(result, expected)
})

test_that("filter_files() filters by path_pattern", {
  path = filtering_files()
  result = filter_files(
    path,
    path_pattern = "/keep/",
    exclude = NULL
  )

  expected = normalize_path(test_path("fixtures", "filtering", "keep", "keep-r.R"))

  expect_setequal(result, expected)
})

test_that("filter_files() filters by max_file_size", {
  path = c(
    test_path("fixtures", "filtering", "size", "small.txt"),
    test_path("fixtures", "filtering", "size", "large.txt")
  )

  result = filter_files(
    path,
    max_file_size = 20L,
    exclude = NULL
  )

  expected = normalize_path(test_path("fixtures", "filtering", "size", "small.txt"))

  expect_setequal(result, expected)
})

test_that("filter_files() applies custom exclude functions", {
  path = filtering_files()
  custom_fns = list(
    exclude_skip = function(path) grepl("/skip/", path)
  )

  result = filter_files(path, exclude = custom_fns)
  details = exclusions(result)

  expect_false(any(grepl("/skip/", result)))
  expect_true("exclude_skip" %in% names(details))
  expect_true(details$exclude_skip[details$path == normalize_path(test_path("fixtures", "filtering", "skip", "skip-r.R"))])
})

test_that("filter_files() applies exclude functions only to active files", {
  path = filtering_files()
  remaining_paths = NULL

  custom_fns = list(
    exclude_txt = function(path) grepl("\\.txt$", path),
    capture_remaining = function(path) {
      if (any(grepl("\\.txt$", path))) {
        stop("exclude function applied to non-active file")
      }

      rep(FALSE, length(path))
    }
  )

  expect_no_error(filter_files(path, exclude = custom_fns))
})

test_that("filter_files() rejects exclude functions with invalid return length", {
  path = filtering_files()
  custom_fns = list(
    bad_length = function(path) TRUE
  )

  expect_error(
    filter_files(path, exclude = custom_fns),
    class = "seekr_error_length"
  )
})

test_that("filter_files() supports progress output", {
  withr::local_message_sink(nullfile())
  path = filtering_files()

  expect_no_error(filter_files(path, .progress = TRUE))
})

test_that("filter_files() works with no active filters", {
  path = filtering_files()
  out = filter_files(path, exclude = NULL)
  expect_identical(path, as.character(out))

  expected_exclusions = tibble::tibble(
    path = path,
    excluded = FALSE
  )

  expect_identical(exclusions(out), expected_exclusions)
})


# create_empty_exclusion_details_df() -------------------------------------

test_that("create_empty_exclusion_details_df() creates one row per path", {
  path = normalize_path(filtering_files()[1:2])
  exclusion_functions = list(foo = function(path) FALSE, bar = function(path) FALSE)
  result = create_empty_exclusion_details_df(path, exclusion_functions)

  expect_s3_class(result, "data.frame")
  expect_named(result, c("path", "excluded", "foo", "bar"))
  expect_equal(result$path, path)
  expect_equal(result$excluded, c(FALSE, FALSE))
  expect_true(all(is.na(result$foo)))
  expect_true(all(is.na(result$bar)))
})


# create_exclusion_functions() --------------------------------------------

test_that("create_exclusion_functions() builds exclusion functions in order", {
  custom_fns = list(custom = function(path) rep(FALSE, length(path)))

  result = create_exclusion_functions(
    extension = "r",
    path_pattern = "/R/",
    max_file_size = 10L,
    exclude = custom_fns
  )

  expect_type(result, "list")
  expect_named(result, c(
    "exclude_by_extension",
    "exclude_by_path_pattern",
    "exclude_by_file_size",
    "custom"
  ))
})


# ff_exclude_by_path_pattern() --------------------------------------------

test_that("ff_exclude_by_path_pattern() excludes paths that do not match", {
  path = normalize_path(c(
    test_path("fixtures", "filtering", "keep", "keep-r.R"),
    test_path("fixtures", "filtering", "skip", "skip-r.R")
  ))

  fn = ff_exclude_by_path_pattern("/keep/")
  result = fn(path)

  expect_equal(result, c(FALSE, TRUE))
})


# ff_exclude_by_extension() ------------------------------------------------

test_that("ff_exclude_by_extension() excludes paths with non-matching extensions", {
  path = normalize_path(c(
    test_path("fixtures", "filtering", "root-r.R"),
    test_path("fixtures", "filtering", "upper.CSV"),
    test_path("fixtures", "filtering", "no-extension")
  ))

  fn = ff_exclude_by_extension(c("r", ""))
  expect_equal(fn(path), c(FALSE, TRUE, FALSE))
})


# ff_exclude_by_file_size() ------------------------------------------------

test_that("ff_exclude_by_file_size() excludes files larger than the limit", {
  path = normalize_path(c(
    test_path("fixtures", "filtering", "size", "small.txt"),
    test_path("fixtures", "filtering", "size", "large.txt")
  ))

  fn = ff_exclude_by_file_size(20L)
  expect_equal(fn(path), c(FALSE, TRUE))
})


# exclude_functions -------------------------------------------------------

test_that("exclude_functions contains the default exclude pipeline", {
  expect_type(exclude_functions, "list")
  expect_named(exclude_functions, c(
    "is_git_dir",
    "is_dependency_dir",
    "is_minified_file",
    "is_not_text_mime"
  ))

  expect_true(all(vapply(exclude_functions, is.function, logical(1))))
})

test_that("is_git_dir() detects files inside .git directories", {
  path = normalize_path(c(
    test_path("fixtures", "filtering", ".git", "objects", "config"),
    test_path("fixtures", "filtering", "root-r.R")
  ))

  expect_equal(is_git_dir(path), c(TRUE, FALSE))
})

test_that("is_dependency_dir() detects files inside dependency directories", {
  path = normalize_path(c(
    test_path("fixtures", "filtering", "node_modules", "pkg", "package.js"),
    test_path("fixtures", "filtering", "root-r.R")
  ))

  expect_equal(is_dependency_dir(path), c(TRUE, FALSE))
})

test_that("is_minified_file() detects minified or bundled files", {
  path = normalize_path(c(
    test_path("fixtures", "filtering", "app.min.js"),
    test_path("fixtures", "filtering", "root-r.R")
  ))

  expect_equal(is_minified_file(path), c(TRUE, FALSE))
})

test_that("is_not_text_mime() detects non-text files", {
  path = normalize_path(c(
    test_path("fixtures", "filtering", "root-txt.txt"),
    test_path("fixtures", "filtering", "upper.CSV"),
    test_path("fixtures", "filtering", "image.jpg")
  ))

  expect_equal(is_not_text_mime(path), c(FALSE, FALSE, TRUE))
})


# exclusions() ------------------------------------------------------------

test_that("exclusions() retrieves exclusion details", {
  path = filtering_files()
  result = filter_files(path, extension = "R", exclude = NULL)
  details = exclusions(result)

  expect_s3_class(details, "data.frame")
  expect_named(details, c("path", "excluded", "exclude_by_extension"))
})

test_that("exclusions() returns NULL when no exclusion details are available", {
  expect_null(exclusions("foo"))
  expect_null(exclusions(NULL))
})


# extract_lower_file_extension() ------------------------------------------

test_that("extract_lower_file_extension() returns lowercase file extensions", {
  path = c("file.R", "data.CSV", "README", "archive.tar.gz")

  expect_equal(
    extract_lower_file_extension(path),
    c("r", "csv", "", "gz")
  )
})


# seekr_file_info() -------------------------------------------------------

test_that("seekr_file_info() returns file information without warning on missing files", {
  path = c(
    test_path("fixtures", "filtering", "root-r.R"),
    test_path("fixtures", "filtering", "missing.txt")
  )

  expect_no_warning(result <- seekr_file_info(path))
  expect_equal(nrow(result), 2L)
  expect_false(is.na(result$size[[1]]))
  expect_true(is.na(result$size[[2]]))
})


