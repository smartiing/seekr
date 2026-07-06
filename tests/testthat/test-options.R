# seekr_option() -----------------------------------------------------------

test_that("seekr_option() returns the default value when the option is unset", {
  withr::with_options(
    list(seekr.progress = NULL), {
      result = seekr_option("seekr.progress")
      expect_equal(result, rlang::is_interactive())
    }
  )
})

test_that("seekr_option() returns user-defined option values", {
  withr::with_options(
    list(seekr.progress = FALSE),
    expect_equal(seekr_option("seekr.progress"), FALSE)
  )

  withr::with_options(
    list(seekr.print.mode = "rich"),
    expect_equal(seekr_option("seekr.print.mode"), "rich")
  )

  withr::with_options(
    list(seekr.print.mode = "plain"),
    expect_equal(seekr_option("seekr.print.mode"), "plain")
  )
})

test_that("seekr_option() resolves all known options", {
  all_options = names(seekr_options_defaults())
  for (option in all_options) {
    expect_no_error(seekr_option(option))
  }
})

test_that("seekr_option() rejects invalid option names", {
  error_class = "seekr_error_option_name"
  expect_error(seekr_option(NULL), class = error_class)
  expect_error(seekr_option(NA), class = error_class)
  expect_error(seekr_option(NA_character_), class = error_class)
  expect_error(seekr_option(123), class = error_class)
  expect_error(seekr_option(c("seekr.progress", "seekr.print.mode")), class = error_class)
})

test_that("seekr_option() rejects unknown options", {
  error_class = "seekr_error_option_unknown"
  expect_error(seekr_option(""), class = error_class)
  expect_error(seekr_option("not_seekr"), class = error_class)
  expect_error(seekr_option("seekr.unknown"), class = error_class)
})

test_that("seekr_option() assert user-defined option values", {
  withr::with_options(
    list(seekr.print.mode = "fancy"),
    expect_error(
      seekr_option("seekr.print.mode"),
      class = "seekr_error_option_print_mode"
    )
  )

  withr::with_options(
    list(seekr.progress = NA),
    expect_error(
      seekr_option("seekr.progress"),
      class = "seekr_error_option_progress"
    )
  )
})


# seekr_options() ---------------------------------------------------------

test_that("seekr_options() returns a tibble with the expected columns", {
  result = seekr_options()
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("name", "current", "default"))
  expect_type(result$name, "character")
  expect_type(result$current, "character")
  expect_type(result$default, "character")
})

test_that("seekr_options() includes all known options", {
  result = seekr_options()
  defaults = seekr_options_defaults()
  expect_equal(result$name, names(defaults))
})

test_that("seekr_options() reports user-defined option values", {
  withr::with_options(
    list(seekr.progress = FALSE),
    {
      result = seekr_options()
      expect_equal(
        result$current[result$name == "seekr.progress"],
        "FALSE"
      )
    }
  )
})

test_that("seekr_options() reports NA for unset options", {
  all_options = names(seekr_options_defaults())
  test_options = structure(vector("list", length(all_options)), names = all_options)

  withr::with_options(
    test_options,
    {
      result = seekr_options()
      expect_true(all(is.na(result$current)))
    }
  )
})

test_that("seekr_options() always reports non-missing default values", {
  result = seekr_options()
  expect_false(any(is.na(result$default)))
})


# seekr_options_defaults() ------------------------------------------------

test_that("seekr_options_defaults() returns a list with all default options", {
  result = seekr_options_defaults()
  expect_type(result, "list")
  expect_named(
    result,
    c(
      "seekr.progress",
      "seekr.backup_dir",
      "seekr.style.match_only",
      "seekr.style.match",
      "seekr.style.replacement",
      "seekr.style.dim",
      "seekr.style.class",
      "seekr.style.osc8_file",
      "seekr.style.osc8_dir",
      "seekr.style.na",
      "seekr.print.mode",
      "seekr.print.tab",
      "seekr.print.newline"
    )
  )
})


test_that("seekr_options_defaults() returns valid default option values", {
  result = seekr_options_defaults()
  for (name in names(result)) {
    expect_no_error(assert_seekr_option(name, result[[name]]))
  }
})


# default_print_mode() ----------------------------------------------------

test_that("default_print_mode() returns plain when colors are not supported", {
  expect_identical(
    default_print_mode(n_colors = 1L, support_osc8 = TRUE, in_knitr = FALSE),
    "plain"
  )
})

test_that("default_print_mode() returns color when colors are supported but OSC8 is not", {
  expect_identical(
    default_print_mode(n_colors = 256L, support_osc8 = FALSE, in_knitr = FALSE),
    "color"
  )
})

test_that("default_print_mode() returns color when running inside knitr", {
  expect_identical(
    default_print_mode(n_colors = 256L, support_osc8 = TRUE, in_knitr = TRUE),
    "color"
  )
})

test_that("default_print_mode() returns rich when colors and OSC8 are supported outside knitr", {
  expect_identical(
    default_print_mode(n_colors = 256L, support_osc8 = TRUE, in_knitr = FALSE),
    "rich"
  )
})


# ansi_option() -----------------------------------------------------------

test_that("ansi_option() returns input unchanged in plain mode", {
  withr::with_options(
    list(seekr.print.mode = "plain"),
    expect_equal(ansi_option("hello", "match"), "hello")
  )
})

test_that("ansi_option() applies ANSI codes in rich mode", {
  withr::with_options(
    list(
      seekr.print.mode = "rich",
      seekr.style.match = "31"
    ), {
      result = ansi_option(c("hello", "world"), "match")
      expect_equal(
        result,
        c("\033[31mhello\033[0m", "\033[31mworld\033[0m")
      )
    }
  )
})

test_that("ansi_option() rejects invalid style arguments", {
  expect_error(
    ansi_option("hello", c("match", "dim")),
    class = "seekr_error_internal_ansi_style"
  )

  expect_error(
    ansi_option("hello", NA_character_),
    class = "seekr_error_internal_ansi_style"
  )
})
