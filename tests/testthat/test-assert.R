# Helpers -----------------------------------------------------------------

test_that("assert_vector() accepts valid vectors", {
  expect_no_error(assert_vector("a"))
  expect_no_error(assert_vector(1L))
  expect_no_error(assert_vector(TRUE))
  expect_no_error(assert_vector(c("a", "b", "c")))
})

test_that("assert_vector() returns x on success", {
  x = c("a", "b")
  expect_identical(assert_vector(x), x)
})

test_that("assert_vector() rejects NULL when null_ok is FALSE", {
  expect_error(assert_vector(NULL, null_ok = FALSE), class = "seekr_error_null")
})

test_that("assert_vector() accepts NULL when null_ok is TRUE", {
  expect_null(assert_vector(NULL, null_ok = TRUE))
})

test_that("assert_vector() rejects wrong class with a single expected class", {
  expect_error(assert_vector("a", classes = "numeric"), class = "seekr_error_class")
  expect_error(assert_vector(1L, classes = "character"), class = "seekr_error_class")
})

test_that("assert_vector() rejects wrong class with multiple expected classes", {
  expect_error(assert_vector("a", classes = c("numeric", "integer")), class = "seekr_error_class")
})

test_that("assert_vector() accepts correct class with a single expected class", {
  expect_no_error(assert_vector(1L, classes = "integer"))
  expect_no_error(assert_vector("a", classes = "character"))
})

test_that("assert_vector() accepts correct class with multiple expected classes", {
  expect_no_error(assert_vector(1L, classes = c("integer", "numeric")))
  expect_no_error(assert_vector(1.0, classes = c("integer", "numeric")))
  expect_no_error(assert_vector(1.0, classes = c("character", "numeric")))
})

test_that("assert_vector() accepts correct exact length", {
  expect_no_error(assert_vector("a", len = 1L))
  expect_no_error(assert_vector(c("a", "b"), len = 2L))
})

test_that("assert_vector() rejects wrong exact length", {
  expect_error(assert_vector(c("a", "b"), len = 1L), class = "seekr_error_length")
  expect_error(assert_vector("a", len = 2L), class = "seekr_error_length")
})

test_that("assert_vector() accepts vectors at or above len_min", {
  expect_no_error(assert_vector("a", len_min = 0L))
  expect_no_error(assert_vector(c("a", "b", "c"), len_min = 2L))
})

test_that("assert_vector() rejects vectors below len_min", {
  expect_error(assert_vector(character(), len_min = 1L), class = "seekr_error_length_min")
  expect_error(assert_vector(c("a"), len_min = 2L), class = "seekr_error_length_min")
})

test_that("assert_vector() accepts vectors at or below len_max", {
  expect_no_error(assert_vector("a", len_max = 2L))
  expect_no_error(assert_vector(c("a", "b"), len_max = 2L))
})

test_that("assert_vector() rejects vectors above len_max", {
  expect_error(assert_vector(c("a", "b", "c"), len_max = 2L), class = "seekr_error_length_max")
})

test_that("assert_vector() accepts NA when na_ok is TRUE", {
  expect_no_error(assert_vector(NA, na_ok = TRUE))
  expect_no_error(assert_vector(c("a", NA), na_ok = TRUE))
})

test_that("assert_vector() rejects scalar NA when na_ok is FALSE", {
  expect_error(assert_vector(NA, na_ok = FALSE), class = "seekr_error_na")
  expect_error(assert_vector(NA_character_, na_ok = FALSE), class = "seekr_error_na")
  expect_error(assert_vector(NA_integer_, na_ok = FALSE), class = "seekr_error_na")
})

test_that("assert_vector() rejects NA in vector when na_ok is FALSE", {
  expect_error(assert_vector(c("a", NA), na_ok = FALSE), class = "seekr_error_na")
  expect_error(assert_vector(c(NA, "a", NA), na_ok = FALSE), class = "seekr_error_na")
})


test_that("assert_non_empty_string() accepts non-empty strings", {
  expect_no_error(assert_non_empty_string("hello"))
  expect_no_error(assert_non_empty_string(c("a", "b", "c")))
})

test_that("assert_non_empty_string() returns x on success", {
  x = c("hello", "world")
  expect_identical(assert_non_empty_string(x), x)
})

test_that("assert_non_empty_string() rejects NULL with internal error", {
  expect_error(assert_non_empty_string(NULL), class = "internal_error")
})

test_that("assert_non_empty_string() rejects NA with internal error", {
  expect_error(assert_non_empty_string(NA_character_), class = "internal_error")
  expect_error(assert_non_empty_string(c("a", NA_character_)), class = "internal_error")
})

test_that("assert_non_empty_string() rejects scalar empty string", {
  expect_error(assert_non_empty_string(""), class = "seekr_error_empty_string")
})

test_that("assert_non_empty_string() rejects empty strings in a vector", {
  expect_error(assert_non_empty_string(c("a", "")), class = "seekr_error_empty_string")
  expect_error(assert_non_empty_string(c("", "", "a")), class = "seekr_error_empty_string")
})


test_that("assert_integerish() accepts integer and integer-like numeric values", {
  expect_no_error(assert_integerish(1L))
  expect_no_error(assert_integerish(0L))
  expect_no_error(assert_integerish(1.0))
  expect_no_error(assert_integerish(c(1L, 2L, 3L)))
  expect_no_error(assert_integerish(round(c(1, 5.5, 3.2))))
})

test_that("assert_integerish() rejects non-integer-like numeric values", {
  expect_error(assert_integerish(1.5), class = "seekr_error_integerish")
  expect_error(assert_integerish(c(1L, 1.5)), class = "seekr_error_integerish")
  expect_error(assert_integerish(-0.1), class = "seekr_error_integerish")
})

test_that("assert_integerish() rejects non-numeric types", {
  expect_error(assert_integerish("1"), class = "seekr_error_integerish")
  expect_error(assert_integerish(TRUE), class = "seekr_error_integerish")
})


# Generic assertions ------------------------------------------------------

test_that("assert_flag() accepts TRUE and FALSE", {
  expect_no_error(assert_flag(TRUE))
  expect_no_error(assert_flag(FALSE))
})

test_that("assert_flag() returns x on success", {
  expect_identical(assert_flag(TRUE), TRUE)
  expect_identical(assert_flag(FALSE), FALSE)
})

test_that("assert_flag() rejects NULL", {
  expect_error(assert_flag(NULL), class = "seekr_error_null")
})

test_that("assert_flag() rejects NA", {
  expect_error(assert_flag(NA), class = "seekr_error_na")
})

test_that("assert_flag() rejects non-logical types", {
  expect_error(assert_flag(1L), class = "seekr_error_class")
  expect_error(assert_flag("TRUE"), class = "seekr_error_class")
  expect_error(assert_flag(0), class = "seekr_error_class")
})

test_that("assert_flag() rejects logical vectors of length > 1", {
  expect_error(assert_flag(c(TRUE, FALSE)), class = "seekr_error_length")
})


test_that("assert_paths() accepts non-empty character vectors", {
  expect_no_error(assert_paths("some/path"))
  expect_no_error(assert_paths(c("path/a", "path/b")))
})

test_that("assert_paths() returns x on success", {
  x = c("path/a", "path/b")
  expect_identical(assert_paths(x), x)
})

test_that("assert_paths() rejects NULL", {
  expect_error(assert_paths(NULL), class = "seekr_error_null")
})

test_that("assert_paths() rejects NA", {
  expect_error(assert_paths(NA_character_), class = "seekr_error_na")
  expect_error(assert_paths(c("a", NA_character_)), class = "seekr_error_na")
})

test_that("assert_paths() rejects empty strings", {
  expect_error(assert_paths(""), class = "seekr_error_empty_string")
  expect_error(assert_paths(c("a", "")), class = "seekr_error_empty_string")
})

test_that("assert_paths() rejects non-character types", {
  expect_error(assert_paths(1L), class = "seekr_error_class")
  expect_error(assert_paths(TRUE), class = "seekr_error_class")
})

test_that("assert_paths() respects the len argument", {
  expect_no_error(assert_paths("a", len = 1L))
  expect_error(assert_paths(c("a", "b"), len = 1L), class = "seekr_error_length")
  expect_error(assert_paths("a", len = 2L), class = "seekr_error_length")
})


test_that("assert_pattern() rejects NULL when null_ok is FALSE", {
  expect_error(assert_pattern(NULL), class = "seekr_error_null")
  expect_error(assert_pattern(NULL, null_ok = FALSE), class = "seekr_error_null")
})

test_that("assert_pattern() accepts NULL when null_ok is TRUE", {
  expect_null(assert_pattern(NULL, null_ok = TRUE))
})

test_that("assert_pattern() accepts plain character strings", {
  expect_no_error(assert_pattern("foo"))
  expect_no_error(assert_pattern("foo|bar"))
})

test_that("assert_pattern() accepts stringr pattern objects", {
  expect_no_error(assert_pattern(stringr::regex("foo")))
  expect_no_error(assert_pattern(stringr::fixed("foo")))
  expect_no_error(assert_pattern(stringr::coll("foo")))
})

test_that("assert_pattern() rejects stringr_boundary patterns", {
  expect_error(assert_pattern(stringr::boundary("word")), class = "seekr_error_pattern_boundary")
})

test_that("assert_pattern() rejects NA", {
  expect_error(assert_pattern(NA_character_), class = "seekr_error_na")
})

test_that("assert_pattern() rejects character vectors of length > 1", {
  expect_error(assert_pattern(c("foo", "bar")), class = "seekr_error_length")
})


test_that("assert_match() rejects non-seekr_match objects", {
  expect_error(assert_match("not a match"), class = "seekr_error_class")
  expect_error(assert_match(NULL), class = "seekr_error_null")
  expect_error(assert_match(list()), class = "seekr_error_class")
  expect_error(assert_match(1L), class = "seekr_error_class")
})

test_that("assert_match() accepts empty match vectors", {
  x = new_seekr_match()
  expect_s3_class(assert_match(x), "seekr_match")
})

test_that("assert_match() accepts valid matches", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 400L),
    end = c(203L, 403L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
 )

  expect_s3_class(assert_match(x), "seekr_match")
})


test_that("assert_match() rejects matches where start is greater than end", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(203L, 403L),
    end = c(200L, 400L),
    start_col = c(4L, 20L),
    end_col = c(6L, 2L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
 )

  expect_error(assert_match(x), class = "seekr_error_match_start_after_end")
})

test_that("assert_match() rejects matches where start_line is greater than end_line", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(11L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 400L),
    end = c(203L, 403L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
 )

  expect_error(assert_match(x), class = "seekr_error_match_start_after_end_line")
})


test_that("assert_match() rejects overlapping matches within the same file", {
  x = new_seekr_match(
    path = c("foo.R", "foo.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 250L),
    end = c(300L, 350L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
 )

  expect_error(assert_match(x), class = "seekr_error_match_order_or_overlap")
})


test_that("assert_match() allows identical ranges in different files", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(10L, 10L),
    end_line = c(10L, 10L),
    start = c(200L, 200L),
    end = c(203L, 203L),
    start_col = c(6L, 6L),
    end_col = c(8L, 8L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
 )

  expect_s3_class(assert_match(x), "seekr_match")
})


test_that("assert_fields_values() accepts valid seekr_match vectors", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 250L),
    end = c(202L, 252L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  expect_s3_class(assert_fields_values(x), "seekr_match")
})

test_that("assert_fields_values() accepts valid data frames", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 250L),
    end = c(202L, 252L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  df = tibble::as_tibble(x)

  expect_equal(assert_fields_values(df), df)
})

test_that("assert_fields_values() rejects invalid data frames", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 250L),
    end = c(202L, 252L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  df = tibble::as_tibble(x)
  df$start_line = as.numeric(df$start_line)

  expect_error(assert_fields_values(df), class = "seekr_error_match_incorrect_fields")
})

test_that("assert_fields_values() rejects invalid seekr_match vectors", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(10, 20),
    end_line = c(10L, 20L),
    start = c(200L, 250L),
    end = c(202L, 252L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  expect_error(assert_fields_values(x), class = "seekr_error_match_incorrect_fields")
})


# Options assertions ------------------------------------------------------

test_that("assert_seekr_option() accepts valid option values", {
  expect_identical(assert_seekr_option("seekr.progress", TRUE), TRUE)
  expect_identical(assert_seekr_option("seekr.backup_dir", "backups"), "backups")
  expect_identical(assert_seekr_option("seekr.style.match", "31"), "31")
  expect_identical(assert_seekr_option("seekr.print.mode", "plain"), "plain")
  expect_identical(assert_seekr_option("seekr.print.tab", "→"), "→")
  expect_identical(assert_seekr_option("seekr.print.newline", "↵"), "↵")
})

test_that("assert_seekr_option() rejects unknown option names", {
  expect_error(assert_seekr_option("seekr.unknown", TRUE), class = "seekr_error_option_unknown")
})

test_that("assert_seekr_option() rejects invalid option values", {
  expect_error(assert_seekr_option("seekr.progress", NA), class = "seekr_error_option_progress")
  expect_error(assert_seekr_option("seekr.progress", NULL), class = "seekr_error_option_progress")
  expect_error(assert_seekr_option("seekr.backup_dir", character()), class = "seekr_error_option_backup_dir")
  expect_error(assert_seekr_option("seekr.style.match", "red"), class = "seekr_error_option_ansi_style")
  expect_error(assert_seekr_option("seekr.print.mode", "fancy"), class = "seekr_error_option_print_mode")
  expect_error(assert_seekr_option("seekr.print.tab", "->"), class = "seekr_error_option_print_symbol")
  expect_error(assert_seekr_option("seekr.print.newline", "\\n"), class = "seekr_error_option_print_symbol")
})


test_that("assert_option_print_symbol() accepts single display-width characters", {
  expect_no_error(assert_option_print_symbol("seekr.print.tab", "→", "tab", c("→", ">")))
  expect_no_error(assert_option_print_symbol("seekr.print.tab", ">", "tab", c("→", ">")))
  expect_no_error(assert_option_print_symbol("seekr.print.tab", " ", "tab", c("→", ">")))
  expect_no_error(assert_option_print_symbol("seekr.print.newline", "↵", "newline", c("↵", "↓")))
})

test_that("assert_option_print_symbol() rejects non-string values", {
  cls = "seekr_error_option_print_symbol"
  expect_error(assert_option_print_symbol("seekr.print.tab", NA_character_, "tab", c("→", ">")), class = cls)
  expect_error(assert_option_print_symbol("seekr.print.tab", 1L, "tab", c("→", ">")), class = cls)
})

test_that("assert_option_print_symbol() rejects multi-character symbols", {
  cls = "seekr_error_option_print_symbol"
  expect_error(assert_option_print_symbol("seekr.print.tab", "->", "tab", c("→", ">")), class = cls)
  expect_error(assert_option_print_symbol("seekr.print.tab", "abc", "tab", c("→", ">")), class = cls)
})

test_that("assert_option_print_symbol() rejects empty strings", {
  cls = "seekr_error_option_print_symbol"
  expect_error(assert_option_print_symbol("seekr.print.tab", "", "tab", c("→", ">")), class = cls)
})


test_that("assert_option_ansi_style() accepts valid ANSI SGR codes", {
  expect_no_error(assert_option_ansi_style("seekr.style.match", "31"))
  expect_no_error(assert_option_ansi_style("seekr.style.match", "0"))
  expect_no_error(assert_option_ansi_style("seekr.style.match", "1;31"))
  expect_no_error(assert_option_ansi_style("seekr.style.match", "38;5;243"))
  expect_no_error(assert_option_ansi_style("seekr.style.match", "4;1;31"))
})

test_that("assert_option_ansi_style() rejects non-string values", {
  cls = "seekr_error_option_ansi_style"
  expect_error(assert_option_ansi_style("seekr.style.match", 31L), class = cls)
  expect_error(assert_option_ansi_style("seekr.style.match", NA_character_), class = cls)
  expect_error(assert_option_ansi_style("seekr.style.match", c("31", "32")), class = cls)
})

test_that("assert_option_ansi_style() rejects invalid ANSI code shapes", {
  cls = "seekr_error_option_ansi_style"
  expect_error(assert_option_ansi_style("seekr.style.match", "red"), class = cls)
  expect_error(assert_option_ansi_style("seekr.style.match", "31;red"), class = cls)
  expect_error(assert_option_ansi_style("seekr.style.match", ""), class = cls)
  expect_error(assert_option_ansi_style("seekr.style.match", ";31"), class = cls)
  expect_error(assert_option_ansi_style("seekr.style.match", "31;"), class = cls)
})


# List files assertions ---------------------------------------------------

test_that("assert_path_list_files() accepts existing directories", {
  dirs = c(
    test_path("fixtures", "assert"),
    test_path("fixtures", "assert", "dir1"),
    test_path("fixtures", "assert", "dir2", "nested")
 )

  expect_no_error(assert_path_list_files(dirs[[1]]))
  expect_no_error(assert_path_list_files(dirs[[2]]))
  expect_no_error(assert_path_list_files(dirs[[3]]))
  expect_no_error(assert_path_list_files(dirs))
})

test_that("assert_path_list_files() rejects non-existing directories", {
  dirs = c(
    test_path("fixtures", "assert"),
    test_path("fixtures", "assert", "dir1"),
    test_path("fixtures", "assert", "dir2", "nested"),
    test_path("fixtures", "assert", "nonexistent")
 )

  expect_error(assert_path_list_files(dirs), class = "seekr_error_notdir")
  expect_error(assert_path_list_files(dirs[[4]]), class = "seekr_error_notdir")
})

test_that("assert_path_list_files() rejects file paths (not directories)", {
  file = test_path("fixtures", "assert", "root-file.txt")
  expect_error(assert_path_list_files(file), class = "seekr_error_notdir")
})

test_that("assert_path_list_files() rejects vectors with mixed valid/invalid paths", {
  dirs = c(
    test_path("fixtures", "assert", "dir1"),
    test_path("fixtures", "assert", "nonexistent")
 )

  expect_no_error(assert_path_list_files(dirs[[1]]))
  expect_error(assert_path_list_files(dirs), class = "seekr_error_notdir")
})

test_that("assert_path_list_files() rejects NULL", {
  expect_error(assert_path_list_files(NULL), class = "seekr_error_null")
})

test_that("assert_path_list_files() rejects NA", {
  dirs = c(
    test_path("fixtures", "assert", "dir1"),
    NA_character_,
    test_path("fixtures", "assert", "dir2")
 )

  expect_error(assert_path_list_files(dirs), class = "seekr_error_na")
})

test_that("assert_path_list_files() rejects empty strings", {
  dirs = c(
    test_path("fixtures", "assert", "dir1"),
    "",
    test_path("fixtures", "assert", "dir2")
 )

  expect_error(assert_path_list_files(dirs), class = "seekr_error_empty_string")
})

test_that("assert_path_list_files() rejects non-character types", {
  expect_error(assert_path_list_files(1L), class = "seekr_error_class")
})


test_that("assert_recurse() accepts TRUE and FALSE", {
  expect_no_error(assert_recurse(TRUE))
  expect_no_error(assert_recurse(FALSE))
})

test_that("assert_recurse() accepts non-negative integers", {
  expect_no_error(assert_recurse(0L))
  expect_no_error(assert_recurse(1L))
  expect_no_error(assert_recurse(10L))
  expect_no_error(assert_recurse(0.0))
  expect_no_error(assert_recurse(5.0))
})

test_that("assert_recurse() rejects infinites", {
  expect_error(assert_recurse(-Inf), class = "seekr_error_integerish")
  expect_error(assert_recurse(Inf), class = "seekr_error_integerish")
})

test_that("assert_recurse() rejects negative integers", {
  expect_error(assert_recurse(-1L), class = "seekr_error_bounds")
  expect_error(assert_recurse(-10L), class = "seekr_error_bounds")
})

test_that("assert_recurse() rejects non-integer-like numeric", {
  expect_error(assert_recurse(1.5), class = "seekr_error_integerish")
})

test_that("assert_recurse() rejects NULL", {
  expect_error(assert_recurse(NULL), class = "seekr_error_null")
})

test_that("assert_recurse() rejects NA", {
  expect_error(assert_recurse(NA), class = "seekr_error_na")
})

test_that("assert_recurse() rejects character", {
  expect_error(assert_recurse("yes"), class = "seekr_error_class")
})

test_that("assert_recurse() rejects vectors of length > 1", {
  expect_error(assert_recurse(c(TRUE, FALSE)), class = "seekr_error_length")
  expect_error(assert_recurse(c(1L, 2L)), class = "seekr_error_length")
})


test_that("assert_git_available() errors when Git is not available", {
  expect_error(
    assert_git_available(git = ""),
    class = "seekr_error_git_not_available"
  )
})

test_that("assert_git_available() returns invisibly when Git is available", {
  expect_invisible(
    assert_git_available(git = "/usr/bin/git")
  )
})


# Filter files assertions -------------------------------------------------

test_that("assert_extension() accepts NULL", {
  expect_null(assert_extension(NULL))
})

test_that("assert_extension() accepts non-empty character vectors", {
  expect_no_error(assert_extension("R"))
  expect_no_error(assert_extension(c("R", "Rmd", "qmd")))
  expect_no_error(assert_extension(".csv"))
})

test_that("assert_extension() rejects NA", {
  expect_error(assert_extension(NA_character_), class = "seekr_error_na")
  expect_error(assert_extension(c("R", NA_character_)), class = "seekr_error_na")
})

test_that("assert_extension() accepts empty strings", {
  expect_no_error(assert_extension(""))
  expect_no_error(assert_extension(c("R", "")))
})

test_that("assert_extension() rejects empty character vectors", {
  expect_error(assert_extension(character()), class = "seekr_error_length_min")
})

test_that("assert_extension() rejects non-character types", {
  expect_error(assert_extension(1L), class = "seekr_error_class")
})


test_that("assert_max_file_size() accepts Inf", {
  expect_no_error(assert_max_file_size(Inf))
})

test_that("assert_max_file_size() accepts positive integer-like values", {
  expect_no_error(assert_max_file_size(1000L))
  expect_no_error(assert_max_file_size(1000.0))
  expect_no_error(assert_max_file_size(1L))
})

test_that("assert_max_file_size() rejects NA", {
  expect_error(assert_max_file_size(NA_real_), class = "seekr_error_na")
  expect_error(assert_max_file_size(NA_integer_), class = "seekr_error_na")
})

test_that("assert_max_file_size() rejects NULL", {
  expect_error(assert_max_file_size(NULL), class = "seekr_error_null")
})

test_that("assert_max_file_size() rejects non-integerish numeric (except Inf)", {
  expect_error(assert_max_file_size(1.5), class = "seekr_error_integerish")
  expect_error(assert_max_file_size(100.1), class = "seekr_error_integerish")
})

test_that("assert_max_file_size() rejects non-numeric types", {
  expect_error(assert_max_file_size("1000"), class = "seekr_error_class")
  expect_error(assert_max_file_size(TRUE), class = "seekr_error_class")
})

test_that("assert_max_file_size() rejects vectors of length > 1", {
  expect_error(assert_max_file_size(c(100L, 200L)), class = "seekr_error_length")
})


test_that("assert_exclude() accepts NULL", {
  expect_null(assert_exclude(NULL))
})

test_that("assert_exclude() accepts the default exclude_functions", {
  expect_no_error(assert_exclude(exclude_functions))
})

test_that("assert_exclude() accepts a valid named list of functions with arguments", {
  fns = list(
    my_fn1 = function(paths) rep(FALSE, length(paths)),
    my_fn2 = function(paths) rep(TRUE, length(paths))
 )

  expect_no_error(assert_exclude(fns))
})

test_that("assert_exclude() rejects a list containing non-function elements", {
  expect_error(assert_exclude(list(my_fn = "not_a_function")), class = "seekr_error_exclude_functions")
  expect_error(assert_exclude(list(my_fn = 42L)), class = "seekr_error_exclude_functions")
})

test_that("assert_exclude() rejects unnamed lists", {
  fns = list(
    function(paths) rep(FALSE, length(paths)),
    function(paths) rep(TRUE, length(paths))
 )

  expect_error(assert_exclude(fns), class = "seekr_error_exclude_functions")
})

test_that("assert_exclude() rejects lists with empty names", {
  fns = list(
    my_fn1 = function(paths) rep(FALSE, length(paths)),
    my_fn2 = function(paths) rep(TRUE, length(paths))
 )

  names(fns)[[2]] = ""
  expect_error(assert_exclude(fns), class = "seekr_error_exclude_functions_names")
})

test_that("assert_exclude() rejects lists with NA names", {
  fns = list(
    my_fn1 = function(paths) rep(FALSE, length(paths)),
    my_fn2 = function(paths) rep(TRUE, length(paths))
 )

  names(fns)[[2]] = NA_character_
  expect_error(assert_exclude(fns), class = "seekr_error_exclude_functions_names")
})

test_that("assert_exclude() rejects lists with duplicate names", {
  fns = list(
    my_fn = function(paths) rep(FALSE, length(paths)),
    my_fn = function(paths) rep(TRUE, length(paths))
 )

  expect_error(assert_exclude(fns), class = "seekr_error_exclude_functions_names")
})

test_that("assert_exclude() rejects reserved function names", {
  fns = list(
    my_fn1 = function(paths) rep(FALSE, length(paths)),
    my_fn2 = function(paths) rep(TRUE, length(paths))
 )

  names(fns)[[2]] = "exclude_by_extension"
  expect_error(assert_exclude(fns), class = "seekr_error_exclude_functions_names")
  names(fns)[[2]] = "exclude_by_path_pattern"
  expect_error(assert_exclude(fns), class = "seekr_error_exclude_functions_names")
  names(fns)[[2]] = "exclude_by_file_size"
  expect_error(assert_exclude(fns), class = "seekr_error_exclude_functions_names")
})

test_that("assert_exclude() rejects functions with no arguments", {
  fns = list(
    my_fn1 = function(paths) rep(FALSE, length(paths)),
    my_fn2 = function() TRUE
 )

  expect_error(assert_exclude(fns), class = "seekr_error_exclude_functions_arguments")
})

test_that("assert_exclude() rejects functions with only ... as argument", {
  fns = list(
    my_fn1 = function(paths) rep(FALSE, length(paths)),
    my_fn2 = function(...) rep(TRUE, ...)
 )

  expect_error(assert_exclude(fns), class = "seekr_error_exclude_functions_arguments")
})


test_that("assert_exclude_function_return() accepts valid logical vectors", {
  expect_no_error(assert_exclude_function_return(c(TRUE, FALSE, TRUE), len = 3L, arg = "test_fn"))
  expect_no_error(assert_exclude_function_return(logical(), len = 0L, arg = "test_fn"))
  expect_no_error(assert_exclude_function_return(FALSE, len = 1L, arg = "test_fn"))
})

test_that("assert_exclude_function_return() rejects NULL", {
  expect_error(assert_exclude_function_return(NULL, len = 1L, arg = "test_fn"), class = "seekr_error_null")
})

test_that("assert_exclude_function_return() rejects non-logical return values", {
  expect_error(assert_exclude_function_return(c(1L, 0L), len = 2L, arg = "test_fn"), class = "seekr_error_type")
  expect_error(assert_exclude_function_return(c("TRUE", "FALSE"), len = 2L, arg = "test_fn"), class = "seekr_error_type")
})

test_that("assert_exclude_function_return() rejects logical vectors containing NA", {
  expect_error(assert_exclude_function_return(c(TRUE, NA), len = 2L, arg = "test_fn"), class = "seekr_error_na")
  expect_error(assert_exclude_function_return(NA, len = 1L, arg = "test_fn"), class = "seekr_error_na")
})

test_that("assert_exclude_function_return() rejects logical vectors of wrong length", {
  expect_error(assert_exclude_function_return(c(TRUE, FALSE), len = 3L, arg = "test_fn"), class = "seekr_error_length")
  expect_error(assert_exclude_function_return(c(TRUE, FALSE, TRUE), len = 2L, arg = "test_fn"), class = "seekr_error_length")
})


# Match files assertions --------------------------------------------------

test_that("assert_replacement() accepts NULL", {
  expect_null(assert_replacement(NULL, pattern = "foo"))
})

test_that("assert_replacement() accepts a single plain character string", {
  expect_no_error(assert_replacement("bar", pattern = "foo"))
  expect_no_error(assert_replacement("bar", pattern = "foo"))
})

test_that("assert_replacement() accepts a function with at least one named argument", {
  expect_no_error(assert_replacement(toupper, pattern = "foo"))
  expect_no_error(assert_replacement(function(x) toupper(x), pattern = "foo"))
})

test_that("assert_replacement() rejects a function with no arguments", {
  expect_error(assert_replacement(with_capture_groups_matrix(function() "bar"), pattern = "foo"), class = "seekr_error_replacement_noargs")
  expect_error(assert_replacement(function() "bar", pattern = "foo"), class = "seekr_error_replacement_noargs")
})

test_that("assert_replacement() rejects a with_capture_groups_matrix function with non-regex pattern", {
  fn = with_capture_groups_matrix(function(m) m[, 1])
  expect_error(assert_replacement(fn, pattern = stringr::fixed("foo")), class = "seekr_error_replacement_groups_pattern")
  expect_error(assert_replacement(fn, pattern = stringr::coll("foo")), class = "seekr_error_replacement_groups_pattern")
})

test_that("assert_replacement() accepts a with_capture_groups_matrix function with regex pattern", {
  fn = with_capture_groups_matrix(function(m) m[, 1])
  expect_no_error(assert_replacement(fn, pattern = stringr::regex("(foo)")))
  expect_no_error(assert_replacement(fn, pattern = "(foo)"))
})

test_that("assert_replacement() rejects NA_character_", {
  expect_error(assert_replacement(NA_character_, pattern = "foo"), class = "seekr_error_na")
})

test_that("assert_replacement() rejects empty character vectors", {
  expect_error(assert_replacement(character(), pattern = "foo"), class = "seekr_error_length")
})

test_that("assert_replacement() rejects character vectors of length > 1", {
  expect_error(assert_replacement(c("bar", "baz"), pattern = "foo"), class = "seekr_error_length")
})


test_that("assert_context() accepts a single non-negative integer", {
  expect_no_error(assert_context(0L))
  expect_no_error(assert_context(5L))
  expect_no_error(assert_context(5.0))
  expect_no_error(assert_context(100L))
})

test_that("assert_context() accepts a pair of non-negative integers", {
  expect_no_error(assert_context(c(3L, 5L)))
  expect_no_error(assert_context(c(0L, 10L)))
  expect_no_error(assert_context(c(0L, 0L)))
})

test_that("assert_context() rejects negative values", {
  expect_error(assert_context(-1L), class = "seekr_error_bounds")
  expect_error(assert_context(c(-1L, 5L)), class = "seekr_error_bounds")
  expect_error(assert_context(c(5L, -1L)), class = "seekr_error_bounds")
})

test_that("assert_context() rejects vectors of length > 2", {
  expect_error(assert_context(c(1L, 2L, 3L)), class = "seekr_error_length_max")
})

test_that("assert_context() rejects non-integerish values", {
  expect_error(assert_context(1.5), class = "seekr_error_integerish")
  expect_error(assert_context(c(1L, 1.5)), class = "seekr_error_integerish")
})

test_that("assert_context() rejects NA", {
  expect_error(assert_context(NA_integer_), class = "seekr_error_na")
  expect_error(assert_context(NA_real_), class = "seekr_error_na")
})

test_that("assert_context() rejects NULL", {
  expect_error(assert_context(NULL), class = "seekr_error_null")
})

test_that("assert_context() rejects character", {
  expect_error(assert_context("5"), class = "seekr_error_class")
})


test_that("assert_encoding() accepts NULL", {
  expect_null(assert_encoding(NULL))
})

test_that("assert_encoding() accepts valid encoding strings", {
  expect_no_error(assert_encoding("UTF-8"))
  expect_no_error(assert_encoding("latin1"))
  expect_no_error(assert_encoding("windows-1252"))
})

test_that("assert_encoding() rejects NA", {
  expect_error(assert_encoding(NA_character_), class = "seekr_error_na")
})

test_that("assert_encoding() rejects empty strings", {
  expect_error(assert_encoding(""), class = "seekr_error_empty_string")
})

test_that("assert_encoding() rejects vectors of length > 1", {
  expect_error(assert_encoding(c("UTF-8", "latin1")), class = "seekr_error_length")
})


test_that("assert_file_text() accepts a single character string", {
  expect_no_error(assert_file_text("some text"))
  expect_no_error(assert_file_text(""))
  expect_no_error(assert_file_text("line1\nline2\n"))
})

test_that("assert_file_text() rejects NULL", {
  expect_error(assert_file_text(NULL), class = "seekr_error_null")
})

test_that("assert_file_text() rejects NA", {
  expect_error(assert_file_text(NA_character_), class = "seekr_error_na")
})

test_that("assert_file_text() rejects vectors of length > 1", {
  expect_error(assert_file_text(c("a", "b")), class = "seekr_error_length")
})

test_that("assert_file_text() rejects non-character types", {
  expect_error(assert_file_text(1L), class = "seekr_error_class")
  expect_error(assert_file_text(TRUE), class = "seekr_error_class")
})


test_that("assert_replacement_function_return() accepts a character vector of correct length", {
  expect_no_error(assert_replacement_function_return(c("a", "b", "c"), len = 3L))
  expect_no_error(assert_replacement_function_return(character(), len = 0L))
  expect_no_error(assert_replacement_function_return("x", len = 1L))
})

test_that("assert_replacement_function_return() rejects non-character return values", {
  cls =
  expect_error(assert_replacement_function_return(NULL, len = 0L), class = "seekr_error_null")
  expect_error(assert_replacement_function_return(1:3, len = 3L), class = "seekr_error_class")
  expect_error(assert_replacement_function_return(list("a", "b"), len = 2L), class = "seekr_error_class")
})

test_that("assert_replacement_function_return() rejects character vectors of wrong length", {
  cls = "seekr_error_replacement_function_return_length"
  expect_error(assert_replacement_function_return(c("a", "b"), len = 3L), class = "seekr_error_length")
  expect_error(assert_replacement_function_return(c("a", "b", "c"), len = 2L), class = "seekr_error_length")
})


# Backup assertions -------------------------------------------------------

test_that("assert_backup_description() accepts NA_character_", {
  expect_no_error(assert_backup_description(NA_character_))
})

test_that("assert_backup_description() accepts a single character string", {
  expect_no_error(assert_backup_description("my backup"))
  expect_no_error(assert_backup_description(""))
})

test_that("assert_backup_description() rejects NULL", {
  expect_error(assert_backup_description(NULL), class = "seekr_error_null")
})

test_that("assert_backup_description() rejects character vectors of length > 1", {
  expect_error(assert_backup_description(c("a", "b")), class = "seekr_error_length")
})

test_that("assert_backup_description() rejects non-character types", {
  expect_error(assert_backup_description(1L), class = "seekr_error_class")
  expect_error(assert_backup_description(TRUE), class = "seekr_error_class")
})


test_that("assert_id() accepts integer and integerish vectors", {
  expect_equal(assert_id(c(1L, 2L, 3L)), c(1L, 2L, 3L))
  expect_equal(assert_id(c(1, 2, 3)), c(1, 2, 3))
  expect_equal(assert_id(integer()), integer())
})

test_that("assert_id() rejects NULL", {
  expect_error(
    assert_id(NULL),
    class = "seekr_error_null"
 )
})

test_that("assert_id() rejects missing values", {
  expect_error(
    assert_id(NA_integer_),
    class = "seekr_error_na"
 )

  expect_error(
    assert_id(c(1L, NA_integer_)),
    class = "seekr_error_na"
 )
})

test_that("assert_id() rejects non-numeric vectors", {
  expect_error(
    assert_id("1"),
    class = "seekr_error_class"
 )

  expect_error(
    assert_id(TRUE),
    class = "seekr_error_class"
 )
})

test_that("assert_id() rejects non-integerish numeric values", {
  expect_error(
    assert_id(1.5),
    class = "seekr_error_integerish"
 )

  expect_error(
    assert_id(c(1, 2.5)),
    class = "seekr_error_integerish"
 )
})


# Replacements assertions -------------------------------------------------

test_that("assert_match_for_replacement() rejects non-seekr_match objects", {
  expect_error(assert_match_for_replacement("not a match"), class = "seekr_error_class")
  expect_error(assert_match_for_replacement(NULL), class = "seekr_error_null")
  expect_error(assert_match_for_replacement(list()), class = "seekr_error_class")
})

test_that("assert_match_for_replacement() accepts matches with concrete replacement values", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 250L),
    end = c(202L, 252L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
 )

  expect_s3_class(assert_match_for_replacement(x), "seekr_match")
})

test_that("assert_match_for_replacement() rejects missing replacement values", {
  x = new_seekr_match(
    path = c("foo.txt", "bar.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 250L),
    end = c(202L, 252L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", NA_character_),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
 )

  expect_error(assert_match_for_replacement(x), class = "seekr_error_replacement_na_for_replacement")
})

test_that("assert_match_for_replacement() rejects multiple encodings for the same file", {
  x = new_seekr_match(
    path = c("foo.R", "foo.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 250L),
    end = c(202L, 252L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-16"),
    hash = c("abc", "abc")
 )

  expect_error(assert_match_for_replacement(x), class = "seekr_error_match_single_source_multiple_encoding")
})

test_that("assert_match_for_replacement() rejects multiple hashes for the same file", {
  x = new_seekr_match(
    path = c("foo.R", "foo.R"),
    start_line = c(10L, 20L),
    end_line = c(10L, 20L),
    start = c(200L, 250L),
    end = c(202L, 252L),
    start_col = c(4L, 20L),
    end_col = c(6L, 22L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = rep(NA_character_, 2L),
    line = c("blafoo...", "1234567890123456789bar"),
    after = rep(NA_character_, 2L),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("aaa", "bbb")
 )

  expect_error(assert_match_for_replacement(x), class = "seekr_error_match_single_source_multiple_hash")
})


test_that("assert_hash_for_replacement() accepts unchanged text", {
  text = "hello old_name\nbye old_name"

  x = match_text(
    text = text,
    path = "example.txt",
    pattern = "old_name",
    replacement = "new_name"
  )

  expect_no_error(assert_hash_for_replacement(text, x))
})

test_that("assert_hash_for_replacement() accepts empty match vectors", {
  text = "hello old_name\nbye old_name"
  x = new_seekr_match()

  expect_no_error(assert_hash_for_replacement(text, x))
})

test_that("assert_hash_for_replacement() rejects changed text", {
  text = "hello old_name\nbye old_name"

  x = match_text(
    text = text,
    path = "example.txt",
    pattern = "old_name",
    replacement = "new_name"
  )

  changed_text = "hello old_name\nbye changed_name"

  expect_error(
    assert_hash_for_replacement(changed_text, x),
    class = "seekr_error_replacement_hash_changed"
  )
})


# Restore files assertions ------------------------------------------------

test_that("assert_restore_from_to() rejects NULL `from` or `to`", {
  expect_error(assert_restore_from_to(NULL, "/dest/file.R"), class = "seekr_error_null")
  expect_error(assert_restore_from_to("/src/file.R", NULL), class = "seekr_error_null")
})

test_that("assert_restore_from_to() rejects NA `from` or `to`", {
  expect_error(assert_restore_from_to(NA_character_, "/dest/file.R"), class = "seekr_error_na")
  expect_error(assert_restore_from_to("/src/file.R", NA_character_), class = "seekr_error_na")
})

test_that("assert_restore_from_to() rejects empty strings in `from` or `to`", {
  expect_error(assert_restore_from_to("", "/dest/file.R"), class = "seekr_error_empty_string")
  expect_error(assert_restore_from_to("/src/file.R", ""), class = "seekr_error_empty_string")
})

test_that("assert_restore_from_to() rejects non-character `from` or `to`", {
  expect_error(assert_restore_from_to(1L, "/dest/file.R"), class = "seekr_error_class")
  expect_error(assert_restore_from_to("/src/file.R", 1L), class = "seekr_error_class")
})

test_that("assert_restore_from_to() rejects `from` and `to` of different lengths", {
  expect_error(
    assert_restore_from_to(from = c("foo", "bar"), to = c("foo")),
    class = "seekr_error_restore_from_to_lengths"
 )
})

test_that("assert_restore_from_to() rejects missing `from` files", {
  expect_error(
    assert_restore_from_to(
      from = "/nonexistent/path/backup.R",
      to = "/some/dest/file.R"
   ),
    class = "seekr_error_restore_missing_backup"
 )
})

test_that("assert_restore_from_to() rejects directories in `from`", {
  from_dir = withr::local_tempdir()

  expect_error(
    assert_restore_from_to(
      from = from_dir,
      to = "/some/dest/file.R"
   ),
    class = "seekr_error_restore_from_is_directory"
 )
})

test_that("assert_restore_from_to() rejects exact duplicate `to` paths", {
  tmp1 = withr::local_tempfile(lines = "foo")
  tmp2 = withr::local_tempfile(lines = "bar")

  expect_error(
    assert_restore_from_to(
      from = c(tmp1, tmp2),
      to = c("/dest/file.R", "/dest/file.R")
   ),
    class = "seekr_error_restore_duplicate_destination"
 )
})

test_that("assert_restore_from_to() rejects normalized duplicate `to` paths", {
  tmp1 = withr::local_tempfile(lines = "foo")
  tmp2 = withr::local_tempfile(lines = "bar")

  dest_dir = withr::local_tempdir()
  dest = file.path(dest_dir, "file.R")
  dest_same = file.path(dest_dir, ".", "file.R")

  expect_error(
    assert_restore_from_to(
      from = c(tmp1, tmp2),
      to = c(dest, dest_same)
   ),
    class = "seekr_error_restore_duplicate_destination"
 )
})

test_that("assert_restore_from_to() rejects existing directories in `to`", {
  tmp = withr::local_tempfile(lines = "foo")
  to_dir = withr::local_tempdir()

  expect_error(
    assert_restore_from_to(
      from = tmp,
      to = to_dir
   ),
    class = "seekr_error_restore_to_is_directory"
 )
})

test_that("assert_restore_from_to() accepts missing destination files", {
  tmp = withr::local_tempfile(lines = "foo")
  to = file.path(withr::local_tempdir(), "new-file.R")

  expect_no_error(assert_restore_from_to(from = tmp, to = to))
})

test_that("assert_restore_from_to() returns a list with `from` and `to` on success", {
  tmp1 = withr::local_tempfile()
  tmp2 = withr::local_tempfile()
  writeLines("a", tmp1)
  writeLines("b", tmp2)

  expected = list(from = c(tmp1, tmp2), to = c("/dest/a.R", "/dest/b.R"))
  result = assert_restore_from_to(from = expected$from, to = expected$to)

  expect_identical(result, expected)
})


# Others assertions -------------------------------------------------------

test_that("assert_filter_match_result() accepts logical vectors of the expected length", {
  x = c(TRUE, FALSE, TRUE)
  expect_equal(assert_filter_match_result(x, len = 3L), x)
  expect_equal(assert_filter_match_result(logical(), len = 0L), logical())
})

test_that("assert_filter_match_result() rejects NULL", {
  expect_error(
    assert_filter_match_result(NULL, len = 3L),
    class = "seekr_error_filter_match_result_null"
 )
})

test_that("assert_filter_match_result() rejects non-logical vectors", {
  cls = "seekr_error_filter_match_result_type"
  expect_error(assert_filter_match_result(c("TRUE", "FALSE"), len = 2L), class = cls)
  expect_error(assert_filter_match_result(c(0, 1), len = 2L), class = cls)
})

test_that("assert_filter_match_result() rejects missing values", {
  cls = "seekr_error_filter_match_result_na"
  expect_error(assert_filter_match_result(c(TRUE, NA, FALSE), len = 3L), class = cls)
  expect_error(assert_filter_match_result(NA, len = 1L), class = cls)
})

test_that("assert_filter_match_result() rejects vectors of incorrect length", {
  cls = "seekr_error_filter_match_result_length"
  expect_error(assert_filter_match_result(TRUE, len = 3L), class = cls)
  expect_error(assert_filter_match_result(c(TRUE, FALSE), len = 3L), class = cls)
  expect_error(assert_filter_match_result(c(TRUE, FALSE), len = 0L), class = cls)
})


test_that("assert_n_print() accepts NULL", {
  expect_null(assert_n_print(NULL))
})

test_that("assert_n_print() accepts positive integer values", {
  expect_identical(assert_n_print(10L), 10L)
})

test_that("assert_n_print() accepts positive numeric integerish values", {
  expect_identical(assert_n_print(10), 10)
})

test_that("assert_n_print() accepts zero", {
  expect_identical(assert_n_print(0L), 0L)
  expect_identical(assert_n_print(0), 0)
})

test_that("assert_n_print() rejects missing values", {
  expect_error(assert_n_print(NA_integer_), class = "seekr_error_na")
  expect_error(assert_n_print(NA_real_), class = "seekr_error_na")
})

test_that("assert_n_print() rejects empty vectors", {
  expect_error(assert_n_print(integer()), class = "seekr_error_length_min")
  expect_error(assert_n_print(numeric()), class = "seekr_error_length_min")
})

test_that("assert_n_print() accepts positive Inf", {
  expect_identical(assert_n_print(Inf), Inf)
})

test_that("assert_n_print() rejects vectors of length greater than one", {
  expect_error(assert_n_print(c(1L, 2L)), class = "seekr_error_length_max")
  expect_error(assert_n_print(c(1, 2)), class = "seekr_error_length_max")
})

test_that("assert_n_print() rejects non-numeric values", {
  expect_error(assert_n_print("10"), class = "seekr_error_class")
  expect_error(assert_n_print(TRUE), class = "seekr_error_class")
  expect_error(assert_n_print(list(10L)), class = "seekr_error_class")
})

test_that("assert_n_print() rejects non-integerish and negative numeric values", {
  expect_error(assert_n_print(1.5))
  expect_error(assert_n_print(-1.5))
  expect_error(assert_n_print(-Inf))
})
