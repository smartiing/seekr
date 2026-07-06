# summary.seekr_match -----------------------------------------------------

test_that("summary.seekr_match() rejects non-empty dots", {
  x = new_seekr_match()

  expect_error(
    summary(x, unused = TRUE),
    class = "rlib_error_dots_nonempty"
  )
})

test_that("summary.seekr_match() summarizes empty seekr_match vectors", {
  x = new_seekr_match()
  out = summary(x)

  expect_equal(nrow(out$path), 0L)
  expect_equal(nrow(out$match), 0L)
  expect_equal(nrow(out$extension), 0L)
  expect_equal(nrow(out$encoding), 0L)
})

test_that("summary.seekr_match() summarizes matches by path, match, extension, and encoding", {
  dir = withr::local_tempdir()
  path1 = file.path(dir, "a.R")
  path2 = file.path(dir, "b.R")
  path3 = file.path(dir, "c.txt")

  x = new_seekr_match(
    path = c(path1, path1, path1, path2, path3),
    start_line = c(1L, 2L, 3L, 1L, 1L),
    end_line = c(1L, 2L, 3L, 1L, 1L),
    start = c(1L, 5L, 9L, 1L, 1L),
    end = c(3L, 7L, 11L, 3L, 3L),
    start_col = c(1L, 1L, 1L, 1L, 1L),
    end_col = c(3L, 3L, 3L, 3L, 3L),
    match = c("foo", "foo", "foo", "foo", "baz"),
    replacement = c("bar", "bar", "bar", NA_character_, "qux"),
    before = rep(NA_character_, 5L),
    line = c("foo", "foo", "foo", "foo", "baz"),
    after = rep(NA_character_, 5L),
    encoding = c("UTF-8", "UTF-8", "UTF-8", "latin1", "UTF-8"),
    hash = c("a", "a", "a", "b", "c")
  )

  out = summary(x)

  expect_s3_class(out, "summary_seekr_match")
  expect_identical(out$path$path[[1]], path1)
  expect_identical(out$path$n[[1]], 3L)
  expect_equal(out$path$share[[1]], 3 / 5)

  idx_match = which(out$match$match == "foo" & out$match$replacement == "bar")
  expect_length(idx_match, 1L)
  expect_identical(out$match$n[[idx_match]], 3L)
  expect_equal(out$match$share[[idx_match]], 3 / 5)

  idx_missing_replacement = which(out$match$match == "foo" & is.na(out$match$replacement))
  expect_length(idx_missing_replacement, 1L)
  expect_identical(out$match$n[[idx_missing_replacement]], 1L)

  idx_r = which(out$extension$extension == "r")
  expect_length(idx_r, 1L)
  expect_identical(out$extension$n[[idx_r]], 4L)
  expect_equal(out$extension$share[[idx_r]], 4 / 5)

  idx_txt = which(out$extension$extension == "txt")
  expect_length(idx_txt, 1L)
  expect_identical(out$extension$n[[idx_txt]], 1L)

  idx_utf8 = which(out$encoding$encoding == "UTF-8")
  expect_length(idx_utf8, 1L)
  expect_identical(out$encoding$n[[idx_utf8]], 4L)

  idx_latin1 = which(out$encoding$encoding == "latin1")
  expect_length(idx_latin1, 1L)
  expect_identical(out$encoding$n[[idx_latin1]], 1L)
})


# print.summary_seekr_match ----------------------------------------------

test_that("print.summary_seekr_match() rejects non-empty dots", {
  x = summary(new_seekr_match())
  expect_error(print(x, unused = TRUE), class = "rlib_error_dots_nonempty")
})

test_that("print.summary_seekr_match() rejects invalid n values", {
  x = summary(new_seekr_match())
  expect_error(print(x, n = "foo"), class = "seekr_error_class")
  expect_error(print(x, n = NA_integer_), class = "seekr_error_na")
})

test_that("print.summary_seekr_match() prints empty summaries", {
  withr::local_message_sink(nullfile())
  withr::local_options(seekr.print.mode = "plain")

  x = summary(new_seekr_match())

  result = NULL
  output = capture.output(result <- print(x))

  expect_identical(result, x)
  expect_equal(output, character())
})

test_that("print.summary_seekr_match() prints summaries without replacements", {
  withr::local_message_sink(nullfile())
  withr::local_options(seekr.print.mode = "plain")

  dir = withr::local_tempdir()
  path1 = file.path(dir, "a.R")
  path2 = file.path(dir, "b.txt")

  x = new_seekr_match(
    path = c(path1, path1, path2),
    start_line = c(1L, 2L, 1L),
    end_line = c(1L, 2L, 1L),
    start = c(1L, 5L, 1L),
    end = c(3L, 7L, 3L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("foo", "bar", "foo"),
    replacement = rep(NA_character_, 3L),
    before = rep(NA_character_, 3L),
    line = c("foo", "bar", "foo"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "abc", "def")
  )

  sx = summary(x)

  result = NULL
  output = capture.output(result <- print(sx))
  output = cli::ansi_strip(output)

  expect_identical(result, sx)
  expect_true(any(grepl("Common Path:", output)))
  expect_true(any(grepl("Top sources", output)))
  expect_true(any(grepl("Top matches", output)))
  expect_false(any(grepl("Top matches/replacements", output)))
  expect_true(any(grepl("Top extension", output)))
  expect_true(any(grepl("Top encoding", output)))
})

test_that("print.summary_seekr_match() prints summaries with replacements", {
  withr::local_message_sink(nullfile())
  withr::local_options(seekr.print.mode = "plain")

  dir = withr::local_tempdir()
  path1 = file.path(dir, "a.R")
  path2 = file.path(dir, "b.txt")

  x = new_seekr_match(
    path = c(path1, path1, path2),
    start_line = c(1L, 2L, 1L),
    end_line = c(1L, 2L, 1L),
    start = c(1L, 5L, 1L),
    end = c(3L, 7L, 3L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("foo", "foo", "bar"),
    replacement = c("baz", "baz", "qux"),
    before = rep(NA_character_, 3L),
    line = c("foo", "foo", "bar"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "abc", "def")
  )

  sx = summary(x)

  output = capture.output(print(sx))
  output = cli::ansi_strip(output)

  expect_true(any(grepl("Top matches/replacements", output)))
  expect_true(any(grepl("<foo/baz>", output, fixed = TRUE)))
  expect_true(any(grepl("<bar/qux>", output, fixed = TRUE)))
})

test_that("print.summary_seekr_match() limits each section with n", {
  withr::local_message_sink(nullfile())
  withr::local_options(seekr.print.mode = "plain")

  dir = withr::local_tempdir()
  path1 = file.path(dir, "a.R")
  path2 = file.path(dir, "b.R")
  path3 = file.path(dir, "c.R")

  x = new_seekr_match(
    path = c(path1, path2, path3),
    start_line = c(1L, 1L, 1L),
    end_line = c(1L, 1L, 1L),
    start = c(1L, 1L, 1L),
    end = c(3L, 3L, 3L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("foo", "bar", "baz"),
    replacement = c("FOO", "BAR", "BAZ"),
    before = rep(NA_character_, 3L),
    line = c("foo", "bar", "baz"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "xxx", "def")
  )

  output = capture.output(print(summary(x), n = 2L))
  output = cli::ansi_strip(output)

  expect_true(any(grepl("Top sources \\[2/3\\]", output)))
  expect_true(any(grepl("Top matches/replacements \\[2/3\\]", output)))
})

test_that("print.summary_seekr_match() prints all rows with n = Inf", {
  withr::local_message_sink(nullfile())
  withr::local_options(seekr.print.mode = "plain")

  dir = withr::local_tempdir()
  path1 = file.path(dir, "a.R")
  path2 = file.path(dir, "b.R")
  path3 = file.path(dir, "c.R")

  x = new_seekr_match(
    path = c(path1, path2, path3),
    start_line = c(1L, 1L, 1L),
    end_line = c(1L, 1L, 1L),
    start = c(1L, 1L, 1L),
    end = c(3L, 3L, 3L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("foo", "bar", "baz"),
    replacement = c("FOO", "BAR", "BAZ"),
    before = rep(NA_character_, 3L),
    line = c("foo", "bar", "baz"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "xxx", "def")
  )

  output = capture.output(print(summary(x), n = Inf))
  output = cli::ansi_strip(output)

  expect_true(any(grepl("Top sources \\[3\\]", output)))
  expect_true(any(grepl("Top matches/replacements \\[3\\]", output)))
})

test_that("print.summary_seekr_match() error on negative n", {
  x = new_seekr_match()
  expect_error(print(summary(x), n = -3), class = "seekr_error_bounds")
})

test_that("print.summary_seekr_match() supports n = 0", {
  withr::local_message_sink(nullfile())
  withr::local_options(seekr.print.mode = "plain")

  dir = withr::local_tempdir()
  path1 = file.path(dir, "a.R")
  path2 = file.path(dir, "b.R")

  x = new_seekr_match(
    path = c(path1, path2),
    start_line = c(1L, 1L),
    end_line = c(1L, 1L),
    start = c(1L, 1L),
    end = c(3L, 3L),
    start_col = c(1L, 1L),
    end_col = c(3L, 3L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("foo", "bar"),
    after = rep(NA_character_, 2L),
    encoding = rep("UTF-8", 2L),
    hash = c("abc", "def")
  )

  expect_no_error(
    output <- capture.output(print(summary(x), n = 0L))
  )

  output = cli::ansi_strip(output)

  expect_true(any(grepl("Top sources \\[0/2\\]", output)))
  expect_true(any(grepl("Top matches/replacements \\[0/2\\]", output)))
})


test_that("print.summary_seekr_match() prints full paths when there is no common path", {
  withr::local_message_sink(nullfile())
  withr::local_options(list(seekr.print.mode = "plain"))

  path = file.path(withr::local_tempdir(), "single-file.R")
  x = match_text("foo foo", path, "foo", "bar")

  out = capture.output(print(summary(x)))

  expect_false(any(grepl("Common Path:", out, fixed = TRUE)))
  expect_true(any(grepl("single-file.R", out, fixed = TRUE)))
})


# compute_summary_available_width ----------------------------------------

test_that("compute_summary_available_width() computes available width for regular summary tables", {
  testthat::local_mocked_bindings(
    console_width = function() 60L,
    .package = "cli"
  )

  df = tibble::tibble(
    path = "a.R",
    n = 123L,
    share = 0.45
  )

  expect_identical(compute_summary_available_width(df), 44L)
})

test_that("compute_summary_available_width() reserves extra room for match/replacement tables", {
  testthat::local_mocked_bindings(
    console_width = function() 60L,
    .package = "cli"
  )

  df = tibble::tibble(
    match = "foo",
    replacement = "bar",
    n = 123L,
    share = 0.45
  )

  expect_identical(compute_summary_available_width(df), 41L)
})

test_that("compute_summary_available_width() uses at least a width of 30", {
  testthat::local_mocked_bindings(
    console_width = function() 10L,
    .package = "cli"
  )

  df = tibble::tibble(
    path = "a.R",
    n = 1L,
    share = 1
  )

  expect_identical(compute_summary_available_width(df), 15L)
})


# prepare_summary_df ------------------------------------------------------

test_that("prepare_summary_df() counts rows by one column", {
  xdf = tibble::tibble(
    path = c("a.R", "a.R", "b.R")
  )

  out = prepare_summary_df(xdf, "path")

  expect_s3_class(out, "tbl_df")
  expect_identical(names(out), c("path", "n", "share"))
  expect_identical(out$path[[1]], "a.R")
  expect_identical(out$n[[1]], 2L)
  expect_equal(out$share[[1]], 2 / 3)
})

test_that("prepare_summary_df() counts rows by multiple columns", {
  xdf = tibble::tibble(
    match = c("foo", "foo", "foo", "bar"),
    replacement = c("baz", "baz", NA_character_, "qux")
  )

  out = prepare_summary_df(xdf, c("match", "replacement"))

  expected = tibble::tibble(
    match = c("foo", "bar", "foo"),
    replacement = c("baz", "qux", NA_character_),
    n = c(2L, 1L, 1L),
    share = c(1/2, 1/4, 1/4)
  )

  expect_identical(out, expected)
})

test_that("prepare_summary_df() sorts counts in decreasing order", {
  xdf = tibble::tibble(
    extension = c("r", "txt", "r", "r", "md", "md")
  )

  out = prepare_summary_df(xdf, "extension")
  expected = tibble::tibble(
    extension = c("r", "md", "txt"),
    n = c(3L, 2L, 1L),
    share = c(3/6, 2/6, 1/6)
  )

  expect_identical(out, expected)
})


# prepare_summary_df_lines ------------------------------------------------

test_that("prepare_summary_df_lines() supports n = 0", {
  df = tibble::tibble(
    path = c("a.R", "b.R"),
    n = c(2L, 1L),
    share = c(2/3, 1/3)
  )

  expect_identical(
    prepare_summary_df_lines(df, n = 0L),
    character()
  )
})

test_that("prepare_summary_df_lines() formats summary rows", {
  withr::local_options(seekr.print.mode = "plain")

  df = tibble::tibble(
    path = c("a.R", "long-file-name.R"),
    n = c(2L, 1L),
    share = c(2/3, 1/3)
  )

  expect_identical(
    prepare_summary_df_lines(df, n = NULL),
    c(
      " \u2022 a.R              : 2 (66.7%)",
      " \u2022 long-file-name.R : 1 (33.3%)"
    )
  )
})

test_that("prepare_summary_df_lines() respects n", {
  df = tibble::tibble(
    path = c("a.R", "long-file-name.R", "c.R"),
    n = c(2L, 1L, 1L),
    share = c(2/4, 1/4, 1/4)
  )

  expect_identical(
    prepare_summary_df_lines(df, n = 2L),
    c(
      " \u2022 a.R              : 2 (50.0%)",
      " \u2022 long-file-name.R : 1 (25.0%)"
    )
  )
})


# prepare_summary_n_of ----------------------------------------------------

test_that("prepare_summary_n_of() formats complete row counts", {
  df = tibble::tibble(
    path = c("a.R", "b.R"),
    n = c(2L, 1L),
    share = c(2 / 3, 1 / 3)
  )

  out = prepare_summary_n_of(df, n = NULL)
  expect_identical(cli::ansi_strip(as.character(out)), "[2]")
})

test_that("prepare_summary_n_of() formats partial row counts", {
  df = tibble::tibble(
    path = c("a.R", "b.R", "c.R"),
    n = c(3L, 2L, 1L),
    share = c(0.5, 1 / 3, 1 / 6)
  )

  out = prepare_summary_n_of(df, n = 2L)
  expect_identical(cli::ansi_strip(as.character(out)), "[2/3]")
})

test_that("prepare_summary_n_of() supports n = 0", {
  df = tibble::tibble(
    path = c("a.R", "b.R"),
    n = c(2L, 1L),
    share = c(2 / 3, 1 / 3)
  )

  out = prepare_summary_n_of(df, n = 0L)
  expect_identical(cli::ansi_strip(as.character(out)), "[0/2]")
})

test_that("prepare_summary_n_of() supports n = Inf", {
  df = tibble::tibble(
    path = c("a.R", "b.R"),
    n = c(2L, 1L),
    share = c(2 / 3, 1 / 3)
  )

  out = prepare_summary_n_of(df, n = Inf)
  expect_identical(cli::ansi_strip(as.character(out)), "[2]")
})


# prepare_summary_match_replacement() ----------------------------------------

test_that("prepare_summary_match_replacement() formats matches without replacement", {
  out = prepare_summary_match_replacement(match = "foo", replacement = NA_character_ )
  expect_identical(cli::ansi_strip(out), "<foo>")
})

test_that("prepare_summary_match_replacement() formats matches with replacement", {
  out = prepare_summary_match_replacement(match = "foo", replacement = "bar")
  expect_identical(cli::ansi_strip(out), "<foo/bar>")
})

test_that("prepare_summary_match_replacement() formats empty replacements", {
  out = prepare_summary_match_replacement(match = "foo", replacement = "")
  expect_identical(cli::ansi_strip(out), "<foo/>")
})

test_that("prepare_summary_match_replacement() is vectorized", {
  out = prepare_summary_match_replacement(
    match = c("foo", "bar", "baz"),
    replacement = c("FOO", NA_character_, "")
  )

  expect_identical(cli::ansi_strip(out), c("<foo/FOO>", "<bar>", "<baz/>"))
})

test_that("prepare_summary_match_replacement() truncates long match and replacement previews", {
  # no truncation if width < 10L
  out = prepare_summary_match_replacement(
    match = "abcdefhijk",
    replacement = "abcdefhijk",
    width = 5L
  )

  expect_identical(cli::ansi_strip(out), "<abcdefhijk/abcdefhijk>")

  out = prepare_summary_match_replacement(
    match = "abcdefhijk",
    replacement = "abcdefhijk",
    width = 10L
  )

  expect_identical(cli::ansi_strip(out), "<abc\u2026/ab\u2026>")

  out = prepare_summary_match_replacement(
    match = "abcdefhijk",
    replacement = "abcdefhijk",
    width = 15L
  )

  expect_identical(cli::ansi_strip(out), "<abcdefhi\u2026/ab\u2026>")
})

test_that("prepare_summary_match_replacement() leaves short match and replacement previews unchanged", {
  out = prepare_summary_match_replacement(
    match = "foo",
    replacement = "bar",
    width = 20L
  )

  expect_identical(cli::ansi_strip(out), "<foo/bar>")
})
