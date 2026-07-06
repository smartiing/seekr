# restore_files -----------------------------------------------------------

test_that("restore_files() rejects non-empty dots", {
  expect_error(
    restore_files(from = from, to = to, unused = TRUE),
    class = "rlib_error_dots_nonempty"
  )
})

test_that("restore_files() validates non-path arguments", {
  from = withr::local_tempfile(lines = "backup")
  to = withr::local_tempfile(lines = "current")
  expect_error(restore_files(from = from, to = to, backup = NA), class = "seekr_error_na")
  expect_error(restore_files(from = from, to = to, description = 123), class = "seekr_error_class")
  expect_error(restore_files(from = from, to = to, .progress = NA), class = "seekr_error_na")
})

test_that("restore_files() returns invisibly for empty inputs", {
  withr::local_message_sink(nullfile())
  result = restore_files(from = character(), to = character(), backup = FALSE)
  expect_identical(result, character())
})

test_that("restore_files() restores one file", {
  from = withr::local_tempfile(lines = "backup version")
  to = withr::local_tempfile(lines = "current version")

  result = restore_files(
    from = from,
    to = to,
    backup = FALSE
  )

  expect_identical(result, to)
  expect_identical(readLines(to), "backup version")
})

test_that("restore_files() restores multiple files", {
  from1 = withr::local_tempfile(lines = "backup one")
  from2 = withr::local_tempfile(lines = "backup two")

  to1 = withr::local_tempfile(lines = "current one")
  to2 = withr::local_tempfile(lines = "current two")

  result = restore_files(from = c(from1, from2), to = c(to1, to2), backup = FALSE)
  expect_identical(result, c(to1, to2))
  expect_identical(readLines(to1), "backup one")
  expect_identical(readLines(to2), "backup two")
})

test_that("restore_files() can restore to missing destination files", {
  from1 = withr::local_tempfile(lines = "backup one")
  from2 = withr::local_tempfile(lines = "backup two")

  to_dir = withr::local_tempdir()
  to1 = file.path(to_dir, "one.txt")
  to2 = file.path(to_dir, "two.txt")

  expect_false(file.exists(to1))
  expect_false(file.exists(to2))

  result = restore_files(from = c(from1, from2), to = c(to1, to2), backup = FALSE)
  expect_identical(result, c(to1, to2))
  expect_identical(readLines(to1), "backup one")
  expect_identical(readLines(to2), "backup two")
})

test_that("restore_files() creates a backup of existing destination files before restoring", {
  withr::local_message_sink(nullfile())

  from = withr::local_tempfile(lines = "backup version")
  to = withr::local_tempfile(lines = "current version")
  backup_dir = withr::local_tempdir()

  restore_files(
    from = from,
    to = to,
    backup = TRUE,
    description = "restore test",
    backup_dir = backup_dir,
    .progress = TRUE
  )

  backups = list_backups(backup_dir)

  expect_equal(nrow(backups), 1L)
  expect_identical(backups$operation, "restore")
  expect_identical(backups$description, "restore test")
  expect_identical(readLines(backups$backup[[1]]), "current version")
  expect_identical(readLines(to), "backup version")
})

test_that("restore_files() only backs up destination files that already exist", {
  withr::local_message_sink(nullfile())
  from_existing = withr::local_tempfile(lines = "backup existing")
  from_missing = withr::local_tempfile(lines = "backup missing")

  to_existing = withr::local_tempfile(lines = "current existing")

  to_dir = withr::local_tempdir()
  to_missing = file.path(to_dir, "new-file.txt")

  backup_dir = withr::local_tempdir()

  restore_files(
    from = c(from_existing, from_missing),
    to = c(to_existing, to_missing),
    backup = TRUE,
    backup_dir = backup_dir
  )

  backups = list_backups(backup_dir)

  expect_equal(nrow(backups), 1L)
  expect_identical(readLines(backups$backup[[1]]), "current existing")
  expect_identical(readLines(to_existing), "backup existing")
  expect_identical(readLines(to_missing), "backup missing")
})


test_that("restore_files() does not create backup entries when no destination file exists", {
  withr::local_message_sink(nullfile())
  from1 = withr::local_tempfile(lines = "backup one")
  from2 = withr::local_tempfile(lines = "backup two")

  to_dir = withr::local_tempdir()
  to1 = file.path(to_dir, "one.txt")
  to2 = file.path(to_dir, "two.txt")

  backup_dir = withr::local_tempdir()

  restore_files(
    from = c(from1, from2),
    to = c(to1, to2),
    backup = TRUE,
    backup_dir = backup_dir
  )

  backups = list_backups(backup_dir)

  expect_equal(nrow(backups), 0L)
  expect_identical(readLines(to1), "backup one")
  expect_identical(readLines(to2), "backup two")
})


# restore_files_interactive() ---------------------------------------------

test_that("restore_files_interactive() errors in non-interactive sessions", {
  withr::local_options(rlang_interactive = FALSE)
  expect_error(
    restore_files_interactive("foo.txt", "bar.txt"),
    class = "seekr_error_restore_non_interactive"
  )
})

test_that("restore_files_interactive() errors if `diffobj` is not installed", {
  withr::local_options(rlang_interactive = TRUE)
  testthat::local_mocked_bindings(
    is_installed = function(x) FALSE,
    .package = "rlang"
  )

  expect_error(
    restore_files_interactive("foo.txt", "bar.txt"),
    class = "seekr_error_dependency_not_installed"
  )
})

test_that("restore_files_interactive() validates non-path arguments", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  from = withr::local_tempfile(lines = "backup")
  to = withr::local_tempfile(lines = "current")
  expect_error(restore_files_interactive(from = from, to = to, backup = NA), class = "seekr_error_na")
  expect_error(restore_files_interactive(from = from, to = to, description = 123), class = "seekr_error_class")
  expect_error(restore_files_interactive(from = from, to = to, .progress = NA), class = "seekr_error_na")
})

test_that("restore_files_interactive() returns invisibly for empty inputs", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  result = restore_files_interactive(from = character(), to = character(), backup = FALSE)
  expect_identical(result, character())
})

test_that("restore_files_interactive() passes diff options to diffobj::diffFile()", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  from = withr::local_tempfile(lines = "backup")
  to = withr::local_tempfile(lines = "current")

  diff_args = NULL

  testthat::local_mocked_bindings(
    diffFile = function(...) {
      diff_args <<- list(...)
      structure(list(), class = "seekr_test_diff")
    },
    .package = "diffobj"
  )

  testthat::local_mocked_bindings(
    show = function(object) invisible(NULL),
    .package = "methods"
  )

  testthat::local_mocked_bindings(
    restore_backup_menu = function() "ignore_one"
  )

  restore_files_interactive(
    from = from,
    to = to,
    mode = "unified",
    color.mode = "yb",
    backup = FALSE
  )

  expect_identical(diff_args$target, from)
  expect_identical(diff_args$current, to)
  expect_identical(diff_args$mode, "unified")
  expect_identical(diff_args$format, "auto")
  expect_identical(diff_args$color.mode, "yb")
})

test_that("restore_files_interactive() restores files selected with restore_one", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  from1 = withr::local_tempfile(lines = "backup one")
  from2 = withr::local_tempfile(lines = "backup two")

  to1 = withr::local_tempfile(lines = "current one")
  to2 = withr::local_tempfile(lines = "current two")

  choices = c("restore_one", "restore_one")
  i = 0L

  testthat::local_mocked_bindings(
    diffFile = function(...) structure(list(), class = "seekr_test_diff"),
    .package = "diffobj"
  )

  testthat::local_mocked_bindings(
    show = function(object) invisible(NULL),
    .package = "methods"
  )

  testthat::local_mocked_bindings(
    restore_backup_menu = function() {
      i <<- i + 1L
      choices[[i]]
    }
  )

  result = restore_files_interactive(
    from = c(from1, from2),
    to = c(to1, to2),
    backup = FALSE
  )

  expect_identical(result, c(to1, to2))
  expect_identical(readLines(to1), "backup one")
  expect_identical(readLines(to2), "backup two")
})

test_that("restore_files_interactive() skips files selected with ignore_one", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  from1 = withr::local_tempfile(lines = "backup one")
  from2 = withr::local_tempfile(lines = "backup two")

  to1 = withr::local_tempfile(lines = "current one")
  to2 = withr::local_tempfile(lines = "current two")

  choices = c("ignore_one", "restore_one")
  i = 0L

  testthat::local_mocked_bindings(
    diffFile = function(...) structure(list(), class = "seekr_test_diff"),
    .package = "diffobj"
  )

  testthat::local_mocked_bindings(
    show = function(object) invisible(NULL),
    .package = "methods"
  )

  testthat::local_mocked_bindings(
    restore_backup_menu = function() {
      i <<- i + 1L
      choices[[i]]
    }
  )

  result = restore_files_interactive(
    from = c(from1, from2),
    to = c(to1, to2),
    backup = FALSE
  )

  expect_identical(result, to2)
  expect_identical(readLines(to1), "current one")
  expect_identical(readLines(to2), "backup two")
})

test_that("restore_files_interactive() restores all remaining files", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  from1 = withr::local_tempfile(lines = "backup one")
  from2 = withr::local_tempfile(lines = "backup two")
  from3 = withr::local_tempfile(lines = "backup three")

  to1 = withr::local_tempfile(lines = "current one")
  to2 = withr::local_tempfile(lines = "current two")
  to3 = withr::local_tempfile(lines = "current three")

  choices = c("ignore_one", "restore_remaining")
  i = 0L

  testthat::local_mocked_bindings(
    diffFile = function(...) structure(list(), class = "seekr_test_diff"),
    .package = "diffobj"
  )

  testthat::local_mocked_bindings(
    show = function(object) invisible(NULL),
    .package = "methods"
  )

  testthat::local_mocked_bindings(
    restore_backup_menu = function() {
      i <<- i + 1L
      choices[[i]]
    }
  )

  result = restore_files_interactive(
    from = c(from1, from2, from3),
    to = c(to1, to2, to3),
    backup = FALSE
  )

  expect_identical(result, c(to2, to3))
  expect_identical(readLines(to1), "current one")
  expect_identical(readLines(to2), "backup two")
  expect_identical(readLines(to3), "backup three")
})

test_that("restore_files_interactive() ignores all remaining files", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  from1 = withr::local_tempfile(lines = "backup one")
  from2 = withr::local_tempfile(lines = "backup two")
  from3 = withr::local_tempfile(lines = "backup three")

  to1 = withr::local_tempfile(lines = "current one")
  to2 = withr::local_tempfile(lines = "current two")
  to3 = withr::local_tempfile(lines = "current three")

  choices = c("restore_one", "ignore_remaining")
  i = 0L

  testthat::local_mocked_bindings(
    diffFile = function(...) structure(list(), class = "seekr_test_diff"),
    .package = "diffobj"
  )

  testthat::local_mocked_bindings(
    show = function(object) invisible(NULL),
    .package = "methods"
  )

  testthat::local_mocked_bindings(
    restore_backup_menu = function() {
      i <<- i + 1L
      choices[[i]]
    }
  )

  result = restore_files_interactive(
    from = c(from1, from2, from3),
    to = c(to1, to2, to3),
    backup = FALSE
  )

  expect_identical(result, to1)
  expect_identical(readLines(to1), "backup one")
  expect_identical(readLines(to2), "current two")
  expect_identical(readLines(to3), "current three")
})

test_that("restore_files_interactive() cancels all planned changes", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  from1 = withr::local_tempfile(lines = "backup one")
  from2 = withr::local_tempfile(lines = "backup two")

  to1 = withr::local_tempfile(lines = "current one")
  to2 = withr::local_tempfile(lines = "current two")

  choices = c("restore_one", "cancel")
  i = 0L

  testthat::local_mocked_bindings(
    diffFile = function(...) structure(list(), class = "seekr_test_diff"),
    .package = "diffobj"
  )

  testthat::local_mocked_bindings(
    show = function(object) invisible(NULL),
    .package = "methods"
  )

  testthat::local_mocked_bindings(
    restore_backup_menu = function() {
      i <<- i + 1L
      choices[[i]]
    }
  )

  result = restore_files_interactive(
    from = c(from1, from2),
    to = c(to1, to2),
    backup = FALSE
  )

  expect_identical(result, character())
  expect_identical(readLines(to1), "current one")
  expect_identical(readLines(to2), "current two")
})

test_that("restore_files_interactive() errors on unknown menu choices", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  from = withr::local_tempfile(lines = "backup")
  to = withr::local_tempfile(lines = "current")

  testthat::local_mocked_bindings(
    diffFile = function(...) structure(list(), class = "seekr_test_diff"),
    .package = "diffobj"
  )

  testthat::local_mocked_bindings(
    show = function(object) invisible(NULL),
    .package = "methods"
  )

  testthat::local_mocked_bindings(
    restore_backup_menu = function() "unknown_choice"
  )

  expect_error(
    restore_files_interactive(
      from = from,
      to = to,
      backup = FALSE
    ),
    regexp = "Internal error while handling restore choice"
  )
})

test_that("restore_files_interactive() handles missing destination files", {
  withr::local_options(rlang_interactive = TRUE)
  withr::local_message_sink(nullfile())
  from = withr::local_tempfile(lines = "backup")
  to = file.path(withr::local_tempdir(), "new-file.txt")

  testthat::local_mocked_bindings(
    diffFile = function(...) {
      stop("diffobj::diffFile() should not be called for missing destination files.")
    },
    .package = "diffobj"
  )

  testthat::local_mocked_bindings(
    show = function(object) {
      stop("methods::show() should not be called for missing destination files.")
    },
    .package = "methods"
  )

  testthat::local_mocked_bindings(
    restore_backup_menu = function() "restore_one"
  )

  result = restore_files_interactive(
    from = from,
    to = to,
    backup = FALSE
  )

  expect_identical(result, to)
  expect_identical(readLines(to), "backup")
})


# restore_backup_menu -----------------------------------------------------

test_that("restore_backup_menu() returns the selected choice name", {
  testthat::local_mocked_bindings(
    menu = function(choices, title) 1L,
    .package = "utils"
  )

  expect_identical(restore_backup_menu(), "restore_one")
})


test_that("restore_backup_menu() retries until a valid choice is selected", {
  testthat::local_mocked_bindings(
    menu = function(choices, title) 3L,
    .package = "utils"
  )

  expect_identical(restore_backup_menu(), "restore_remaining")
})
