# Should CLI Output Be Printed?

Determines whether CLI progress or messaging functions should be
executed. This helper evaluates the `seekr.verbose` option, checks for
an interactive session, and disables output during testthat tests.

## Usage

``` r
print_cli()
```

## Value

A logical scalar: `TRUE` if CLI output should be shown, `FALSE`
otherwise.

## Details

This function is designed to control conditional CLI output (e.g.,
[`cli::cli_progress_step()`](https://cli.r-lib.org/reference/cli_progress_step.html)).
It returns `TRUE` only when:

- `getOption("seekr.verbose", TRUE)` is `TRUE`

- the session is interactive
  ([`interactive()`](https://rdrr.io/r/base/interactive.html))

- testthat is not running (`!testthat::is_testing()`)
