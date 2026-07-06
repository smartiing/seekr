# Locate newline character positions in a string

Computes the ending positions of each line (handling all newline
variants).

## Usage

``` r
compute_newline_locs(text)
```

## Arguments

- text:

  Text content as a single string.

## Value

Integer matrix of newlines position with an additional row for the first
line where the start and end position are 0.
