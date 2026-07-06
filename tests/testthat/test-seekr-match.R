# new_seekr_match ---------------------------------------------------------

test_that("new_seekr_match() creates an empty seekr_match vector", {
  x = new_seekr_match()

  expect_s3_class(x, "seekr_match")
  expect_equal(length(x), 0L)

  expect_identical(field(x, "path"), character())
  expect_identical(field(x, "start_line"), integer())
  expect_identical(field(x, "end_line"), integer())
  expect_identical(field(x, "start"), integer())
  expect_identical(field(x, "end"), integer())
  expect_identical(field(x, "start_col"), integer())
  expect_identical(field(x, "end_col"), integer())
  expect_identical(field(x, "match"), character())
  expect_identical(field(x, "replacement"), character())
  expect_identical(field(x, "before"), character())
  expect_identical(field(x, "line"), character())
  expect_identical(field(x, "after"), character())
  expect_identical(field(x, "encoding"), character())
})

test_that("new_seekr_match() stores all fields", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "bar",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  expect_s3_class(x, "seekr_match")
  expect_equal(length(x), 1L)

  expect_identical(field(x, "path"), path)
  expect_identical(field(x, "start_line"), 1L)
  expect_identical(field(x, "end_line"), 1L)
  expect_identical(field(x, "start"), 1L)
  expect_identical(field(x, "end"), 3L)
  expect_identical(field(x, "start_col"), 1L)
  expect_identical(field(x, "end_col"), 3L)
  expect_identical(field(x, "match"), "foo")
  expect_identical(field(x, "replacement"), "bar")
  expect_identical(field(x, "before"), NA_character_)
  expect_identical(field(x, "line"), "foo")
  expect_identical(field(x, "after"), NA_character_)
  expect_identical(field(x, "encoding"), "UTF-8")
  expect_identical(field(x, "hash"), "abc")
})

test_that("new_seekr_match() errors when fields have incompatible lengths", {
  path = tempfile(fileext = ".txt")

  expect_error(
    new_seekr_match(
      path = c(path, path),
      start_line = 1L,
      end_line = 1L,
      start = 1L,
      end = 3L,
      start_col = 1L,
      end_col = 3L,
      match = "foo",
      replacement = "bar",
      before = NA_character_,
      line = "foo",
      after = NA_character_,
      encoding = "UTF-8",
      hash = "abc"
    )
  )
})

# vctrs methods ----------------------------------------------------------

test_that("vec_c() combines seekr_match vectors and drops metadata attributes", {
  path1 = tempfile(fileext = ".txt")
  path2 = tempfile(fileext = ".txt")

  x = new_seekr_match()
  y = new_seekr_match(
    path = path2,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "bar",
    replacement = "BAR",
    before = NA_character_,
    line = "bar",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  attr(x, "empty_stage") = "match"
  attr(y, "exclusions") = data.frame(path = c(path1, path2), excluded = c(TRUE, FALSE))

  z = vctrs::vec_c(x, y)

  expect_s3_class(z, "seekr_match")
  expect_equal(length(z), 1L)
  expect_identical(field(z, "path"), path2)
  expect_null(attr(z, "empty_stage", exact = TRUE))
  expect_null(attr(z, "exclusions", exact = TRUE))
})

test_that("vec_cast() drops metadata attributes", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "FOO",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  attr(x, "empty_stage") = "match"
  attr(x, "exclusions") = data.frame(path = path, excluded = TRUE)

  y = vctrs::vec_cast(x, new_seekr_match())

  expect_s3_class(y, "seekr_match")
  expect_null(attr(y, "empty_stage", exact = TRUE))
  expect_null(attr(y, "exclusions", exact = TRUE))
})

test_that("vec_proxy_equal() keeps missing and empty replacements distinct", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = NA_character_,
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  y = new_seekr_match(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  expect_false(vctrs::vec_equal(x, y, na_equal = TRUE))
})

test_that("vec_proxy_compare() orders seekr_match vectors globally", {
  x = new_seekr_match(
    path = c("path2", "path1", "path1"),
    start_line = c(1L, 1L, 1L),
    end_line = c(1L, 1L, 1L),
    start = c(10L, 5L, 1L),
    end = c(12L, 7L, 3L),
    start_col = c(10L, 5L, 1L),
    end_col = c(12L, 7L, 3L),
    match = c("baz", "bar", "foo"),
    replacement = c("BAZ", "BAR", "FOO"),
    before = rep(NA_character_, 3L),
    line = c("baz", "bar", "foo"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "def", "def")
  )

  expect_identical(vctrs::vec_order(x), c(3L, 2L, 1L))
})

test_that("vec_ptype_abbr() and vec_ptype_full() describe seekr_match vectors", {
  x = new_seekr_match()

  expect_identical(vctrs::vec_ptype_abbr(x), "seekr::match")
  expect_identical(vctrs::vec_ptype_full(x), "seekr::match")
})

test_that("format.seekr_match() formats path, line, and column", {
  path = normalize_path(tempfile(fileext = ".txt"))

  x = new_seekr_match(
    path = path,
    start_line = 12L,
    end_line = 12L,
    start = 30L,
    end = 32L,
    start_col = 4L,
    end_col = 6L,
    match = "foo",
    replacement = NA_character_,
    before = NA_character_,
    line = "abc foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  y = new_seekr_match(
    path = path,
    start_line = 12L,
    end_line = 12L,
    start = 30L,
    end = 32L,
    start_col = 4L,
    end_col = 6L,
    match = "foo",
    replacement = "bar",
    before = NA_character_,
    line = "abc foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  expect_identical(format(x), paste0(path, "<12:4>: <foo>"))
  expect_identical(format(y), paste0(path, "<12:4>: <foo/bar>"))
})

test_that("pillar methods summarize seekr_match vectors", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "bar",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  expect_identical(pillar::type_sum(x), "seekr::match")
  expect_s3_class(pillar::pillar_shaft(x), "pillar_shaft")
})


# as_tibble(), as.data.frame(), and as_match() ----------------------------

test_that("as_tibble() converts a seekr_match vector to a tibble", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "bar",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  df = tibble::as_tibble(x)

  expect_s3_class(df, "tbl_df")
  expect_identical(names(df), seekr_match_fields())
  expect_identical(df$path, path)
  expect_identical(df$match, "foo")
})

test_that("as.data.frame() converts a seekr_match vector to a data frame", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "bar",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  df = as.data.frame(x)

  expect_s3_class(df, "data.frame")
  expect_false(tibble::is_tibble(df))
  expect_identical(df$path, path)
  expect_identical(df$match, "foo")
})

test_that("as_match() converts a data frame to a seekr_match vector", {
  path = tempfile(fileext = ".txt")

  df = data.frame(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "bar",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  x = as_match(df)

  expect_s3_class(x, "seekr_match")
  expect_equal(length(x), 1L)
  expect_identical(field(x, "path"), path)
  expect_identical(field(x, "match"), "foo")
  expect_identical(field(x, "replacement"), "bar")
})

test_that("as_match() ignores additional columns", {
  path = tempfile(fileext = ".txt")

  df = data.frame(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "bar",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc",
    extra = "ignored"
  )

  x = as_match(df)

  expect_s3_class(x, "seekr_match")
  expect_false("extra" %in% vctrs::fields(x))
})

test_that("as_match() sorts matches within files while preserving file order", {
  path1 = tempfile(fileext = ".txt")
  path2 = tempfile(fileext = ".txt")

  df = data.frame(
    path = c(path2, path1, path2),
    start_line = c(2L, 1L, 1L),
    end_line = c(2L, 1L, 1L),
    start = c(10L, 1L, 1L),
    end = c(12L, 3L, 3L),
    start_col = c(10L, 1L, 1L),
    end_col = c(12L, 3L, 3L),
    match = c("bar", "foo", "baz"),
    replacement = c("BAR", "FOO", "BAZ"),
    before = rep(NA_character_, 3L),
    line = c("bar", "foo", "baz"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "def", "abc")
  )

  x = as_match(df)

  expect_identical(field(x, "path"), c(path2, path2, path1))
  expect_identical(field(x, "start"), c(1L, 10L, 1L))
  expect_identical(field(x, "match"), c("baz", "bar", "foo"))
})

test_that("as_match() rejects non-data-frame inputs", {
  expect_error(as_match(list()))
})

test_that("as_match() rejects missing required columns", {
  path = tempfile(fileext = ".txt")

  df = data.frame(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "bar",
    before = NA_character_,
    line = "foo",
    after = NA_character_
  )

  expect_error(as_match(df))
})

test_that("as_match() rejects non-integer position columns", {
  path = tempfile(fileext = ".txt")

  df = data.frame(
    path = path,
    start_line = 1,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo",
    replacement = "bar",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  expect_error(as_match(df))
})

test_that("as_match() rejects missing matched text", {
  path = tempfile(fileext = ".txt")

  df = data.frame(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = NA_character_,
    replacement = "bar",
    before = NA_character_,
    line = "foo",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  expect_error(as_match(df))
})

test_that("as_match() rejects start after end matches within a file", {
  path = tempfile(fileext = ".txt")

  df = data.frame(
    path = c(path, path),
    start_line = c(1L, 1L),
    end_line = c(1L, 1L),
    start = c(4L, 2L),
    end = c(3L, 4L),
    start_col = c(1L, 2L),
    end_col = c(3L, 4L),
    match = c("foo", "ooz"),
    replacement = c("FOO", "OOZ"),
    before = c(NA_character_, NA_character_),
    line = c("fooz", "fooz"),
    after = c(NA_character_, NA_character_),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  expect_error(as_match(df), class = "seekr_error_match_start_after_end")
})

test_that("as_match() rejects start line after end line within a file", {
  path = tempfile(fileext = ".txt")

  df = data.frame(
    path = c(path, path),
    start_line = c(1L, 8L),
    end_line = c(1L, 7L),
    start = c(1L, 2L),
    end = c(3L, 4L),
    start_col = c(1L, 2L),
    end_col = c(3L, 4L),
    match = c("foo", "ooz"),
    replacement = c("FOO", "OOZ"),
    before = c(NA_character_, NA_character_),
    line = c("fooz", "fooz"),
    after = c(NA_character_, NA_character_),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  expect_error(as_match(df), class = "seekr_error_match_start_after_end_line")
})

test_that("as_match() rejects overlapping matches within a file", {
  path = tempfile(fileext = ".txt")

  df = data.frame(
    path = c(path, path),
    start_line = c(1L, 1L),
    end_line = c(1L, 1L),
    start = c(1L, 2L),
    end = c(3L, 4L),
    start_col = c(1L, 2L),
    end_col = c(3L, 4L),
    match = c("foo", "ooz"),
    replacement = c("FOO", "OOZ"),
    before = c(NA_character_, NA_character_),
    line = c("fooz", "fooz"),
    after = c(NA_character_, NA_character_),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  expect_error(as_match(df), class = "seekr_error_match_order_or_overlap")
})


# filter_match ------------------------------------------------------------

test_that("filter_match() rejects non-seekr_match inputs", {
  expect_error(filter_match(data.frame()))
})

test_that("filter_match() returns x unchanged when no expressions are supplied", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = c(path, path, path),
    start_line = c(1L, 2L, 3L),
    end_line = c(1L, 2L, 3L),
    start = c(1L, 5L, 9L),
    end = c(3L, 7L, 11L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("foo", "bar", "foo"),
    replacement = c("FOO", "BAR", "FOO"),
    before = rep(NA_character_, 3L),
    line = c("foo", "bar", "foo"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "abc", "abc")
  )

  expect_identical(filter_match(x), x)
})

test_that("filter_match() filters using field names", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = c(path, path, path),
    start_line = c(1L, 2L, 3L),
    end_line = c(1L, 2L, 3L),
    start = c(1L, 5L, 9L),
    end = c(3L, 7L, 11L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("foo", "bar", "foo"),
    replacement = c("FOO", "BAR", "FOO"),
    before = rep(NA_character_, 3L),
    line = c("foo", "bar", "foo"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "abc", "abc")
  )

  y = filter_match(x, match == "foo")
  expect_identical(x[c(1, 3)], y)
})

test_that("filter_match() combines multiple expressions with AND", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = c(path, path, path),
    start_line = c(1L, 2L, 3L),
    end_line = c(1L, 2L, 3L),
    start = c(1L, 5L, 9L),
    end = c(3L, 7L, 11L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("foo", "bar", "foo"),
    replacement = c("FOO", "BAR", "FOO"),
    before = rep(NA_character_, 3L),
    line = c("foo", "bar", "foo"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "abc", "abc")
  )

  y = filter_match(x, match == "foo", start_line > 1L)
  expect_identical(x[3], y)
})

test_that("filter_match() can use objects from the calling environment", {
  path = tempfile(fileext = ".txt")
  wanted = "bar"

  x = new_seekr_match(
    path = c(path, path, path),
    start_line = c(1L, 2L, 3L),
    end_line = c(1L, 2L, 3L),
    start = c(1L, 5L, 9L),
    end = c(3L, 7L, 11L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("foo", "bar", "foo"),
    replacement = c("FOO", "BAR", "FOO"),
    before = rep(NA_character_, 3L),
    line = c("foo", "bar", "foo"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "abc", "abc")
  )

  y = filter_match(x, match == wanted)
  expect_identical(x[2], y)
})

test_that("filter_match() works with empty seekr_match vectors", {
  x = new_seekr_match()
  y = filter_match(x, start_line > 1L)

  expect_s3_class(y, "seekr_match")
  expect_equal(length(y), 0L)
})

test_that("filter_match() rejects scalar logical results when x has length greater than one", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = c(path, path),
    start_line = c(1L, 2L),
    end_line = c(1L, 2L),
    start = c(1L, 5L),
    end = c(3L, 7L),
    start_col = c(1L, 1L),
    end_col = c(3L, 3L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = c(NA_character_, NA_character_),
    line = c("foo", "bar"),
    after = c(NA_character_, NA_character_),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  expect_error(filter_match(x, TRUE))
})

test_that("filter_match() rejects non-logical results", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = c(path, path),
    start_line = c(1L, 2L),
    end_line = c(1L, 2L),
    start = c(1L, 5L),
    end = c(3L, 7L),
    start_col = c(1L, 1L),
    end_col = c(3L, 3L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = c(NA_character_, NA_character_),
    line = c("foo", "bar"),
    after = c(NA_character_, NA_character_),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  expect_error(filter_match(x, start_line))
})

test_that("filter_match() rejects missing logical results", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = c(path, path),
    start_line = c(1L, 2L),
    end_line = c(1L, 2L),
    start = c(1L, 5L),
    end = c(3L, 7L),
    start_col = c(1L, 1L),
    end_col = c(3L, 3L),
    match = c("foo", "bar"),
    replacement = c("FOO", "BAR"),
    before = c(NA_character_, NA_character_),
    line = c("foo", "bar"),
    after = c(NA_character_, NA_character_),
    encoding = c("UTF-8", "UTF-8"),
    hash = c("abc", "abc")
  )

  expect_error(filter_match(x, c(TRUE, NA)))
})


# str.seekr_match ---------------------------------------------------------

test_that("str.seekr_match() prints empty seekr_match vectors without error", {
  x = new_seekr_match()

  result = NULL
  output = capture.output(result = result <- str(x))

  expect_identical(result, x)
  expect_length(output, 1L)
})

test_that("str.seekr_match() prints non-empty seekr_match vectors without error", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = path,
    start_line = 1L,
    end_line = 1L,
    start = 1L,
    end = 3L,
    start_col = 1L,
    end_col = 3L,
    match = "foo\nbar",
    replacement = NA_character_,
    before = NA_character_,
    line = "foo\nbar",
    after = NA_character_,
    encoding = "UTF-8",
    hash = "abc"
  )

  result = NULL
  output = capture.output(result = result <- str(x))

  expect_identical(result, x)
  expect_length(output, 15L)
})


# split_match_by_source -----------------------------------------------------

test_that("split_match_by_source() splits matches by file while preserving file order", {
  path1 = tempfile(fileext = ".txt")
  path2 = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = c(path2, path1, path2),
    start_line = c(1L, 1L, 2L),
    end_line = c(1L, 1L, 2L),
    start = c(1L, 1L, 5L),
    end = c(3L, 3L, 7L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("baz", "foo", "bar"),
    replacement = c("BAZ", "FOO", "BAR"),
    before = rep(NA_character_, 3L),
    line = c("baz", "foo", "bar"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "def", "abc")
  )

  out = split_match_by_source(x)

  expect_identical(names(out), c(path2, path1))
  expect_equal(length(out), 2L)
  expect_s3_class(out[[1]], "seekr_match")
  expect_s3_class(out[[2]], "seekr_match")
  expect_identical(field(out[[1]], "path"), c(path2, path2))
  expect_identical(field(out[[2]], "path"), path1)
})


# smash -------------------------------------------------------------------

test_that("smash() returns an empty seekr_match vector for an empty list", {
  expect_identical(smash(list()), new_seekr_match())
})

test_that("smash() returns an empty seekr_match vector for an empty list", {
  path1 = tempfile(fileext = ".txt")
  path2 = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = c(path2, path1, path2),
    start_line = c(1L, 1L, 2L),
    end_line = c(1L, 1L, 2L),
    start = c(1L, 1L, 5L),
    end = c(3L, 3L, 7L),
    start_col = c(1L, 1L, 1L),
    end_col = c(3L, 3L, 3L),
    match = c("baz", "foo", "bar"),
    replacement = c("BAZ", "FOO", "BAR"),
    before = rep(NA_character_, 3L),
    line = c("baz", "foo", "bar"),
    after = rep(NA_character_, 3L),
    encoding = rep("UTF-8", 3L),
    hash = c("abc", "def", "abc")
  )

  x = sort(x)
  y = smash(split_match_by_source(x))

  expect_identical(x, y)
})


# sort_within_files -------------------------------------------------------

test_that("sort_within_files() rejects non-seekr_match inputs", {
  expect_error(sort_within_files(data.frame()))
})

test_that("sort_within_files() returns empty seekr_match vectors unchanged", {
  x = new_seekr_match()
  expect_identical(sort_within_files(x), x)
})

test_that("sort_within_files() sorts matches within each file while preserving file order", {
  path1 = tempfile(fileext = ".txt")
  path2 = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = c(path2, path1, path2, path1),
    start_line = c(2L, 2L, 1L, 1L),
    end_line = c(2L, 2L, 1L, 1L),
    start = c(10L, 5L, 1L, 1L),
    end = c(12L, 7L, 3L, 3L),
    start_col = c(10L, 5L, 1L, 1L),
    end_col = c(12L, 7L, 3L, 3L),
    match = c("bar", "qux", "baz", "foo"),
    replacement = c("BAR", "QUX", "BAZ", "FOO"),
    before = rep(NA_character_, 4L),
    line = c("bar", "qux", "baz", "foo"),
    after = rep(NA_character_, 4L),
    encoding = rep("UTF-8", 4L),
    hash = c("abc", "def", "abc", "def")
  )

  y = sort_within_files(x)
  expect_identical(x[c(3L, 1L, 4L, 2L)], y)
})

test_that("sort_within_files() uses end, match, and replacement as tie breakers", {
  path = tempfile(fileext = ".txt")

  x = new_seekr_match(
    path = rep(path, 4L),
    start_line = rep(1L, 4L),
    end_line = rep(1L, 4L),
    start = rep(1L, 4L),
    end = c(5L, 3L, 3L, 3L),
    start_col = rep(1L, 4L),
    end_col = c(5L, 3L, 3L, 3L),
    match = c("foo", "bar", "aaa", "aaa"),
    replacement = c("FOO", "BAR", "BBB", "AAA"),
    before = rep(NA_character_, 4L),
    line = c("foo", "bar", "aaa", "aaa"),
    after = rep(NA_character_, 4L),
    encoding = rep("UTF-8", 4L),
    hash = c("abc", "abc", "abc", "abc")
  )

  y = sort_within_files(x)
  expect_identical(x[c(4L, 3L, 2L, 1L)], y)
})
