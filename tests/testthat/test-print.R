test_that("print works", {
  withr::local_message_sink(nullfile())
  # Test print lines
  text =
    "
    {singleline_match_at_the_start}
    aaaaaaaaaaaaaaaaaaaaaaaa{singleline_match_in_the_middle}
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa{singleline_match_close_to_end}
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa{singleline_very_loooooooooooooooooooooooooooooooooooooonnnnnnnnnnnnnnnnnnnnnnng_match}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

    {multiline_first_line_at_start
    blablabla
    blablabla
    blablabla
    multiline_end_line_at_start}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa


    aaaaaaaaaaaaaaaaaaaa{multiline_first_line_in_the_middle
    blablabla\t\t\tblablabla
    blablabla123
    blablabla
    aaaaaaaaaaaaaaaaaaaaaamultiline_end_line_in_the_middle}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa


    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa{multiline_first_line_at_the_end
    blablabla
    blablabla
    blablabla
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaamultiline_end_line_at_the_end}a

    This is a {very long singleline match that will be center around the start rather than the middle because it is too wide}
    "

  x = match_text(
    text = text,
    path = "dummy_path",
    pattern = stringr::regex("\\{.+?\\}", dotall = TRUE),
    replacement = "blablabla"
  )

  expect_no_error(capture.output(print(x[0])))
  expect_no_error(capture.output(print(x[c(3, 2, 1)])))
  expect_no_error(capture.output(print(x, n = 4)))

  field(x[[2]], "replacement") = NA_character_
  field(x[[3]], "replacement") = "blablabla\nblablabla"
  expect_no_error(capture.output(print(x, n = 4)))

  y = match_text(text, "dummy_path", "\\w{2}")
  expect_no_error(capture.output(print(y)))

  for (w in c(150, 50, 10)) {
    withr::local_options(cli.width = w)
    expect_no_error(capture.output(print(x, n = Inf, context = c(0))))
    expect_no_error(capture.output(print(x, n = Inf, context = c(1L,0L))))
    expect_no_error(capture.output(print(x, n = Inf, context = c(0L,3L))))
    expect_no_error(capture.output(print(x, n = Inf, context = c(3L,0L))))
    expect_no_error(capture.output(print(x, n = Inf, context = c(5L,5L))))
  }
})


test_that("print.seekr_match() prints a common path when several files share one", {
  withr::local_message_sink(nullfile())
  withr::local_options(list(seekr.print.mode = "plain"))

  common_dir = file.path(withr::local_tempdir(), "long-common-directory")
  path1 = file.path(common_dir, "script1.R")
  path2 = file.path(common_dir, "script2.R")

  x1 = match_text("foo", path1, "foo", "bar")
  x2 = match_text("foo", path2, "foo", "bar")
  x = c(x1, x2)

  out = capture.output(print(x))

  expect_true(any(grepl("Common Path:", out, fixed = TRUE)))
  expect_true(any(grepl("script1.R", out, fixed = TRUE)))
  expect_true(any(grepl("script2.R", out, fixed = TRUE)))
})

