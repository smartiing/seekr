# Read a file and decode its content to a string.

`ff_seekr_read_file()` is a factory that returns a closure,
`seekr_read_file()`. The factory pattern is used to maintain a
per-session locale cache: since
[`readr::locale()`](https://readr.tidyverse.org/reference/locale.html)
is not free to construct, the closure caches one locale object per
encoding across the R session.

## Usage

``` r
ff_seekr_read_file()
```

## Details

The returned function reads up to `n_bytes` raw bytes from `path`,
detects or applies `encoding`, and returns the decoded file content as a
single string with an `"encoding"` attribute.
