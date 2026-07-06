# Retrieve a seekr option

`seekr_option()` returns the resolved value of a single seekr option.

It first checks whether the user has set the option with
[`base::options()`](https://rdrr.io/r/base/options.html). If not, it
returns the package default. The returned value is validated before
being returned.

This function is mostly useful for seekr's own default arguments, such
as:

    .progress = seekr_option("seekr.progress")

In most cases, users should configure seekr with
[`base::options()`](https://rdrr.io/r/base/options.html) and inspect
available options with
[`seekr_options()`](https://smartiing.github.io/seekr/reference/seekr_options.md).

## Usage

``` r
seekr_option(name)
```

## Arguments

- name:

  Name of the seekr option to retrieve, as a single string. See
  [`seekr_options()`](https://smartiing.github.io/seekr/reference/seekr_options.md)
  for the list of valid names.

## Value

The resolved option value. The returned type depends on the option:

- `logical` for `seekr.progress`.

- `character` for all other options (paths, print symbols, and ANSI
  style codes).

## See also

[`seekr_options()`](https://smartiing.github.io/seekr/reference/seekr_options.md)
to list all available options and their defaults.

## Examples

``` r
seekr_option("seekr.progress")
#> [1] FALSE
seekr_option("seekr.print.mode")
#> [1] "color"

options(seekr.print.mode = "plain")
seekr_option("seekr.print.mode")
#> [1] "plain"

options(seekr.print.mode = NULL)
seekr_option("seekr.print.mode")
#> [1] "color"
```
