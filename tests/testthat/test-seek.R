# seek() ------------------------------------------------------------------

test_that("seek() sets empty_stage to 'input' when path is empty", {
  x = suppressWarnings(seek("foo", path = character()))
  expect_equal(empty_stage(x), "input")
  expect_s3_class(x, "seekr_match")
  expect_length(x, 0L)
})

test_that("seek() sets empty_stage to 'list' when no files are found", {
  empty = withr::local_tempdir()
  x = seek("foo", path = empty)
  expect_equal(empty_stage(x), "list")
  expect_length(x, 0L)
})

test_that("seek() sets empty_stage to 'filter' when all files are excluded", {
  withr::local_message_sink(nullfile())
  x = seek("foo", path = test_path("fixtures", "listing"), extension = "xyz_nonexistent")
  expect_equal(empty_stage(x), "filter")
  expect_length(x, 0L)
})

test_that("seek() sets empty_stage to 'match' when no matches are found", {
  x = seek("xyzxyz_this_pattern_will_never_match_123456", path = test_path("fixtures", "listing"))
  expect_equal(empty_stage(x), "match")
  expect_length(x, 0L)
})

test_that("seek() returns NULL empty_stage for non-empty results", {
  x = seek("File", path = test_path("fixtures", "listing"))
  expect_null(empty_stage(x))
  expect_gt(length(x), 0L)
})

test_that("seek() attaches exclusions attribute after filtering", {
  x = seek("foo", path = test_path("fixtures", "listing"))
  excl = exclusions(x)
  expect_s3_class(excl, "data.frame")
  expect_true("path" %in% names(excl))
  expect_true("excluded" %in% names(excl))
})

test_that("seek() carries exclusions attribute even when empty_stage is 'filter'", {
  x = seek("foo", path = test_path("fixtures", "listing"), extension = "xyz_nonexistent")
  excl = exclusions(x)
  expect_s3_class(excl, "data.frame")
  expect_gt(nrow(excl), 0L)
  expect_true(all(excl$excluded))
})

test_that("seek() carries exclusions attribute even when empty_stage is 'match'", {
  x = seek("xyzxyz_this_pattern_will_never_match_123456", path = test_path("fixtures", "listing"))
  excl = exclusions(x)
  expect_s3_class(excl, "data.frame")
})

test_that("seek() returns NULL exclusions when path is empty", {
  x = suppressWarnings(seek("foo", path = character()))
  expect_null(exclusions(x))
})

test_that("seek() returns NULL exclusions when no files are listed", {
  empty = withr::local_tempdir()
  x = seek("foo", path = empty)
  expect_null(exclusions(x))
})

test_that("seek() always returns a seekr_match vector", {
  expect_s3_class(seek("File", path = test_path("fixtures", "listing")), "seekr_match")
  expect_s3_class(seek("xyzxyz_nomatch", path = test_path("fixtures", "listing")), "seekr_match")
  expect_s3_class(suppressWarnings(seek("foo", path = character())), "seekr_match")
})

test_that("seek() passes extension to filter_files()", {
  x_all = seek("File", path = test_path("fixtures", "listing"))
  x_txt = seek("File", path = test_path("fixtures", "listing"), extension = "txt")

  paths_all = unique(vctrs::field(x_all, "path"))
  paths_txt = unique(vctrs::field(x_txt, "path"))

  expect_true(all(extract_lower_file_extension(paths_txt) == "txt"))
  expect_lte(length(paths_txt), length(paths_all))
})

test_that("seek() passes path_pattern to filter_files()", {
  x = seek(".", path = test_path("fixtures", "listing"), path_pattern = "dir1")
  paths = unique(vctrs::field(x, "path"))
  expect_true(all(grepl("dir1", paths)))
})

test_that("seek() passes recurse = FALSE to list_files()", {
  x_recurse = seek(".", path = test_path("fixtures", "listing"), recurse = TRUE)
  x_flat    = seek(".", path = test_path("fixtures", "listing"), recurse = FALSE)
  expect_lte(length(x_flat), length(x_recurse))

  paths_recurse = vctrs::field(x_recurse, "path")
  paths_flat    = vctrs::field(x_flat, "path")
  expect_true(any(grepl("nested", paths_recurse)))
  expect_false(any(grepl("nested", paths_flat)))
})

test_that("seek() passes context to match_files()", {
  x0 = seek("File", path = test_path("fixtures", "listing"), context = 0L)
  x5 = seek("File", path = test_path("fixtures", "listing"), context = 5L)

  # With context = 0, before and after fields should be empty strings
  expect_true(all(is.na(vctrs::field(x0, "before"))))
  # With context = 5 on small files, before/after may still be empty but
  # the field lengths are the same — just verify no error is thrown
  expect_true(all(is.na(vctrs::field(x0, "after"))))
  expect_false(all(is.na(vctrs::field(x5, "after"))))
  expect_s3_class(x5, "seekr_match")
})

test_that("seek() passes replacement to match_files()", {
  x_no_repl = seek("File", path = test_path("fixtures", "listing"))
  x_repl    = seek("File", path = test_path("fixtures", "listing"), replacement = "REPLACED")

  expect_true(all(is.na(vctrs::field(x_no_repl, "replacement"))))
  expect_true(all(vctrs::field(x_repl, "replacement") == "REPLACED"))
})

test_that("seek() does not inform when .progress is FALSE", {
  expect_no_message(
    seek("foo", path = test_path("fixtures", "listing"), extension = "xyz_nonexistent", .progress = FALSE)
  )
})

test_that("seek() supports progress output", {
  withr::local_message_sink(nullfile())
  expect_no_error(seek("foo", path = test_path("fixtures", "listing"), .progress = TRUE))
})


# seekr() -----------------------------------------------------------------

test_that("seekr() returns a seekr_match vector", {
  expect_s3_class(seekr("xyzxyz_nomatch", path = test_path("fixtures", "listing")), "seekr_match")
})

test_that("seekr() only searches R, Rmd, and qmd files", {
  x = seekr(".", path = test_path("fixtures", "listing"))

  paths = unique(vctrs::field(x, "path"))
  expect_true(all(extract_lower_file_extension(paths) %in% c("r", "rmd", "qmd")))
})

test_that("seekr() is equivalent to seek() with extension = c('R', 'Rmd', 'qmd')", {
  x_seekr = seekr("file", path = test_path("fixtures", "listing"))
  x_seek  = seek("file", path = test_path("fixtures", "listing"), extension = c("R", "Rmd", "qmd"))
  expect_identical(x_seekr, x_seek)
})


# empty_stage() -----------------------------------------------------------

test_that("empty_stage() returns NULL for non-seekr_match objects", {
  expect_null(empty_stage("foo"))
  expect_null(empty_stage(NULL))
  expect_null(empty_stage(42L))
  expect_null(empty_stage(list()))
})

test_that("empty_stage() returns NULL for non-empty seekr_match", {
  x = seek("File", path = test_path("fixtures", "listing"))
  expect_null(empty_stage(x))
})

test_that("empty_stage() returns NULL for seekr_match without attribute", {
  x = new_seekr_match()
  expect_null(empty_stage(x))
})

test_that("empty_stage() returns the correct stage for each empty case", {
  empty = withr::local_tempdir()
  fixtures = test_path("fixtures", "listing")

  expect_equal(empty_stage(suppressWarnings(seek("foo", path = character()))), "input")
  expect_equal(empty_stage(seek("foo", path = empty)), "list")
  expect_equal(empty_stage(seek("foo", path = fixtures, extension = "xyz")), "filter")
  expect_equal(empty_stage(seek("xyzxyz_nomatch_123456", path = fixtures)), "match")
})
