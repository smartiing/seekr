test_that("prepare_df() returns expected columns with matches = TRUE", {
  files = c("data/file1.txt", "data/file2.txt")
  lines = list(
    line_number = list(c(1, 3), 2),
    line = list(c("match line 1", "match line 3"), "another match line")
  )
  pattern = "match"

  result = prepare_df(
    files = files,
    pattern = pattern,
    lines = lines,
    path = "data/",
    relative_path = TRUE,
    matches = TRUE
  )

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("path", "line_number", "match", "matches", "line"))
  expect_equal(nrow(result), 3)
  expect_s3_class(result$path, "fs_path")
})


test_that("prepare_df() returns expected columns with matches = FALSE", {
  files = c("src/code.R")
  lines = list(
    line_number = list(c(2, 4)),
    line = list(c("found A", "found B"))
  )
  pattern = "found"

  result = prepare_df(
    files = files,
    pattern = pattern,
    lines = lines,
    path = "src/",
    relative_path = TRUE,
    matches = FALSE
  )

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("path", "line_number", "match", "line"))
  expect_equal(result$match, c("found", "found"))
})


test_that("prepare_df() keeps full path if relative_path = FALSE", {
  files = c("project/code/script.R")
  lines = list(
    line_number = list(1),
    line = list("load_package")
  )

  result = prepare_df(
    files = files,
    pattern = "load",
    lines = lines,
    path = "project/",
    relative_path = FALSE,
    matches = FALSE
  )

  expect_true(grepl("^project/", result$path))
})


test_that("prepare_df() mocks CLI", {
  files = c("project/code/script.R")
  lines = list(
    line_number = list(1),
    line = list("load_package")
  )

  local_mocked_bindings(print_cli = function() TRUE)
  local_mocked_bindings(
    cli_progress_step = function(...) invisible(),
    .package = "cli"
  )

  result = prepare_df(
    files = files,
    pattern = "load",
    lines = lines,
    path = "project/",
    relative_path = FALSE,
    matches = FALSE
  )

  expect_true(grepl("^project/", result$path))
})
