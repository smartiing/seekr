# seekr (development version)

# seekr 0.1.3

* Fixed a test that incorrectly assumed how `normalizePath()` behaves on macOS.
  The test now avoids relying on full file paths and instead checks file names,
  ensuring compatibility across platforms.

# seekr 0.1.2

# seekr 0.1.1

* Added realistic, minimal files (`.R`, `.csv`, `.log`, `.yaml`, `.json`) to 
`inst/extdata/` to demonstrate the package's usage. These files are used in 
examples and allow `seek()` and `seek_in()` to run without requiring external data.

# seekr 0.1.0

* Initial CRAN submission.
