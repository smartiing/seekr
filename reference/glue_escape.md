# Escape curly braces for use in glue::glue templates

Converts `{` to `{{` and `}` to `}}` to prevent premature evaluation in
[`glue::glue()`](https://glue.tidyverse.org/reference/glue.html).

## Usage

``` r
glue_escape(x)
```

## Arguments

- x:

  A character vector.

## Value

Escaped character vector
