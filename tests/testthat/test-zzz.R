test_that("set_seekr_verbose_default() sets default only when option is unset", {
  original = getOption("seekr.verbose")
  on.exit(options(seekr.verbose = original), add = TRUE)

  # Case 1: Option is unset → should be set to interactive()
  withr::with_options(list(seekr.verbose = NULL), {
    expect_null(getOption("seekr.verbose"))
    set_seekr_verbose_default()
    expect_identical(getOption("seekr.verbose"), interactive())
  })

  # Case 2: Option is already set → should remain unchanged
  withr::with_options(list(seekr.verbose = FALSE), {
    expect_false(getOption("seekr.verbose"))
    set_seekr_verbose_default()
    expect_identical(getOption("seekr.verbose"), FALSE)
  })
})


test_that(".onLoad() executes without error", {
  expect_silent(.onLoad("seekr", "seekr"))
})

