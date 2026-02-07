# Changelog

## seekr (development version)

## seekr 0.1.3

CRAN release: 2025-05-10

- Fixed a test that incorrectly assumed how
  [`normalizePath()`](https://rdrr.io/r/base/normalizePath.html) behaves
  on macOS. The test now avoids relying on full file paths and instead
  checks file names, ensuring compatibility across platforms.

## seekr 0.1.2

CRAN release: 2025-05-05

## seekr 0.1.1

- Added realistic, minimal files (`.R`, `.csv`, `.log`, `.yaml`,
  `.json`) to `inst/extdata/` to demonstrate the package’s usage. These
  files are used in examples and allow
  [`seek()`](https://smartiing.github.io/seekr/reference/seek.md) and
  [`seek_in()`](https://smartiing.github.io/seekr/reference/seek.md) to
  run without requiring external data.

## seekr 0.1.0

- Initial CRAN submission.
