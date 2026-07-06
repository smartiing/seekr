# Design choices

## Overview

The central object in `seekr` is the `seekr_match` vector. Technically,
it is implemented as a [`vctrs` record-style
vector](https://vctrs.r-lib.org/reference/new_rcrd.html): a vector
object made of several same-length fields, where the internal field
structure supports the object but is not the main user-facing
abstraction.

This article explains two related design choices:

1.  why `seekr` represents search results as a vector of matches;
2.  how replacements are applied only to matches that were previously
    found and potentially filtered.

It is not a tutorial and it does not try to show everything the package
can do. Instead, it describes the design problem behind `seekr`: how to
make search and replacement inspectable, composable, and safe from
inside R.

The design started from a few requirements:

- After the search step, files should not need to be read again until
  replacements are applied.
- A search result should therefore be rich enough to support most
  operations after the search without reading the files again.
- A user should be able to print matches with context, summarize them,
  filter them, and preview replacements.
- The user should be able to set or update replacements after the
  search.
- Each match should be independent. If a search finds fifty matches and
  the user keeps only five, those five matches should still carry enough
  information to be printed, summarized, updated, and eventually
  replaced.
- Replacement should be safe. When files are modified, `seekr` should
  replace the matches that were inspected and kept, instead of blindly
  rerunning a pattern and replacing whatever happens to match later.

The `seekr_match` vector is the object that came out of these
constraints.

## A first example

Here is a simple search over the example files shipped with `seekr`.

``` r

x <- seekr(
  pattern = "([a-z]+)_([a-z]+)(?= <- function)",
  replacement = "\\2_\\1",
  path = system.file("extdata", package = "seekr")
)
```

The result is a `seekr_match` vector. It can be inspected as a
structured object.

``` r

str(x)
#> <seekr::match[5]> vctrs::rcrd
#> path        <chr> "/home/runner/work/_temp/Library/seekr/extdata/script1.R", "/home/runner/work/_temp/Library/seekr/extdata/script1.R", "/home/runner/…
#> start_line  <int> 1, 9, 2, 7, 12
#> end_line    <int> 1, 9, 2, 7, 12
#> start       <int> 1, 107, 32, 119, 202
#> end         <int> 7, 115, 40, 125, 213
#> start_col   <int> 1, 1, 1, 1, 1
#> end_col     <int> 7, 9, 9, 7, 12
#> match       <chr> "add_one", "say_hello", "mean_safe", "sd_safe", "print_vector"
#> replacement <chr> "one_add", "hello_say", "safe_mean", "safe_sd", "vector_print"
#> before      <chr> NA, "\ncapitalize <- function(txt) {\n  toupper(substr(txt, 1, 1))\n}\n", "# TODO: optimize this function", "mean_safe <- function(x…
#> line        <chr> "add_one <- function(x) {", "say_hello <- function(name) {", "mean_safe <- function(x) {", "sd_safe <- function(x) {", "print_vector…
#> after       <chr> "  return(x + 1)\n}\n\ncapitalize <- function(txt) {\n  toupper(substr(txt, 1, 1))", "  paste('Hello', name)\n}\n", "  if (length(x)…
#> encoding    <chr> "UTF-8", "UTF-8", "UTF-8", "UTF-8", "UTF-8"
#> hash        <chr> "e4cc5c4031699a911e6d5029cce6d71c", "e4cc5c4031699a911e6d5029cce6d71c", "036951bf4066a0b69595b7a0d9d0eb96", "036951bf4066a0b69595b7a…
```

Matches found can also be summarised.

``` r

summary(x)
#> ── <seekr::match[5]> ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#> Common Path: /home/runner/work/_temp/Library/seekr/extdata
#> 
#> Top sources [2]
#>  • script2.R : 3 (60.0%)
#>  • script1.R : 2 (40.0%)
#> 
#> Top matches/replacements [5]
#>  • <say_hello/hello_say>       : 1 (20.0%)
#>  • <add_one/one_add>           : 1 (20.0%)
#>  • <mean_safe/safe_mean>       : 1 (20.0%)
#>  • <sd_safe/safe_sd>           : 1 (20.0%)
#>  • <print_vector/vector_print> : 1 (20.0%)
#> 
#> Top extension [1]
#>  • r : 5 (100.0%)
#> 
#> Top encoding [1]
#>  • UTF-8 : 5 (100.0%)
```

It can be printed with context and replacement previews.

``` r

print(x, context = c(0, 2L))
#> <seekr::match[5]> 2 sources
#> Common Path: /home/runner/work/_temp/Library/seekr/extdata
#> 
#> script1.R [2]
#> [1] --  1 | add_one <- function(x) {
#>     ++  1 | one_add <- function(x) {
#>         2 |   return(x + 1)
#>         3 | }
#> 
#> [2] --  9 | say_hello <- function(name) {
#>     ++  9 | hello_say <- function(name) {
#>        10 |   paste('Hello', name)
#>        11 | }
#> 
#> script2.R [3]
#> [3] --  2 | mean_safe <- function(x) {
#>     ++  2 | safe_mean <- function(x) {
#>         3 |   if (length(x) == 0) return(NA)
#>         4 |   mean(x, na.rm = TRUE)
#> 
#> [4] --  7 | sd_safe <- function(x) {
#>     ++  7 | safe_sd <- function(x) {
#>         8 |   if (length(x) <= 1) return(NA)
#>         9 |   sd(x, na.rm = TRUE)
#> 
#> [5] -- 12 | print_vector <- function(v) {
#>     ++ 12 | vector_print <- function(v) {
#>        13 |   print(paste('Vector of length', length(v)))
#>        14 | }
```

## What each match needs to carry

To support the workflow, a match needs to remember more than the matched
string.

A `seekr_match` stores information such as the file path, match
location, matched text, optional replacement, surrounding context,
encoding, and a hash of the searched text. This is what allows
[`print()`](https://rdrr.io/r/base/print.html) to display matches with
context, [`summary()`](https://rdrr.io/r/base/summary.html) to aggregate
matches by file or replacement,
[`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
to filter matches without searching again, and
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
to later check and replace the recorded matches safely.

The goal is that, after the search step, most decisions can be made from
the match vector itself. The files only need to be read again when it is
time to verify and apply replacements.

That is the main reason `seekr_match` contains context, location,
replacement, encoding, and hash information directly. It turns the
search result into something actionable, not just something printable.

## Why not plain printed output?

The simplest representation of search results is console output: print
the matching lines and let the user read them.

That works for quick exploration, but it is not enough for `seekr`.

Printed output is hard to manipulate. It cannot easily be subset,
filtered, summarized, converted, or passed to another function. It also
cannot act as a contract for later replacement, because the information
needed to apply changes safely has already been flattened into text for
humans.

`seekr` needed an object that could still be printed nicely, but that
remained structured enough for later operations.

## Why not a data frame?

A data frame was the most obvious alternative.

It is familiar to R users, easy to inspect, and very convenient for
tabular workflows. In fact, `seekr_match` vectors can be converted to
tibbles with
[`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
and converted back with
[`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md).
For examples of this style of workflow, see the [tabular workflows
article](https://smartiing.github.io/seekr/articles/tabular-workflows.md).

But a data frame did not feel right as the core representation.

The main drawbacks were:

- **Most fields should not be modified directly.** Fields such as
  `path`, `start_line`, `end_line`, `match`, `before`, `line`, `after`,
  `encoding`, and `hash` describe what was found. They are part of the
  recorded search result. In normal use, the only field users are
  expected to modify is `replacement`. A data frame makes every column
  feel equally editable, while a `seekr_match` vector makes it clearer
  that these fields describe matches rather than ordinary analysis
  variables.

- **The natural print method is not tabular.** The most useful way to
  print matches is not as rows and columns. It is to group matches by
  file, show surrounding context, display the matched line, and preview
  the planned replacement. That output is closer to a structured search
  result than to a data frame.

- **The natural summary is not a data frame preview either.** A useful
  summary should describe the search result: how many matches were
  found, which files and extensions are affected, and which
  match/replacement combinations are planned.

- **A match is one entity made of several fields.** In a data frame,
  this idea is less explicit. The result looks like a table with many
  columns, rather than a vector where each element is one match. With a
  `seekr_match` vector, subsetting feels natural: `x[1]` means “the
  first match”, not “the first row of a table that happens to represent
  a match”.

- **The object needs match-specific behavior and validation.** `seekr`
  needs to preserve invariants that are specific to matches: positions
  must be valid, matches within a file must not overlap, all matches for
  a given source must refer to a single searched version of that source
  before replacement, and so on. A custom vector object makes this
  behavior part of the abstraction.

This does not mean that data frames are the wrong tool. They are
extremely useful when the workflow becomes tabular: grouped summaries,
joins, group-aware filtering, or complex replacement preparation. That
is why `seekr` provides
[`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
and
[`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md).

## Why not one object per file?

Another design considered was to have a file-centric structure.

For example, a search over ten files could have returned a list of ten
file objects. Each file object could have stored the file path, probably
the full text, the encoding, and all matches found in that file.

This design had some attractive properties. Search happens in files, so
grouping by file is natural. It could also avoid duplicating some
information because values shared by all matches in a file could live
once at the file level.

But it also made the user-facing workflow much more complicated.

Filtering matches would require working inside a nested structure.
Updating replacements would mean modifying matches inside file objects.
Combining results from several searches would raise questions about how
to merge file-level objects. Simple operations would often require
`map()`, loops, or custom helpers.

Storing the full file text inside the result object was also not ideal.
It would make some operations easier, but it would be expensive for
large files or broad searches.

The file-centric design was more normalized, but less pleasant to use.
It preserved the fact that matches came from files, but it made the
match itself less directly accessible.

By contrast, a vector of matches gives the user a much simpler mental
model: if a search returns 50 matches across 20 files, the result is a
vector of 50 matches. Each element represents one match at one location
in one source. This makes ordinary operations easier to reason about:
keep some matches, drop others, filter by matched text, filter by
context, update replacements, or combine results from several searches.

A nested file-centric object would probably require its own class, its
own accessors, and its own filtering helpers. If context lived at the
file level, or had to be recomputed from stored file text, even simple
questions such as “keep only matches whose surrounding context contains
this word” would become much more complex.

Combining results would also be less obvious. If two searches returned
two nested file-centric objects, the user would need to understand how
file-level objects are merged, how matches from the same file are
combined, and how conflicting metadata is handled. With a `seekr_match`
vector, the mental model is much simpler: two search results are two
vectors of matches, and combining them is just vector concatenation, for
example `c(x, y)`.

## Why a vector of matches?

The final design is thus a vector where each element represents one
independent match in one source. This has an important consequence: once
matches have been found, the user can work with them as a collection of
matches.

A `seekr_match` vector can be subset, filtered, combined, sorted,
summarized, printed, converted to a data frame, converted back, and
eventually passed to replacement functions.

This design favors independence over perfect memory efficiency. Two
matches from the same file may store the same path. Two nearby matches
may store overlapping context. That duplication is intentional. It means
that each match remains understandable and actionable even after
subsetting.

If a user keeps only one match, that match still knows where it came
from, what text was matched, what context surrounds it, and what
replacement is planned. If a user filters fifty matches down to five,
the remaining five are still complete.

This is the trade-off at the heart of `seekr_match`: a little more
duplication in exchange for a much simpler and more composable
user-facing object.

## Replacing what was inspected

The match vector also matters when files are modified.

A common search-and-replace workflow is to search first, inspect the
results, and then run a second command that performs the replacement. In
many tools, that second step reruns the search pattern and replaces
whatever matches at that later moment. As a result, the user cannot
usually keep only a hand-picked subset of matches, and there is no
protection against changes made to the file between search and
replacement.

That is not how `seekr` is designed.
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
starts from the current `seekr_match` vector. It does not rerun the
original search and replace every new match it can find. Instead, it
uses the selected matches and their current replacements.

This is what makes the workflow inspectable. A user can search broadly,
print the result, filter out false positives, update replacements, and
then call
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).
Only the matches still present in the vector are candidates for
replacement.

This gives the user more control, but it creates a safety requirement:
`seekr` must make sure that the recorded match positions still refer to
the same text that was searched.

If a file changed after the search, the recorded positions might no
longer be valid. Text could have been inserted before and shifted the
match. A new occurrence could have appeared. Replacing at the old
recorded positions could modify the wrong part of the file.

So `seekr` does not trust recorded positions blindly.

## Why seekr checks the searched text hash

When `seekr` creates a `seekr_match` vector, it records a hash of the
searched text.

Before replacement,
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
reads the file again and computes the hash again.
[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md)
does the same check with the text supplied by the user. Replacement
proceeds only if the current text has the same hash as the text that was
searched.

In other words, `seekr` only applies replacements when the source text
has not changed since the matches were created.

This is strict, but it is easy to reason about. If the hash matches, the
recorded positions still refer to the same text. If the hash does not
match, `seekr` stops and asks the user to search again on the current
version.

That strictness is intentional. The point is not to guess whether a
replacement would probably still be safe. The point is to make sure that
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
changes exactly the matches represented by the current `seekr_match`
vector.

This design is especially important because matches can be filtered and
replacements can be updated after the search. Once the user has decided
which matches to keep, `seekr` should not silently expand the
replacement set by rerunning the pattern on a changed file.

The consequence is simple: if the file changed, search again.

``` r

x <- seekr("old_name", "new_name")

# Inspect, filter, or modify x...

replace_files(x)
```

If one of the files changed between
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) and
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md),
replacement will fail for all files before replacing any of the match.
If a file changes while the files are being replaced, the remaining
files will not be replaced and
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
will return the vector of match actually replaced.

If one of the files changed between
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md) and the
initial safety check in
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md),
replacement will fail before replacing any match. If a file changes
while files are being replaced,
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
stops before replacing that file. Files already processed may already
have been modified, and the remaining files are not replaced.

This also means that `seekr` is not designed for replacing text in
sources that are continuously changing. For example, if a log file
receives new lines every few seconds, the hash will change between
search and replacement unless both operations happen before the next
write. In that case, a streaming or append-aware tool is probably a
better fit.

## Encoding and replacement scope

Encoding is another place where `seekr` deliberately chooses a strict
and explicit design.

Command-line search and replacement tools do not all handle encodings in
the same way. Some tools operate mostly on bytes, some depend on the
system locale, and some allow the user to specify an encoding
explicitly. In general, a plain text file does not always carry reliable
information about the encoding it uses, so automatic detection cannot be
perfect.

`seekr` therefore does not try to be a universal encoding-preserving
editor. When matches are created, the encoding used to read the source
text is recorded in the `seekr_match` vector. When replacements are
applied to files, `seekr` writes UTF-8 text. By default, it refuses to
silently rewrite a non-UTF-8 file as UTF-8, the user has to make that
choice explicitly.

This is a design trade-off. It makes replacement less magical, but
easier to reason about. `seekr` avoids pretending that encoding changes
are harmless implementation details. If the user needs full control over
reading, transforming, and writing text, they can use the lower-level
in-memory tools described in the [working with in-memory
text](https://smartiing.github.io/seekr/articles/in-memory-text.md)
article.

## Summary

`seekr_match` exists because `seekr` treats search-and-replace as a
workflow.

A plain printed result was not structured enough. A data frame was
familiar and had some advantages, but it did not communicate the
match-specific behavior and invariants clearly enough. A file-centric
object was natural in some ways, but too nested and heavy for everyday
manipulation.

A structured vector of independent matches offered the best trade-off.

It gives each match enough information to be inspected, summarized,
filtered, updated, and replaced later. It uses more memory than a fully
normalized structure, but it keeps the object simple, composable, and
directly useful.

The same design also makes safe replacement possible. `seekr` does not
rerun a search pattern at replacement time and replace whatever matches
then. It replaces only the matches that are still present in the
`seekr_match` vector, and only if the searched text has not changed.

That design choice is what makes `seekr` work the way it does: matches
are structured, replacements target only inspected results, file changes
are detected before writing, and encoding changes are never hidden from
the user.
