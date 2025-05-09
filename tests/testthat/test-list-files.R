# list_files -----------------------------------------------------------------
# This function is not thoroughly tested as it is mainly a wrapper around
# fs::dir_ls() with some custom error message in case no files are listed.

test_that("list_files() returns files correctly", {
  tmp = withr::local_tempdir()

  writeLines("content", file.path(tmp, "file1.txt"))
  writeLines("content", file.path(tmp, "file2.log"))

  result = list_files(path = tmp, recurse = FALSE, all = FALSE)

  expect_true(all(c("file1.txt", "file2.log") %in% basename(result)))
})


test_that("list_files() error message: recurse = TRUE, all = TRUE", {
  tmp = withr::local_tempdir()
  expect_error(
    list_files(tmp, recurse = TRUE, all = TRUE),
    class = "error_list_files_TT"
  )
})


test_that("list_files() error message: recurse = TRUE, all = FALSE", {
  tmp = withr::local_tempdir()
  expect_error(
    list_files(tmp, recurse = TRUE, all = FALSE),
    class = "error_list_files_TF"
  )
})


test_that("list_files() error message: recurse = FALSE, all = TRUE", {
  tmp = withr::local_tempdir()
  expect_error(
    list_files(tmp, recurse = FALSE, all = TRUE),
    class = "error_list_files_FT"
  )
})


test_that("list_files() error message: recurse = FALSE, all = FALSE", {
  tmp = withr::local_tempdir()
  expect_error(
    list_files(tmp, recurse = FALSE, all = FALSE),
    class = "error_list_files_FF"
  )
})


test_that("mock cli for coverage", {
  tmp = withr::local_tempdir()
  file1 = file.path(tmp, "file1.txt")
  writeLines("content", file1)
  file1 = normalizePath(file1, "/")

  local_mocked_bindings(print_cli = function() TRUE)
  local_mocked_bindings(
    cli_progress_step = function(...) invisible(),
    .package = "cli"
  )

  expect_no_error(list_files(tmp, FALSE, FALSE))
})
