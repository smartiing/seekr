## Resubmission

This is a resubmission. Following initial submission, I have:

* Not added a scientific reference or DOI, as the package does not implement or replicate any specific published method. It is a utility tool based on regular expression filtering.

* Removed examples for the internal function `read_filter_lines()` as it is not exported.

* Added realistic, minimal files (`.R`, `.csv`, `.log`, `.yaml`, `.json`) to `inst/extdata/` to demonstrate the package's usage. These files are used in examples and allow `seek()` and `seek_in()` to run without requiring external data.

* Replaced all uses of `\\dontrun{}` in examples with executable code by adding small sample files in `inst/extdata/`.

* Rewrote all examples using `system.file("extdata", package = "seekr")` so they can run safely during CRAN checks.


## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.
