# prepare_vctrs_header_ansi ----------------------------------------------

test_that("prepare_vctrs_header_ansi() formats the match count", {
  out = prepare_vctrs_header_ansi(n_matches = 3L)
  expect_identical(cli::ansi_strip(out), "<seekr::match[3]>")
})

test_that("prepare_vctrs_header_ansi() formats singular file counts", {
  out = prepare_vctrs_header_ansi(n_matches = 3L, n_files = 1L)
  expect_identical(cli::ansi_strip(out), "<seekr::match[3]> 1 source")
})

test_that("prepare_vctrs_header_ansi() formats plural file counts", {
  out = prepare_vctrs_header_ansi(n_matches = 3L, n_files = 2L)
  expect_identical(cli::ansi_strip(out), "<seekr::match[3]> 2 sources")
})

test_that("prepare_vctrs_header_ansi() formats zero file counts as plural", {
  out = prepare_vctrs_header_ansi(n_matches = 0L, n_files = 0L)
  expect_identical(cli::ansi_strip(out), "<seekr::match[0]> 0 sources")
})

test_that("prepare_vctrs_header_ansi() can include the vctrs class", {
  out = prepare_vctrs_header_ansi( n_matches = 3L, n_files = 2L, print_vctrs = TRUE)
  expect_identical(cli::ansi_strip(out), "<seekr::match[3]> 2 sources vctrs::rcrd")
})


# create_osc8_file --------------------------------------------------------

test_that("create_osc8_file() returns plain paths in plain mode", {
  withr::local_options(seekr.print.mode = "plain")

  out = create_osc8_file(
    display_path = "R/file.R",
    absolute_path = "/tmp/project/R/file.R"
  )

  expect_identical(as.character(out), "R/file.R")
})

test_that("create_osc8_file() keeps match counts in plain mode", {
  withr::local_options(seekr.print.mode = "plain")

  out = create_osc8_file(
    display_path = "R/file.R",
    absolute_path = "/tmp/project/R/file.R",
    n_of = "[4/10]"
  )

  expect_identical(cli::ansi_strip(out), "R/file.R [4/10]")
})

test_that("create_osc8_file() creates OSC8 links outside plain mode", {
  withr::local_options(seekr.print.mode = "rich")

  testthat::local_mocked_bindings(
    file_exists = function(path) TRUE,
    .package = "fs"
  )

  out = as.character(create_osc8_file(
    display_path = "R/file.R",
    absolute_path = "/tmp/project/R/file.R"
  ))

  expect_true(grepl("\033]8;;file:///tmp/project/R/file.R", out, fixed = TRUE))
  expect_true(grepl("R/file.R", out, fixed = TRUE))
  expect_true(grepl("\033]8;;\a", out, fixed = TRUE))
})

test_that("create_osc8_file() appends match counts outside plain mode", {
  withr::local_options(seekr.print.mode = "rich")

  out = create_osc8_file(
    display_path = "R/file.R",
    absolute_path = "/tmp/project/R/file.R",
    n_of = "[4/10]"
  )

  expect_identical(cli::ansi_strip(out), "R/file.R [4/10]")
})


test_that("create_osc8_file() works with 'color' mode", {
  withr::local_options(seekr.print.mode = "color")

  out = create_osc8_file(
    display_path = "R/file.R",
    absolute_path = "/tmp/project/R/file.R",
    n_of = "[4/10]"
  )

  expect_identical(cli::ansi_strip(out), "R/file.R [4/10]")
})


# create_osc8_dir ---------------------------------------------------------

test_that("create_osc8_dir() returns plain paths in plain mode", {
  withr::local_options(seekr.print.mode = "plain")
  out = create_osc8_dir(display_path = "R", absolute_path = "/tmp/project/R")
  expect_identical(as.character(out), "R")
})

test_that("create_osc8_dir() returns colored paths in color mode", {
  withr::local_options(seekr.print.mode = "color")
  out = create_osc8_dir(display_path = "R", absolute_path = "/tmp/project/R")
  expect_identical(cli::ansi_strip(out), "R")
})

test_that("create_osc8_dir() creates IDE links outside plain mode", {
  withr::local_options(seekr.print.mode = "rich")

  testthat::local_mocked_bindings(
    file_exists = function(path) TRUE,
    .package = "fs"
  )

  out = as.character(create_osc8_dir(display_path = "R", absolute_path = "tmp/R"))
  expect_identical(out, "\033]8;;ide:run:fs::file_show(\"tmp/R\")\a\033[1;34mR\033[0m\033]8;;\a")
})


# create_osc8_match -------------------------------------------------------

test_that("create_osc8_match() returns plain strings in plain mode", {
  withr::local_options(seekr.print.mode = "plain")

  out = create_osc8_match(
    string = "foo",
    absolute_path = "/tmp/project/R/file.R",
    start_line = 12L,
    start_col = 4L
  )

  expect_identical(out, "foo")
})

test_that("create_osc8_match() returns plain strings in color mode", {
  withr::local_options(seekr.print.mode = "color")

  out = create_osc8_match(
    string = "foo",
    absolute_path = "/tmp/project/R/file.R",
    start_line = 12L,
    start_col = 4L
  )

  expect_identical(out, "foo")
})

test_that("create_osc8_match() creates file links with line and column outside plain mode", {
  withr::local_options(seekr.print.mode = "rich")

  testthat::local_mocked_bindings(
    file_exists = function(path) TRUE,
    .package = "fs"
  )

  out = create_osc8_match(
    string = "foo",
    absolute_path = "/tmp/project/R/file.R",
    start_line = 12L,
    start_col = 4L
  )

  expect_identical(
    as.character(out),
    "\033]8;line = 12:col = 4;file:///tmp/project/R/file.R\afoo\033]8;;\a"
  )
})


# escape_newlines ---------------------------------------------------------

test_that("escape_newlines() escapes line feeds", {
  expect_identical(escape_newlines("a\nb"), "a\\nb")
})

test_that("escape_newlines() escapes carriage returns", {
  expect_identical(escape_newlines("a\rb"), "a\\rb")
})

test_that("escape_newlines() escapes CRLF sequences", {
  expect_identical(escape_newlines("a\r\nb"), "a\\r\\nb")
})

test_that("escape_newlines() is vectorized", {
  expect_identical(escape_newlines(c("a\nb", "c\rd", "e\r\nf")), c("a\\nb", "c\\rd", "e\\r\\nf"))
})

test_that("escape_newlines() preserves missing values", {
  expect_identical(escape_newlines(NA_character_), NA_character_)
})


# truncate ----------------------------------------------------------------

test_that("truncate_left/center/right returns a string with the correct length", {
  expect_identical(truncate_left("abcdef", 3L), "\u2026ef")
  expect_identical(truncate_center("abcdef", 3L), "a\u2026f")
  expect_identical(truncate_right("abcdef", 3L), "ab\u2026")
})

test_that("truncate_left/center/right leaves short strings unchanged", {
  expect_identical(truncate_left("abc", 10L), "abc")
  expect_identical(truncate_center("abc", 10L), "abc")
  expect_identical(truncate_right("abc", 10L), "abc")
})


# truncate_right_ansi -----------------------------------------------------

test_that("truncate_right_ansi() leaves short ANSI strings unchanged", {
  x = ansi_option("foo", "match")
  out = truncate_right_ansi(x, 10L)

  expect_identical(out, x)
})

test_that("truncate_right_ansi() truncates plain strings and appends an ellipsis", {
  x = "abcdef"
  out = truncate_right_ansi(x, 5L)

  expect_identical(out, "abcd\u2026")
})

test_that("truncate_right_ansi() truncates ANSI strings and appends an ellipsis", {
  x = ansi_option("abcdef", "match")
  out = truncate_right_ansi(x, 5L)

  expect_identical(cli::ansi_strip(out), "abcd\u2026")
  expect_equal(cli::ansi_nchar(out), 5L)
})

test_that("truncate_right_ansi() inserts the ellipsis before trailing ANSI SGR codes", {
  x = "\033[31mabcdef\033[39m"
  out = truncate_right_ansi(x, 3L)

  expect_identical(out, paste0("\033[31m", "ab\u2026", "\033[39m"))
  expect_identical(cli::ansi_strip(out), "ab\u2026")
  expect_equal(cli::ansi_nchar(out), 3L)
})

test_that("truncate_right_ansi() keeps the ellipsis inside an open ANSI style", {
  x = "\033[31mabcdef"
  out = truncate_right_ansi(x, 3L)

  expect_identical(out, paste0("\033[31m", "ab\u2026", "\033[39m"))
  expect_identical(cli::ansi_strip(out), "ab\u2026")
  expect_equal(cli::ansi_nchar(out), 3L)
})


# replace_all_tabs_for_printing ------------------------------------------

test_that("replace_all_tabs_for_printing() replaces tabs with the configured string", {
  withr::local_options(seekr.print.tab = " ")

  expect_identical(
    replace_all_tabs_for_printing("a\tb"),
    "a b"
  )
})

test_that("replace_all_tabs_for_printing() is vectorized", {
  withr::local_options(seekr.print.tab = "T")

  expect_identical(
    replace_all_tabs_for_printing(c("a\tb", "c\td")),
    c("aTb", "cTd")
  )
})

test_that("replace_all_tabs_for_printing() leaves strings without tabs unchanged", {
  withr::local_options(seekr.print.tab = "T")

  expect_identical(
    replace_all_tabs_for_printing("abc"),
    "abc"
  )
})


# plur --------------------------------------------------------------------

test_that("plur() returns an empty string for singular numeric values", {
  expect_identical(plur(1L, "s"), "")
  expect_identical(plur(1, "s"), "")
})

test_that("plur() returns plural suffixes for zero and numeric values other than one", {
  expect_identical(plur(0L, "s"), "s")
  expect_identical(plur(2L, "s"), "s")
  expect_identical(plur(-1L, "s"), "s")
})

test_that("plur() returns plural suffixes for vectors of length greater than one", {
  expect_identical(plur(c(1L, 2L), "s"), "s")
})

test_that("plur() returns an empty string for missing numeric values", {
  expect_identical(plur(NA_real_, "s"), "")
})

test_that("plur() returns an empty string for scalar non-numeric values", {
  expect_identical(plur("x", "s"), "")
})


# compute_n_print ---------------------------------------------------------

test_that("compute_n_print() returns the vector length when n is NULL and length is below the threshold", {
  x = seq_len(5L)
  expect_identical(compute_n_print(x, n = NULL), 5L)
})

test_that("compute_n_print() returns the vector length when n is NULL and length equals the threshold", {
  x = seq_len(20L)
  expect_identical(compute_n_print(x, n = NULL), 20L)
})

test_that("compute_n_print() returns the default when n is NULL and length is above the threshold", {
  x = seq_len(21L)
  expect_identical(compute_n_print(x, n = NULL), 10L)
})

test_that("compute_n_print() uses data frame rows instead of length", {
  x = data.frame(a = seq_len(21L), b = seq_len(21L))
  expect_identical(compute_n_print(x, n = NULL), 10L)
})

test_that("compute_n_print() returns n when n is lower than the object size", {
  x = seq_len(20L)
  expect_identical(compute_n_print(x, n = 3L), 3L)
})

test_that("compute_n_print() returns the object size when n is greater than the object size", {
  x = seq_len(5L)
  expect_identical(compute_n_print(x, n = 10L), 5L)
})

test_that("compute_n_print() supports n equal to zero", {
  x = seq_len(5L)
  expect_identical(compute_n_print(x, n = 0L), 0L)
})
