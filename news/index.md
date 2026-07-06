# Changelog

## seekr 0.2.0

This is a complete redesign of `seekr`.

`seekr` is now a much more ambitious package built around a different
model of search-and-replace. Instead of providing a small set of helpers
for finding text in files, it now introduces a full workflow for listing
files, filtering files, finding matches, inspecting and refining
results, staging replacements, modifying selected files, creating
backups, and restoring them.

This release introduces the `seekr_match` vector, implemented as a vctrs
record-style (`rcrd`) vector. Each element represents one independent
match in one file, while fields store the file path, match location,
matched text, planned replacement, surrounding context, and related
metadata.

This release is intentionally not backward compatible with `seekr`
0.1.3. The scope of the package has expanded substantially, and keeping
the previous API would have required maintaining two separate paradigms
side by side. The previous API has therefore been removed, and existing
code using earlier versions of `seekr` will need to be rewritten with
the new workflow-oriented API.

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
  `seek_in()` to run without requiring external data.

## seekr 0.1.0

- Initial CRAN submission.
