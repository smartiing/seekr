# Tabular workflows

## Overview

[`seek()`](https://smartiing.github.io/seekr/reference/seek.md)/[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md)
returns matches as a `seekr_match` vector. For many workflows, you can
inspect and refine this vector directly with
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html), and
[`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md).

Sometimes, however, it is useful to switch to a tabular workflow. This
is especially true when you want to summarize matches by file, filter
based on group-level information, or prepare replacements with data
frame tools.

This article shows how to:

- convert a `seekr_match` vector to a data frame,
- inspect matches with grouped summaries,
- filter matches using group-level logic,
- update replacements with `dplyr`,
- convert back to a `seekr_match` vector with
  [`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md),
- apply replacements with
  [`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).

The examples use a temporary copy of the example files shipped with
`seekr`, so they are safe to modify.

## Find matches

Suppose we want to inspect log messages.

``` r

library(seekr)
library(dplyr)
library(stringr)
```

``` r

x <- seek("([A-Z]+) : (.+$)", extension = "log")
x
#> <seekr::match[80]> 2 sources
#> Common Path: /tmp/RtmpbfUhm7/seekr-example/extdata
#> 
#> server1.log [10/40]
#>  [1] ->  1 | 2026-06-30 01:13:45 INFO : Starting process
#>  [2] ->  2 | 2026-06-30 15:35:57 DEBUG : Disk usage high
#>  [3] ->  3 | 2026-06-30 20:36:52 WARNING : Timeout reached
#>  [4] ->  4 | 2026-06-30 12:15:22 WARNING : Loading config
#>  [5] ->  5 | 2026-07-01 00:59:41 INFO : Restart scheduled
#>  [6] ->  6 | 2026-06-30 17:03:42 DEBUG : Connection successful
#>  [7] ->  7 | 2026-07-01 00:54:56 DEBUG : Restart scheduled
#>  [8] ->  8 | 2026-06-30 16:43:17 INFO : Timeout reached
#>  [9] ->  9 | 2026-06-30 21:24:23 INFO : Timeout reached
#> [10] -> 10 | 2026-06-30 22:49:27 INFO : Timeout reached
#> 
#> # ℹ 70 more matches
#> # ℹ Use `print(n = ...)` to see more matches
```

We summarize directly to have an idea of what was found.

``` r

summary(x)
#> ── <seekr::match[80]> ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#> Common Path: /tmp/RtmpbfUhm7/seekr-example/extdata
#> 
#> Top sources [2]
#>  • server1.log : 40 (50.0%)
#>  • server2.log : 40 (50.0%)
#> 
#> Top matches [10/31]
#>  • <INFO : Timeout reached>         : 8 (10.0%)
#>  • <DEBUG : Disk usage high>        : 6 ( 7.5%)
#>  • <ERROR : Retrying request>       : 6 ( 7.5%)
#>  • <ERROR : Starting process>       : 5 ( 6.2%)
#>  • <INFO : User login failed>       : 5 ( 6.2%)
#>  • <DEBUG : Failed to authenticate> : 3 ( 3.8%)
#>  • <DEBUG : Loading config>         : 3 ( 3.8%)
#>  • <ERROR : Restart scheduled>      : 3 ( 3.8%)
#>  • <INFO : Connection successful>   : 3 ( 3.8%)
#>  • <WARNING : Disk usage high>      : 3 ( 3.8%)
#> 
#> Top extension [1]
#>  • log : 80 (100.0%)
#> 
#> Top encoding [1]
#>  • UTF-8 : 80 (100.0%)
```

## Convert to a data frame

For simple filtering,
[`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
is usually enough. Let’s keep only the `DEBUG` lines and convert our
vector to a data frame.

``` r

df <- 
  x |> 
  filter_match(str_detect(match, "^DEBUG")) |>
  as_tibble()

df
#> # A tibble: 20 × 14
#>    path                                          start_line end_line start   end start_col end_col match replacement before line  after encoding hash 
#>    <chr>                                              <int>    <int> <int> <int>     <int>   <int> <chr> <chr>       <chr>  <chr> <chr> <chr>    <chr>
#>  1 /tmp/RtmpbfUhm7/seekr-example/extdata/server…          2        2    65    87        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#>  2 /tmp/RtmpbfUhm7/seekr-example/extdata/server…          6        6   245   273        21      49 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#>  3 /tmp/RtmpbfUhm7/seekr-example/extdata/server…          7        7   295   319        21      45 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#>  4 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         12       12   514   536        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#>  5 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         14       14   602   624        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#>  6 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         19       19   831   852        21      42 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#>  7 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         20       20   874   896        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#>  8 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         24       24  1055  1079        21      45 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#>  9 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         25       25  1101  1123        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#> 10 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         28       28  1234  1256        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#> 11 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         31       31  1366  1387        21      42 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#> 12 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         38       38  1686  1709        21      44 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…
#> 13 /tmp/RtmpbfUhm7/seekr-example/extdata/server…          5        5   211   234        21      44 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…
#> 14 /tmp/RtmpbfUhm7/seekr-example/extdata/server…          7        7   299   328        21      50 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…
#> 15 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         10       10   442   463        21      42 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…
#> 16 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         20       20   903   932        21      50 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…
#> 17 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         30       30  1364  1386        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…
#> 18 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         33       33  1496  1519        21      44 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…
#> 19 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         35       35  1585  1614        21      50 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…
#> 20 /tmp/RtmpbfUhm7/seekr-example/extdata/server…         36       36  1636  1664        21      49 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…
```

This gives one row per match and one column per field, which makes
grouped summaries easy.

For example, we could create a custom summary per file for `DEBUG` lines
where we see the number of matches and distinct matches as well as the
first and last lines where we find a match.

``` r

df |>
  summarise(
    n_matches = n(),
    n_distinct_matches = n_distinct(match),
    first_line = min(start_line),
    last_line = max(end_line),
    .by = path
  )
#> # A tibble: 2 × 5
#>   path                                              n_matches n_distinct_matches first_line last_line
#>   <chr>                                                 <int>              <int>      <int>     <int>
#> 1 /tmp/RtmpbfUhm7/seekr-example/extdata/server1.log        12                  6          2        38
#> 2 /tmp/RtmpbfUhm7/seekr-example/extdata/server2.log         8                  5          5        36
```

This kind of question is often easier to answer with a data frame than
with the match vector directly.

## Filter with group-level information

A tabular workflow is also useful when filtering depends on group-level
information.

For example, suppose we only want to keep the latest occurrence of each
distinct `DEBUG` log message in each file.

``` r

latest <-
  df |>
  mutate(
    match_rank_from_end = row_number(desc(start_line)),
    .by = c(path, match)
  ) |>
  filter(match_rank_from_end == 1L)

latest
#> # A tibble: 11 × 15
#>    path                      start_line end_line start   end start_col end_col match replacement before line  after encoding hash  match_rank_from_end
#>    <chr>                          <int>    <int> <int> <int>     <int>   <int> <chr> <chr>       <chr>  <chr> <chr> <chr>    <chr>               <int>
#>  1 /tmp/RtmpbfUhm7/seekr-ex…          6        6   245   273        21      49 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…                   1
#>  2 /tmp/RtmpbfUhm7/seekr-ex…         12       12   514   536        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…                   1
#>  3 /tmp/RtmpbfUhm7/seekr-ex…         24       24  1055  1079        21      45 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…                   1
#>  4 /tmp/RtmpbfUhm7/seekr-ex…         28       28  1234  1256        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…                   1
#>  5 /tmp/RtmpbfUhm7/seekr-ex…         31       31  1366  1387        21      42 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…                   1
#>  6 /tmp/RtmpbfUhm7/seekr-ex…         38       38  1686  1709        21      44 DEBU… NA          "2026… 2026… "202… UTF-8    88aa…                   1
#>  7 /tmp/RtmpbfUhm7/seekr-ex…         10       10   442   463        21      42 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…                   1
#>  8 /tmp/RtmpbfUhm7/seekr-ex…         30       30  1364  1386        21      43 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…                   1
#>  9 /tmp/RtmpbfUhm7/seekr-ex…         33       33  1496  1519        21      44 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…                   1
#> 10 /tmp/RtmpbfUhm7/seekr-ex…         35       35  1585  1614        21      50 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…                   1
#> 11 /tmp/RtmpbfUhm7/seekr-ex…         36       36  1636  1664        21      49 DEBU… NA          "2026… 2026… "202… UTF-8    cb05…                   1
```

The extra column `match_rank_from_end` is useful for now, but it is not
part of a `seekr_match` vector.
[`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
will ignore extra columns and validate the required match fields when
converting back.

## Update replacements

Finally, it is also easy to prepare some replacements. Here, we create
different replacements depending on the content of each match.

``` r

latest <-
  latest |>
  mutate(
    replacement = case_when(
      str_detect(match, "Disk") ~ str_to_upper(match),
      str_detect(match, "config") ~ str_to_lower(match),
      .default = str_to_title(match)
    )
  )

latest |>
  count(match, replacement)
#> # A tibble: 8 × 3
#>   match                          replacement                        n
#>   <chr>                          <chr>                          <int>
#> 1 DEBUG : Connection successful  Debug : Connection Successful      2
#> 2 DEBUG : Disk usage high        DEBUG : DISK USAGE HIGH            2
#> 3 DEBUG : Failed to authenticate Debug : Failed To Authenticate     1
#> 4 DEBUG : Loading config         debug : loading config             2
#> 5 DEBUG : Restart scheduled      Debug : Restart Scheduled          1
#> 6 DEBUG : Retrying request       Debug : Retrying Request           1
#> 7 DEBUG : Starting process       Debug : Starting Process           1
#> 8 DEBUG : Timeout reached        Debug : Timeout Reached            1
```

## Convert back to a seekr_match vector

Before replacing files, convert the data frame back to a `seekr_match`
vector. The result can be printed again with replacement previews now
that some replacements have been set.

``` r

to_replace <- as_match(latest)
to_replace
#> <seekr::match[11]> 2 sources
#> Common Path: /tmp/RtmpbfUhm7/seekr-example/extdata
#> 
#> server1.log [6]
#>  [1] --  6 | 2026-06-30 17:03:42 DEBUG : Connection successful
#>      ++  6 | 2026-06-30 17:03:42 Debug : Connection Successful
#>  [2] -- 12 | 2026-06-30 17:34:23 DEBUG : Timeout reached
#>      ++ 12 | 2026-06-30 17:34:23 Debug : Timeout Reached
#>  [3] -- 24 | 2026-06-30 07:41:37 DEBUG : Restart scheduled
#>      ++ 24 | 2026-06-30 07:41:37 Debug : Restart Scheduled
#>  [4] -- 28 | 2026-06-29 22:58:20 DEBUG : Disk usage high
#>      ++ 28 | 2026-06-29 22:58:20 DEBUG : DISK USAGE HIGH
#>  [5] -- 31 | 2026-06-30 03:04:51 DEBUG : Loading config
#>      ++ 31 | 2026-06-30 03:04:51 debug : loading config
#>  [6] -- 38 | 2026-06-30 19:08:53 DEBUG : Starting process
#>      ++ 38 | 2026-06-30 19:08:53 Debug : Starting Process
#> 
#> server2.log [5]
#>  [7] -- 10 | 2026-06-30 02:19:35 DEBUG : Loading config
#>      ++ 10 | 2026-06-30 02:19:35 debug : loading config
#>  [8] -- 30 | 2026-06-30 00:15:00 DEBUG : Disk usage high
#>      ++ 30 | 2026-06-30 00:15:00 DEBUG : DISK USAGE HIGH
#>  [9] -- 33 | 2026-06-30 11:03:55 DEBUG : Retrying request
#>      ++ 33 | 2026-06-30 11:03:55 Debug : Retrying Request
#> [10] -- 35 | 2026-06-30 04:43:43 DEBUG : Failed to authenticate
#>      ++ 35 | 2026-06-30 04:43:43 Debug : Failed To Authenticate
#> [11] -- 36 | 2026-06-30 16:12:44 DEBUG : Connection successful
#>      ++ 36 | 2026-06-30 16:12:44 Debug : Connection Successful
```

Finally, our `seekr_match` vector can be used to replace only the
selected matches in the files by their corresponding `replacement`.

``` r

replace_files(to_replace)
```
