recreate_dirs = function(dirs) {
  for (dir in dirs) {
    if (fs::dir_exists(dir)) {
      fs::dir_delete(dir)
    }

    fs::dir_create(dir)
  }
}

write_file = function(x, file) {
  x = paste0(x, collapse = "\n")
  readr::write_file(x, file, append = FALSE)
}


# Create assert test content ----------------------------------------------

recreate_dirs(c(
  test_path("fixtures", "assert"),
  test_path("fixtures", "assert", "dir1"),
  test_path("fixtures", "assert", "dir2", "nested")
))

write_file(
  "File at the root.",
  test_path("fixtures", "assert", "root-file.txt")
)

write_file(
  "File inside dir1.",
  test_path("fixtures", "assert", "dir1", "dir1.txt")
)

write_file(
  "File nested in dir2.",
  test_path("fixtures", "assert", "dir2", "nested", "nested.txt")
)


# Create read-file files --------------------------------------------------

recreate_dirs(test_path("fixtures", "read-file"))

file.create(test_path("fixtures", "read-file", "empty.txt"))

write_file(
  "hello world",
  test_path("fixtures", "read-file", "plain.txt")
)

write_file(
  c("café TODO","second line"),
  test_path("fixtures", "read-file", "utf8.txt")
)

writeBin(
  as.raw(c(0x61, 0x00, 0x62, 0x00, 0x63)),
  test_path("fixtures", "read-file", "null-bytes.bin")
)


# Create list-files files -------------------------------------------------

recreate_dirs(c(
  test_path("fixtures", "listing"),
  test_path("fixtures", "listing", "dir1"),
  test_path("fixtures", "listing", "dir2", "nested")
))

write_file(
  "\n\n\nFile at the root.\nafter\n",
  test_path("fixtures", "listing", "root-file.txt")
)

write_file(
  "\n\n\nFirst file in dir1.\nafter\n",
  test_path("fixtures", "listing", "dir1", "dir1-file-a.txt")
)

write_file(
  "\n\n\nSecond file in dir1.\nafter\n",
  test_path("fixtures", "listing", "dir1", "dir1-file-b.R")
)

write_file(
  "\n\n\nFile in dir2.\nafter\n",
  test_path("fixtures", "listing", "dir2", "dir2-file.md")
)

write_file(
  "\n\n\nNested file in dir2.\nafter\n",
  test_path("fixtures", "listing", "dir2", "nested", "nested-file.txt")
)


# Create filtering files --------------------------------------------------

recreate_dirs(c(
  test_path("fixtures", "filtering"),
  test_path("fixtures", "filtering", "keep"),
  test_path("fixtures", "filtering", "skip"),
  test_path("fixtures", "filtering", "size"),
  test_path("fixtures", "filtering", "node_modules", "pkg"),
  test_path("fixtures", "filtering", ".git", "objects")
))


write_file(
  "R file at the root.",
  test_path("fixtures", "filtering", "root-r.R")
)

write_file(
  "Text file at the root.",
  test_path("fixtures", "filtering", "root-txt.txt")
)

write_file(
  "A,B\n1,2",
  test_path("fixtures", "filtering", "upper.CSV")
)

write_file(
  "File without extension.",
  test_path("fixtures", "filtering", "no-extension")
)

write_file(
  "File kept by path pattern.",
  test_path("fixtures", "filtering", "keep", "keep-r.R")
)

write_file(
  "File excluded by custom exclude function.",
  test_path("fixtures", "filtering", "skip", "skip-r.R")
)

write_file(
  "small",
  test_path("fixtures", "filtering", "size", "small.txt")
)

write_file(
  paste(rep("large", 50L), collapse = " "),
  test_path("fixtures", "filtering", "size", "large.txt")
)

write_file(
  "module code",
  test_path("fixtures", "filtering", "node_modules", "pkg", "package.js")
)

write_file(
  "git config",
  test_path("fixtures", "filtering", ".git", "objects", "config")
)

write_file(
  "function(x){return(x+1)}",
  test_path("fixtures", "filtering", "app.min.js")
)

writeBin(
  as.raw(c(0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10)),
  test_path("fixtures", "filtering", "image.jpg")
)


# Create matching files ---------------------------------------------------

recreate_dirs(test_path("fixtures", "matching"))

write_file(
  c("before", "TODO one", "between", "TODO two", "after"),
  test_path("fixtures", "matching", "two-matches.txt")
)

write_file(
  c("alpha", "beta", "gamma"),
  test_path("fixtures", "matching", "no-match.txt")
)

file.create(test_path("fixtures", "matching", "empty.txt"))

write_file(
  c("TODO-first", "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "TODO-second"),
  test_path("fixtures", "matching", "n-bytes.txt")
)

write_file(
  "alpha_one beta_ gamma_two",
  test_path("fixtures", "matching", "capture-groups.txt")
)

write_file(
  "curly TODO braces",
  test_path("fixtures", "matching", "braces.txt")
)

writeBin(
  charToRaw("alpha\r\nTODO beta\r\ngamma"),
  test_path("fixtures", "matching", "crlf.txt")
)

writeBin(
  as.raw(c(0x61, 0x00, 0x62, 0x00, 0x63)),
  test_path("fixtures", "matching", "null-bytes.bin")
)
