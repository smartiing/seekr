# list_files() ------------------------------------------------------------

test_that("list_files() rejects non-empty dots", {
  path = test_path("fixtures", "listing")
  expect_error(list_files(path, foo = 1))
  expect_error(list_files(path, 1L))
})

test_that("list_files() validates its arguments", {
  expect_error(list_files(path = NA_character_))
  expect_error(
    list_files(path = test_path("fixtures", "listing", "missing_dir")),
    class = "seekr_error_notdir"
  )

  path = test_path("fixtures", "listing")
  expect_error(list_files(path, recurse = "yes"))
  expect_error(list_files(path, all = NA))
  expect_error(list_files(path, .progress = NA))
})

test_that("list_files() returns an empty character vector for empty paths", {
  result = list_files(character())
  expect_type(result, "character")
  expect_length(result, 0L)
})

test_that("list_files() returns normalized character file paths", {
  path = test_path("fixtures", "listing")
  result = list_files(path)
  expect_type(result, "character")

  fixtures_listing_files = c(
    test_path("fixtures", "listing", "root-file.txt"),
    test_path("fixtures", "listing", "dir1", "dir1-file-a.txt"),
    test_path("fixtures", "listing", "dir1", "dir1-file-b.R"),
    test_path("fixtures", "listing", "dir2", "dir2-file.md"),
    test_path("fixtures", "listing", "dir2", "nested", "nested-file.txt")
  )

  expect_setequal(result, normalize_path(fixtures_listing_files))
})

test_that("list_files() wraps errors from fs::dir_ls()", {
  path = test_path("fixtures", "listing")

  local_mocked_bindings(
    dir_ls = function(...) stop("boom"),
    .package = "fs"
  )

  expect_error(list_files(path), class = "seekr_error_list_files")
})

test_that("list_files(use_git = TRUE) keeps only files returned by Git", {
  path = test_path("fixtures", "listing")

  git_files = normalize_path(
    c(
      test_path("fixtures", "listing", "root-file.txt"),
      test_path("fixtures", "listing", "dir1", "dir1-file-b.R")
    )
  )

  local_mocked_bindings(
    assert_git_available = function(...) invisible(TRUE),
    find_git_root = function(path) normalize_path(path, deduplicate = FALSE),
    git_ls_files = function(root) git_files,
    .package = "seekr"
  )

  result = list_files(path, use_git = TRUE)

  expect_setequal(result, git_files)
})

test_that("list_files(use_git = TRUE) falls back to regular listing outside Git repositories", {
  path = test_path("fixtures", "listing")

  expected = list_files(path, use_git = FALSE)

  local_mocked_bindings(
    assert_git_available = function(...) invisible(TRUE),
    find_git_root = function(path) NA_character_,
    git_ls_files = function(root) character(),
    .package = "seekr"
  )

  result = list_files(path, use_git = TRUE)

  expect_setequal(result, expected)
})

test_that("list_files() supports progress output", {
  withr::local_message_sink(nullfile())
  path = test_path("fixtures", "listing")
  expect_no_error(list_files(path, .progress = TRUE))
})


# seekr_dir_ls() ----------------------------------------------------------

test_that("seekr_dir_ls() lists files using seekr listing rules", {
  path = test_path("fixtures", "listing")
  result = seekr_dir_ls(path, recurse = FALSE, all = FALSE)
  expected = test_path("fixtures", "listing", "root-file.txt")

  expect_type(result, "character")
  expect_setequal(result, normalize_path(expected))
})

test_that("seekr_dir_ls() wraps errors from fs::dir_ls()", {
  path = test_path("fixtures", "listing")

  local_mocked_bindings(
    dir_ls = function(...) stop("boom"),
    .package = "fs"
  )

  expect_error(
    seekr_dir_ls(path, recurse = TRUE, all = FALSE),
    class = "seekr_error_list_files"
  )
})


# find_git_root() ---------------------------------------------------------

test_that("find_git_root() returns NA when Git does not find a repository", {
  local_mocked_bindings(
    run = function(command, args, error_on_status, echo, ...) {
      list(
        status = 128L,
        stdout = "",
        stderr = "fatal: not a git repository"
      )
    },
    .package = "processx"
  )

  result = find_git_root("some/path")
  expect_identical(result, NA_character_)
})

test_that("find_git_root() returns the normalized Git root when Git succeeds", {
  root = withr::local_tempdir()

  local_mocked_bindings(
    run = function(command, args, error_on_status, echo, ...) {
      list(
        status = 0L,
        stdout = paste0(root, "\n"),
        stderr = ""
      )
    },
    .package = "processx"
  )

  result = find_git_root("some/path")
  expect_identical(result, normalize_path(root, deduplicate = FALSE))
})

test_that("find_git_root() returns NA when Git returns an empty root", {
  local_mocked_bindings(
    run = function(command, args, error_on_status, echo, ...) {
      list(
        status = 0L,
        stdout = "\n",
        stderr = ""
      )
    },
    .package = "processx"
  )

  result = find_git_root("some/path")

  expect_identical(result, NA_character_)
})


# git_ls_files() ----------------------------------------------------------

test_that("git_ls_files() returns an empty character vector for missing Git roots", {
  result = git_ls_files(NA_character_)
  expect_type(result, "character")
  expect_length(result, 0L)
})

test_that("git_ls_files() returns normalized files listed by Git", {
  root = withr::local_tempdir()

  dir.create(file.path(root, "R"))
  file.create(file.path(root, "R", "a.R"))
  file.create(file.path(root, "README.md"))

  local_mocked_bindings(
    run = function(command, args, error_on_status, echo, ...) {
      list(
        status = 0L,
        stdout = paste(c("R/a.R", "README.md"), collapse = "\n"),
        stderr = ""
      )
    },
    .package = "processx"
  )

  result = git_ls_files(root)
  expected = normalize_path(file.path(root, c("R/a.R", "README.md")), deduplicate = TRUE)
  expect_setequal(result, expected)
})

test_that("git_ls_files() returns an empty character vector when Git lists no files", {
  root = withr::local_tempdir()

  local_mocked_bindings(
    run = function(command, args, error_on_status, echo, ...) {
      list(
        status = 0L,
        stdout = "",
        stderr = ""
      )
    },
    .package = "processx"
  )

  result = git_ls_files(root)
  expect_type(result, "character")
  expect_length(result, 0L)
})

test_that("git_ls_files() errors when Git cannot list files", {
  root = withr::local_tempdir()

  local_mocked_bindings(
    run = function(command, args, error_on_status, echo, ...) {
      list(
        status = 1L,
        stdout = "",
        stderr = "fatal: bad revision"
      )
    },
    .package = "processx"
  )

  expect_error(git_ls_files(root), class = "seekr_error_git_list_files")
})
