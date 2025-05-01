# Helper: Create a realistic fake file environment
create_mixed_test_files = function(tmpdir) {
  # Text R scripts
  writeLines(c("myfunc = function(x) { x + 1 }"), file.path(tmpdir, "script1.R"))
  writeLines(c("yourfunc = function(x) { x + 1 }"), file.path(tmpdir, "script2.R"))
  writeLines(c("# TODO: refactor this code"), file.path(tmpdir, "script3.R"))

  # CSV file with header
  writeLines(c("id,name,date", "1,John,2020-01-01"), file.path(tmpdir, "data1.csv"))
  writeLines(c("name;age;city", "Alice;30;Paris"), file.path(tmpdir, "data2.csv"))

  # Log files
  writeLines(
    c("INFO: Started server", "ERROR: Failed to load config"),
    file.path(tmpdir, "server.log")
  )
  writeLines(c("ERROR: Connection timeout"), file.path(tmpdir, "error.log"))

  # Binary-like files (fake binary)
  writeBin(as.raw(1:100), file.path(tmpdir, "image.png"))
  writeBin(as.raw(101:200), file.path(tmpdir, "program.exe"))

  # File without extension
  writeLines(c("just some random text"), file.path(tmpdir, "README"))

  # Corrupted/binary unknown extension
  writeBin(as.raw(0:255), file.path(tmpdir, "binaryfile"))
}
