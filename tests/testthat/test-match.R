# match_files() -----------------------------------------------------------

test_that("match_files() rejects non-empty dots", {
  path = test_path("fixtures", "matching", "two-matches.txt")

  expect_error(match_files(path, "foo", "bar", foo = 1), class = "rlib_error_dots_nonempty")
  expect_error(match_files(path, "foo", "bar", 1L), class = "rlib_error_dots_nonempty")
})

test_that("match_files() validates its arguments", {
  path = test_path("fixtures", "matching", "two-matches.txt")

  expect_error(match_files(NA_character_, "TODO"), class = "seekr_error_na")
  expect_error(match_files(path, NULL), class = "seekr_error_null")
  expect_error(match_files(path, "TODO", replacement = 1L), class = "seekr_error_class")
  expect_error(match_files(path, "TODO", context = -1L), class = "seekr_error_bounds")
  expect_error(match_files(path, "TODO", encoding = ""), class = "seekr_error_empty_string")
  expect_error(match_files(path, "TODO", .progress = NA), class = "seekr_error_na")
})

test_that("match_files() returns an empty seekr_match for empty paths", {
  result = match_files(character(), "TODO")
  expect_identical(result, new_seekr_match())
})

test_that("match_files() finds matches in files", {
  path = test_path("fixtures", "matching", "two-matches.txt")
  result = match_files(path, "TODO")

  expect_s3_class(result, "seekr_match")
  expect_length(result, 2L)
  expect_equal(vctrs::field(result, "match"), c("TODO", "TODO"))
  expect_equal(vctrs::field(result, "start_line"), c(2L, 4L))
  expect_equal(unique(vctrs::field(result, "path")), normalize_path(path))
})

test_that("match_files() captures context lines", {
  path = test_path("fixtures", "matching", "two-matches.txt")
  result = match_files(path, "TODO", context = c(1L, 1L))

  expect_equal(vctrs::field(result, "before"), c("before", "between"))
  expect_equal(vctrs::field(result, "line"), c("TODO one", "TODO two"))
  expect_equal(vctrs::field(result, "after"), c("between", "after"))
})

test_that("match_files() stores missing context as NA_character when context is zero", {
  path = test_path("fixtures", "matching", "two-matches.txt")
  result = match_files(path, "TODO", context = 0L)

  expect_true(all(is.na(vctrs::field(result, "before"))))
  expect_true(all(is.na(vctrs::field(result, "after"))))
})

test_that("match_files() stages replacement values", {
  path = test_path("fixtures", "matching", "two-matches.txt")
  result = match_files(path, "TODO", replacement = "DONE")

  expect_equal(vctrs::field(result, "replacement"), c("DONE", "DONE"))
})

test_that("match_files() skips missing files with a warning", {
  existing = test_path("fixtures", "matching", "two-matches.txt")
  missing = test_path("fixtures", "matching", "missing.txt")

  expect_warning(
    {result = match_files(c(existing, missing), "TODO")},
    class = "seekr_warn_missing_files"
  )

  expect_s3_class(result, "seekr_match")
  expect_equal(unique(vctrs::field(result, "path")), normalize_path(existing))
})

test_that("match_files() returns an empty seekr_match when all files are missing", {
  missing = test_path("fixtures", "matching", "missing.txt")

  expect_warning(
    result <- match_files(missing, "TODO"),
    class = "seekr_warn_missing_files"
  )

  expect_s3_class(result, "seekr_match")
  expect_length(result, 0L)
})

test_that("match_files() supports progress output", {
  withr::local_message_sink(nullfile())
  path = test_path("fixtures", "matching", "two-matches.txt")

  expect_no_error(match_files(path, "TODO", .progress = TRUE))
})


# combine_raw_matches() ---------------------------------------------------

test_that("combine_raw_matches() returns an empty seekr_match for empty raw data", {
  result = combine_raw_matches(list(list(), list()))

  expect_s3_class(result, "seekr_match")
  expect_length(result, 0L)
})

test_that("combine_raw_matches() combines raw match data", {
  data = list(
    match_file_impl("TODO one", "a.txt", "TODO", NULL, normalize_context(0L), "UTF-8"),
    match_file_impl("TODO two", "b.txt", "TODO", NULL, normalize_context(0L), "UTF-8")
  )

  result = combine_raw_matches(data)

  expect_s3_class(result, "seekr_match")
  expect_length(result, 2L)
  expect_equal(vctrs::field(result, "path"), c("a.txt", "b.txt"))
  expect_equal(vctrs::field(result, "match"), c("TODO", "TODO"))
})


# match_file_impl() -------------------------------------------------------

test_that("match_file_impl() returns an empty list when there are no matches", {
  result = match_file_impl(
    text = "alpha beta gamma",
    path = "file.txt",
    pattern = "TODO",
    replacement = NULL,
    context = normalize_context(1L),
    encoding = "UTF-8"
  )

  expect_equal(result, list())
})

test_that("match_file_impl() returns an empty list when text is NA", {
  result = match_file_impl(
    text = NA_character_,
    path = "file.txt",
    pattern = "TODO",
    replacement = NULL,
    context = normalize_context(1L),
    encoding = "UTF-8"
  )

  expect_equal(result, list())
})

test_that("match_file_impl() extracts match metadata", {
  text = paste(c("before", "TODO one", "between", "TODO two", "after"), collapse = "\n")
  result = match_file_impl(
    text = text,
    path = "file.txt",
    pattern = "TODO",
    replacement = NULL,
    context = normalize_context(c(1L, 1L)),
    encoding = "UTF-8"
  )

  expect_equal(result$path, c("file.txt", "file.txt"))
  expect_equal(result$start_line, c(2L, 4L))
  expect_equal(result$end_line, c(2L, 4L))
  expect_equal(result$start, c(8L, 25L))
  expect_equal(result$end, c(11L, 28L))
  expect_equal(result$start_col, c(1L, 1L))
  expect_equal(result$end_col, c(4L, 4L))
  expect_equal(result$match, c("TODO", "TODO"))
  expect_equal(result$replacement, c(NA_character_, NA_character_))
  expect_equal(result$before, c("before", "between"))
  expect_equal(result$line, c("TODO one", "TODO two"))
  expect_equal(result$after, c("between", "after"))
  expect_equal(result$encoding, c("UTF-8", "UTF-8"))
})

test_that("match_file_impl() stores missing context when context is zero", {
  result = match_file_impl(
    text = "before\nTODO\nafter",
    path = "file.txt",
    pattern = "TODO",
    replacement = NULL,
    context = normalize_context(0L),
    encoding = "UTF-8"
  )

  expect_true(all(is.na(result$before)))
  expect_true(all(is.na(result$after)))
})

test_that("match_file_impl() handles multiline matches", {
  pattern = stringr::regex("pha\nbe", multiline = TRUE)
  result = match_file_impl(
    text = "alpha\nbeta\ngamma",
    path = "file.txt",
    pattern = pattern,
    replacement = NULL,
    context = normalize_context(0L),
    encoding = "UTF-8"
  )

  expect_equal(result$start_line, 1L)
  expect_equal(result$end_line, 2L)
  expect_equal(result$start, 3L)
  expect_equal(result$end, 8L)
  expect_equal(result$line, "alpha\nbeta")
})


# match_text() ------------------------------------------------------------

test_that("match_text() rejects non-empty dots", {
  expect_error(
    match_text("TODO", "file.txt", "TODO", foo = 1),
    class = "rlib_error_dots_nonempty"
  )
})

test_that("match_text() validates its arguments", {
  expect_error(match_text(NA_character_, "file.txt", "TODO"), class = "seekr_error_na")
  expect_error(match_text("TODO", NA_character_, "TODO"), class = "seekr_error_na")
  expect_error(match_text("TODO", "file.txt", NULL), class = "seekr_error_null")
  expect_error(match_text("TODO", "file.txt", "TODO", replacement = 1L), class = "seekr_error_class")
  expect_error(match_text("TODO", "file.txt", "TODO", context = -1L), class = "seekr_error_bounds")
})

test_that("match_text() matches already-read file content", {
  text = "before\nTODO one\nbetween\nTODO two\nafter"
  result = match_text(text = text, path = "file.txt", pattern = "TODO")

  expect_s3_class(result, "seekr_match")
  expect_length(result, 2L)
  expect_equal(vctrs::field(result, "path"), rep("file.txt", 2L))
  expect_equal(vctrs::field(result, "match"), c("TODO", "TODO"))
})

test_that("match_text() returns an empty seekr_match when there are no matches", {
  result = match_text(text = "alpha beta", path = "file.txt", pattern = "TODO")

  expect_s3_class(result, "seekr_match")
  expect_length(result, 0L)
})

test_that("match_text() stages replacement values", {
  result = match_text(text = "TODO TODO", path = "file.txt", pattern = "TODO", replacement = "DONE")

  expect_equal(vctrs::field(result, "replacement"), c("DONE", "DONE"))
})

test_that("match_text() normalize path if file exists", {
  testthat::local_mocked_bindings(
    file_exists = function(path) TRUE,
    .package = "fs"
  )

  result = match_text(text = "TODO TODO", path = "file.txt", pattern = "TODO")
  expect_all_true(nchar(vctrs::field(result, "path")) > nchar("file.txt"))
})


# compute_newline_locs() --------------------------------------------------

test_that("compute_newline_locs() locates common newline variants", {
  result = compute_newline_locs("a\nb\r\nc\rd")
  expected = rbind(
    c(0L, 0L),
    c(2L, 2L),
    c(4L, 5L),
    c(7L, 7L)
  )

  expect_equal(as.integer(result), as.integer(expected))
})


# extract_lines() ---------------------------------------------------------

test_that("extract_lines() extracts line ranges", {
  text = "a\nb\nc"
  locs_nl = compute_newline_locs(text)

  result = extract_lines(
    text = text,
    locs_nl = locs_nl,
    start_line = c(1L, 2L, 3L),
    end_line = c(1L, 3L, 3L)
  )

  expect_equal(result, c("a", "b\nc", "c"))
})

test_that("extract_lines() ignore lines outside line ranges", {
  text = "a\nb\nc"
  locs_nl = compute_newline_locs(text)

  result = extract_lines(
    text = text,
    locs_nl = locs_nl,
    start_line = c(0L, 2L, 3L),
    end_line = c(1L, 3L, 12L)
  )

  expect_equal(result, c("a", "b\nc", "c"))
})

test_that("extract_lines() returns NA for outside or empty ranges", {
  text = "a\nb\nc"
  locs_nl = compute_newline_locs(text)

  result = extract_lines(
    text = text,
    locs_nl = locs_nl,
    start_line = c(0L, 4L, 2L),
    end_line = c(0L, 4L, 1L)
  )

  expect_equal(result, c(NA_character_, NA_character_, NA_character_))
})


# compute_replacement() ---------------------------------------------------

test_that("compute_replacement() returns missing replacements when replacement is NULL or NA", {
  text = "TODO TODO"
  match = c("TODO", "TODO")
  pattern = "TODO"

  expect_equal(
    compute_replacement(text, pattern, match, replacement = NULL),
    c(NA_character_, NA_character_)
  )

  expect_equal(
    compute_replacement(text, pattern, match, replacement = NA_character_),
    c(NA_character_, NA_character_)
  )
})

test_that("compute_replacement() returns static replacements", {
  text = "TODO TODO"
  match = c("TODO", "TODO")
  pattern = "TODO"

  result = compute_replacement(text, pattern, match, "DONE")
  expect_equal(result, c("DONE", "DONE"))
})

test_that("compute_replacement() interpolates numeric capture groups", {
  text = "alpha_one beta_ gamma_two"
  pattern = "(\\w+)_(\\w+)?"
  match = stringr::str_extract_all(text, pattern)[[1]]

  result = compute_replacement(text, pattern, match, "\\2_\\1")

  expect_equal(result, c("one_alpha", "_beta", "two_gamma"))
})

test_that("compute_replacement() preserves literal curly braces", {
  text = "alpha_one"
  pattern = "(\\w+)_(\\w+)"
  match = stringr::str_extract_all(text, pattern)[[1]]

  result = compute_replacement(text, pattern, match, "{\\2}_\\1")

  expect_equal(result, "{one}_alpha")
})

test_that("compute_replacement() rejects missing capture groups", {
  text = "alpha_one"
  pattern = "(\\w+)_(\\w+)"
  match = stringr::str_extract_all(text, pattern)[[1]]

  expect_error(
    compute_replacement(text, pattern, match, "\\3"),
    class = "seekr_error_replacement_missing_capture_group"
  )
})

test_that("compute_replacement() applies replacement functions to matches", {
  match = c("todo", "fixme")

  result = compute_replacement(
    text = "todo fixme",
    pattern = "\\w+",
    match = match,
    replacement = toupper
  )

  expect_equal(result, c("TODO", "FIXME"))
})

test_that("compute_replacement() applies with_capture_groups_matrix() functions to capture matrices", {
  text = "alpha_one beta_"
  pattern = "(\\w+)_(\\w+)?"
  match = stringr::str_extract_all(text, pattern)[[1]]
  seen = NULL

  replacement = with_capture_groups_matrix(function(M) {
    seen <<- M
    paste0("replacement", seq_len(nrow(M)))
  })

  result = compute_replacement(text, pattern, match, replacement)

  expect_equal(result, c("replacement1", "replacement2"))
  expect_false(anyNA(seen[1:5]))
  expect_true(anyNA(seen[6]))
  expect_equal(seen[, 1], match)
})

test_that("compute_replacement() rejects replacement functions with invalid return type", {
  match = c("todo", "fixme")

  expect_error(
    compute_replacement("todo fixme", "\\w+", match, function(x) seq_along(x)),
    class = "seekr_error_class"
  )
})

test_that("compute_replacement() rejects replacement functions with invalid return length", {
  match = c("todo", "fixme")

  expect_error(
    compute_replacement("todo fixme", "\\w+", match, function(x) "replacement"),
    class = "seekr_error_length"
  )
})


# with_capture_groups_matrix() -----------------------------------------------------------

test_that("with_capture_groups_matrix() marks replacement functions", {
  fn = function(M) rep("x", nrow(M))
  result = with_capture_groups_matrix(fn)

  expect_true(is.function(result))
  expect_true(isTRUE(attr(result, "seekr_with_capture_groups_matrix")))
})

test_that("with_capture_groups_matrix() rejects non-functions", {
  expect_error(
    with_capture_groups_matrix("not a function"),
    class = "seekr_error_with_capture_groups_matrix_function"
  )
})


# glue_escape() -----------------------------------------------------------

test_that("glue_escape() escapes curly braces", {
  expect_equal(glue_escape("a {x} b"), "a {{x}} b")
  expect_equal(glue_escape(c("{a}", "{b}")), c("{{a}}", "{{b}}"))
})
