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

- convert a `seekr_match` vector to a tibble with
  [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html),
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
library(purrr)
library(stringr)
```

``` r

x <- seek("([A-Z]+) : (.+$)", extension = "log")
x
#> <seekr::match[80]> 2 sources
#> Common Path: /tmp/RtmpSZhaS5/seekr-example/extdata
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
#> Common Path: /tmp/RtmpSZhaS5/seekr-example/extdata
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

The summary gives a compact overview of the matches, affected files,
extensions, and match/replacement combinations but only the first 10
elements are printed. Here are all of them.

``` r

summary(x) |> print(n = Inf)
#> ── <seekr::match[80]> ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#> Common Path: /tmp/RtmpSZhaS5/seekr-example/extdata
#> 
#> Top sources [2]
#>  • server1.log : 40 (50.0%)
#>  • server2.log : 40 (50.0%)
#> 
#> Top matches [31]
#>  • <INFO : Timeout reached>           : 8 (10.0%)
#>  • <DEBUG : Disk usage high>          : 6 ( 7.5%)
#>  • <ERROR : Retrying request>         : 6 ( 7.5%)
#>  • <ERROR : Starting process>         : 5 ( 6.2%)
#>  • <INFO : User login failed>         : 5 ( 6.2%)
#>  • <DEBUG : Failed to authenticate>   : 3 ( 3.8%)
#>  • <DEBUG : Loading config>           : 3 ( 3.8%)
#>  • <ERROR : Restart scheduled>        : 3 ( 3.8%)
#>  • <INFO : Connection successful>     : 3 ( 3.8%)
#>  • <WARNING : Disk usage high>        : 3 ( 3.8%)
#>  • <DEBUG : Connection successful>    : 2 ( 2.5%)
#>  • <DEBUG : Restart scheduled>        : 2 ( 2.5%)
#>  • <DEBUG : Retrying request>         : 2 ( 2.5%)
#>  • <ERROR : Disk usage high>          : 2 ( 2.5%)
#>  • <ERROR : Failed to authenticate>   : 2 ( 2.5%)
#>  • <ERROR : Loading config>           : 2 ( 2.5%)
#>  • <ERROR : Timeout reached>          : 2 ( 2.5%)
#>  • <INFO : Disk usage high>           : 2 ( 2.5%)
#>  • <INFO : Loading config>            : 2 ( 2.5%)
#>  • <INFO : Retrying request>          : 2 ( 2.5%)
#>  • <WARNING : Connection successful>  : 2 ( 2.5%)
#>  • <WARNING : Loading config>         : 2 ( 2.5%)
#>  • <WARNING : Restart scheduled>      : 2 ( 2.5%)
#>  • <WARNING : Timeout reached>        : 2 ( 2.5%)
#>  • <DEBUG : Starting process>         : 1 ( 1.2%)
#>  • <DEBUG : Timeout reached>          : 1 ( 1.2%)
#>  • <ERROR : Connection successful>    : 1 ( 1.2%)
#>  • <INFO : Restart scheduled>         : 1 ( 1.2%)
#>  • <INFO : Starting process>          : 1 ( 1.2%)
#>  • <WARNING : Failed to authenticate> : 1 ( 1.2%)
#>  • <WARNING : Starting process>       : 1 ( 1.2%)
#> 
#> Top extension [1]
#>  • log : 80 (100.0%)
#> 
#> Top encoding [1]
#>  • UTF-8 : 80 (100.0%)
```

## Filter matches directly

For simple filtering,
[`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
is usually enough. It evaluates expressions directly on the fields of
the `seekr_match` vector.

For example, we can keep only `DEBUG` lines.

``` r

xf <-
  x |>
  filter_match(str_detect(match, "^DEBUG"))

xf
#> <seekr::match[20]> 2 sources
#> Common Path: /tmp/RtmpSZhaS5/seekr-example/extdata
#> 
#> server1.log [12]
#>  [1] ->  2 | 2026-06-30 15:35:57 DEBUG : Disk usage high
#>  [2] ->  6 | 2026-06-30 17:03:42 DEBUG : Connection successful
#>  [3] ->  7 | 2026-07-01 00:54:56 DEBUG : Restart scheduled
#>  [4] -> 12 | 2026-06-30 17:34:23 DEBUG : Timeout reached
#>  [5] -> 14 | 2026-06-30 18:02:47 DEBUG : Disk usage high
#>  [6] -> 19 | 2026-06-30 03:38:08 DEBUG : Loading config
#>  [7] -> 20 | 2026-06-29 23:18:24 DEBUG : Disk usage high
#>  [8] -> 24 | 2026-06-30 07:41:37 DEBUG : Restart scheduled
#>  [9] -> 25 | 2026-06-30 09:38:10 DEBUG : Disk usage high
#> [10] -> 28 | 2026-06-29 22:58:20 DEBUG : Disk usage high
#> [11] -> 31 | 2026-06-30 03:04:51 DEBUG : Loading config
#> [12] -> 38 | 2026-06-30 19:08:53 DEBUG : Starting process
#> 
#> server2.log [8]
#> [13] ->  5 | 2026-06-30 02:03:55 DEBUG : Retrying request
#> [14] ->  7 | 2026-07-01 00:05:54 DEBUG : Failed to authenticate
#> [15] -> 10 | 2026-06-30 02:19:35 DEBUG : Loading config
#> [16] -> 20 | 2026-06-30 12:13:34 DEBUG : Failed to authenticate
#> [17] -> 30 | 2026-06-30 00:15:00 DEBUG : Disk usage high
#> [18] -> 33 | 2026-06-30 11:03:55 DEBUG : Retrying request
#> [19] -> 35 | 2026-06-30 04:43:43 DEBUG : Failed to authenticate
#> [20] -> 36 | 2026-06-30 16:12:44 DEBUG : Connection successful
```

At this point, `xf` is simply our `seekr_match` vector, filtered.

``` r

print(xf)
#> <seekr::match[20]> 2 sources
#> Common Path: /tmp/RtmpSZhaS5/seekr-example/extdata
#> 
#> server1.log [12]
#>  [1] ->  2 | 2026-06-30 15:35:57 DEBUG : Disk usage high
#>  [2] ->  6 | 2026-06-30 17:03:42 DEBUG : Connection successful
#>  [3] ->  7 | 2026-07-01 00:54:56 DEBUG : Restart scheduled
#>  [4] -> 12 | 2026-06-30 17:34:23 DEBUG : Timeout reached
#>  [5] -> 14 | 2026-06-30 18:02:47 DEBUG : Disk usage high
#>  [6] -> 19 | 2026-06-30 03:38:08 DEBUG : Loading config
#>  [7] -> 20 | 2026-06-29 23:18:24 DEBUG : Disk usage high
#>  [8] -> 24 | 2026-06-30 07:41:37 DEBUG : Restart scheduled
#>  [9] -> 25 | 2026-06-30 09:38:10 DEBUG : Disk usage high
#> [10] -> 28 | 2026-06-29 22:58:20 DEBUG : Disk usage high
#> [11] -> 31 | 2026-06-30 03:04:51 DEBUG : Loading config
#> [12] -> 38 | 2026-06-30 19:08:53 DEBUG : Starting process
#> 
#> server2.log [8]
#> [13] ->  5 | 2026-06-30 02:03:55 DEBUG : Retrying request
#> [14] ->  7 | 2026-07-01 00:05:54 DEBUG : Failed to authenticate
#> [15] -> 10 | 2026-06-30 02:19:35 DEBUG : Loading config
#> [16] -> 20 | 2026-06-30 12:13:34 DEBUG : Failed to authenticate
#> [17] -> 30 | 2026-06-30 00:15:00 DEBUG : Disk usage high
#> [18] -> 33 | 2026-06-30 11:03:55 DEBUG : Retrying request
#> [19] -> 35 | 2026-06-30 04:43:43 DEBUG : Failed to authenticate
#> [20] -> 36 | 2026-06-30 16:12:44 DEBUG : Connection successful
```

## Convert to a tibble

For more complex inspection, convert the match vector to a tibble and
put the path at the end for display reasons.

``` r

xdf <- 
  xf |>
  as_tibble() |>
  relocate(path, .after = last_col())

xdf
#> # A tibble: 20 × 14
#>    start_line end_line start   end start_col end_col match                          replacement before                line  after encoding hash  path 
#>         <int>    <int> <int> <int>     <int>   <int> <chr>                          <chr>       <chr>                 <chr> <chr> <chr>    <chr> <chr>
#>  1          2        2    65    87        21      43 DEBUG : Disk usage high        NA          "2026-06-30 01:13:45… 2026… "202… UTF-8    88aa… /tmp…
#>  2          6        6   245   273        21      49 DEBUG : Connection successful  NA          "2026-06-30 01:13:45… 2026… "202… UTF-8    88aa… /tmp…
#>  3          7        7   295   319        21      45 DEBUG : Restart scheduled      NA          "2026-06-30 15:35:57… 2026… "202… UTF-8    88aa… /tmp…
#>  4         12       12   514   536        21      43 DEBUG : Timeout reached        NA          "2026-07-01 00:54:56… 2026… "202… UTF-8    88aa… /tmp…
#>  5         14       14   602   624        21      43 DEBUG : Disk usage high        NA          "2026-06-30 21:24:23… 2026… "202… UTF-8    88aa… /tmp…
#>  6         19       19   831   852        21      42 DEBUG : Loading config         NA          "2026-06-30 18:02:47… 2026… "202… UTF-8    88aa… /tmp…
#>  7         20       20   874   896        21      43 DEBUG : Disk usage high        NA          "2026-06-30 15:51:48… 2026… "202… UTF-8    88aa… /tmp…
#>  8         24       24  1055  1079        21      45 DEBUG : Restart scheduled      NA          "2026-06-30 03:38:08… 2026… "202… UTF-8    88aa… /tmp…
#>  9         25       25  1101  1123        21      43 DEBUG : Disk usage high        NA          "2026-06-29 23:18:24… 2026… "202… UTF-8    88aa… /tmp…
#> 10         28       28  1234  1256        21      43 DEBUG : Disk usage high        NA          "2026-06-30 12:00:01… 2026… "202… UTF-8    88aa… /tmp…
#> 11         31       31  1366  1387        21      42 DEBUG : Loading config         NA          "2026-06-30 14:59:05… 2026… "202… UTF-8    88aa… /tmp…
#> 12         38       38  1686  1709        21      44 DEBUG : Starting process       NA          "2026-06-30 11:14:29… 2026… "202… UTF-8    88aa… /tmp…
#> 13          5        5   211   234        21      44 DEBUG : Retrying request       NA          "2026-06-30 12:51:40… 2026… "202… UTF-8    cb05… /tmp…
#> 14          7        7   299   328        21      50 DEBUG : Failed to authenticate NA          "2026-06-30 10:39:57… 2026… "202… UTF-8    cb05… /tmp…
#> 15         10       10   442   463        21      42 DEBUG : Loading config         NA          "2026-06-30 02:03:55… 2026… "202… UTF-8    cb05… /tmp…
#> 16         20       20   903   932        21      50 DEBUG : Failed to authenticate NA          "2026-06-30 00:39:03… 2026… "202… UTF-8    cb05… /tmp…
#> 17         30       30  1364  1386        21      43 DEBUG : Disk usage high        NA          "2026-06-30 21:38:09… 2026… "202… UTF-8    cb05… /tmp…
#> 18         33       33  1496  1519        21      44 DEBUG : Retrying request       NA          "2026-06-29 23:53:42… 2026… "202… UTF-8    cb05… /tmp…
#> 19         35       35  1585  1614        21      50 DEBUG : Failed to authenticate NA          "2026-06-30 00:15:00… 2026… "202… UTF-8    cb05… /tmp…
#> 20         36       36  1636  1664        21      49 DEBUG : Connection successful  NA          "2026-06-30 19:27:14… 2026… "202… UTF-8    cb05… /tmp…
```

This gives one row per match and one column per field, which makes
grouped summaries easy.

For example, we could create a custom summary per file where we see the
number of matches and distinct matches as well as the first and last
lines where we find a match.

``` r

xdf |>
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
#> 1 /tmp/RtmpSZhaS5/seekr-example/extdata/server1.log        12                  6          2        38
#> 2 /tmp/RtmpSZhaS5/seekr-example/extdata/server2.log         8                  5          5        36
```

This kind of question is often easier to answer with a tibble than with
the match vector directly.

## Filter with group-level information

A tabular workflow is also useful when filtering depends on group-level
information.

For example, suppose we only want to keep the latest occurrence of each
distinct log message in each file.

``` r

latest <-
  xdf |>
  mutate(
    match_rank_from_end = row_number(desc(start_line)),
    .by = c(path, match)
  ) |>
  filter(match_rank_from_end == 1L)

latest
#> # A tibble: 11 × 15
#>    start_line end_line start   end start_col end_col match                     replacement before line  after encoding hash  path  match_rank_from_end
#>         <int>    <int> <int> <int>     <int>   <int> <chr>                     <chr>       <chr>  <chr> <chr> <chr>    <chr> <chr>               <int>
#>  1          6        6   245   273        21      49 DEBUG : Connection succe… NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#>  2         12       12   514   536        21      43 DEBUG : Timeout reached   NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#>  3         24       24  1055  1079        21      45 DEBUG : Restart scheduled NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#>  4         28       28  1234  1256        21      43 DEBUG : Disk usage high   NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#>  5         31       31  1366  1387        21      42 DEBUG : Loading config    NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#>  6         38       38  1686  1709        21      44 DEBUG : Starting process  NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#>  7         10       10   442   463        21      42 DEBUG : Loading config    NA          "2026… 2026… "202… UTF-8    cb05… /tmp…                   1
#>  8         30       30  1364  1386        21      43 DEBUG : Disk usage high   NA          "2026… 2026… "202… UTF-8    cb05… /tmp…                   1
#>  9         33       33  1496  1519        21      44 DEBUG : Retrying request  NA          "2026… 2026… "202… UTF-8    cb05… /tmp…                   1
#> 10         35       35  1585  1614        21      50 DEBUG : Failed to authen… NA          "2026… 2026… "202… UTF-8    cb05… /tmp…                   1
#> 11         36       36  1636  1664        21      49 DEBUG : Connection succe… NA          "2026… 2026… "202… UTF-8    cb05… /tmp…                   1
```

We can also continue filtering with regular `dplyr` expressions. Here,
we remove messages mentioning connections.

``` r

latest <-
  latest |>
  filter_out(str_detect(match, "Connection"))

latest
#> # A tibble: 9 × 15
#>   start_line end_line start   end start_col end_col match                      replacement before line  after encoding hash  path  match_rank_from_end
#>        <int>    <int> <int> <int>     <int>   <int> <chr>                      <chr>       <chr>  <chr> <chr> <chr>    <chr> <chr>               <int>
#> 1         12       12   514   536        21      43 DEBUG : Timeout reached    NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#> 2         24       24  1055  1079        21      45 DEBUG : Restart scheduled  NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#> 3         28       28  1234  1256        21      43 DEBUG : Disk usage high    NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#> 4         31       31  1366  1387        21      42 DEBUG : Loading config     NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#> 5         38       38  1686  1709        21      44 DEBUG : Starting process   NA          "2026… 2026… "202… UTF-8    88aa… /tmp…                   1
#> 6         10       10   442   463        21      42 DEBUG : Loading config     NA          "2026… 2026… "202… UTF-8    cb05… /tmp…                   1
#> 7         30       30  1364  1386        21      43 DEBUG : Disk usage high    NA          "2026… 2026… "202… UTF-8    cb05… /tmp…                   1
#> 8         33       33  1496  1519        21      44 DEBUG : Retrying request   NA          "2026… 2026… "202… UTF-8    cb05… /tmp…                   1
#> 9         35       35  1585  1614        21      50 DEBUG : Failed to authent… NA          "2026… 2026… "202… UTF-8    cb05… /tmp…                   1
```

The extra column `match_rank_from_end` is useful while working as a
tibble, but it is not part of a `seekr_match` vector.
[`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
will ignore extra columns and validate the required match fields when
converting back.

## Update replacements in a tibble

Finally, a tibble workflow can also be used to prepare replacements.

Here, we create different replacements depending on the content of each
match.

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
#> # A tibble: 7 × 3
#>   match                          replacement                        n
#>   <chr>                          <chr>                          <int>
#> 1 DEBUG : Disk usage high        DEBUG : DISK USAGE HIGH            2
#> 2 DEBUG : Failed to authenticate Debug : Failed To Authenticate     1
#> 3 DEBUG : Loading config         debug : loading config             2
#> 4 DEBUG : Restart scheduled      Debug : Restart Scheduled          1
#> 5 DEBUG : Retrying request       Debug : Retrying Request           1
#> 6 DEBUG : Starting process       Debug : Starting Process           1
#> 7 DEBUG : Timeout reached        Debug : Timeout Reached            1
```

## Convert back to a seekr_match vector

Before replacing files, convert the tibble back to a `seekr_match`
vector. The result can be printed again with replacement previews now
that some replacements have been set.

``` r

to_replace <- as_match(latest)
to_replace
#> <seekr::match[9]> 2 sources
#> Common Path: /tmp/RtmpSZhaS5/seekr-example/extdata
#> 
#> server1.log [5]
#> [1] -- 12 | 2026-06-30 17:34:23 DEBUG : Timeout reached
#>     ++ 12 | 2026-06-30 17:34:23 Debug : Timeout Reached
#> [2] -- 24 | 2026-06-30 07:41:37 DEBUG : Restart scheduled
#>     ++ 24 | 2026-06-30 07:41:37 Debug : Restart Scheduled
#> [3] -- 28 | 2026-06-29 22:58:20 DEBUG : Disk usage high
#>     ++ 28 | 2026-06-29 22:58:20 DEBUG : DISK USAGE HIGH
#> [4] -- 31 | 2026-06-30 03:04:51 DEBUG : Loading config
#>     ++ 31 | 2026-06-30 03:04:51 debug : loading config
#> [5] -- 38 | 2026-06-30 19:08:53 DEBUG : Starting process
#>     ++ 38 | 2026-06-30 19:08:53 Debug : Starting Process
#> 
#> server2.log [4]
#> [6] -- 10 | 2026-06-30 02:19:35 DEBUG : Loading config
#>     ++ 10 | 2026-06-30 02:19:35 debug : loading config
#> [7] -- 30 | 2026-06-30 00:15:00 DEBUG : Disk usage high
#>     ++ 30 | 2026-06-30 00:15:00 DEBUG : DISK USAGE HIGH
#> [8] -- 33 | 2026-06-30 11:03:55 DEBUG : Retrying request
#>     ++ 33 | 2026-06-30 11:03:55 Debug : Retrying Request
#> [9] -- 35 | 2026-06-30 04:43:43 DEBUG : Failed to authenticate
#>     ++ 35 | 2026-06-30 04:43:43 Debug : Failed To Authenticate
```

## Replace selected matches

[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
applies replacements from the current `seekr_match` vector.

This is important: only the matches still present in `to_replace` are
replaced. Matches that were filtered out of the tibble workflow are not
modified.

``` r

replaced <- replace_files(to_replace)
replaced
#> <seekr::match[9]> 2 sources
#> Common Path: /tmp/RtmpSZhaS5/seekr-example/extdata
#> 
#> server1.log [5]
#> [1] -- 12 | 2026-06-30 17:34:23 DEBUG : Timeout reached
#>     ++ 12 | 2026-06-30 17:34:23 Debug : Timeout Reached
#> [2] -- 24 | 2026-06-30 07:41:37 DEBUG : Restart scheduled
#>     ++ 24 | 2026-06-30 07:41:37 Debug : Restart Scheduled
#> [3] -- 28 | 2026-06-29 22:58:20 DEBUG : Disk usage high
#>     ++ 28 | 2026-06-29 22:58:20 DEBUG : DISK USAGE HIGH
#> [4] -- 31 | 2026-06-30 03:04:51 DEBUG : Loading config
#>     ++ 31 | 2026-06-30 03:04:51 debug : loading config
#> [5] -- 38 | 2026-06-30 19:08:53 DEBUG : Starting process
#>     ++ 38 | 2026-06-30 19:08:53 Debug : Starting Process
#> 
#> server2.log [4]
#> [6] -- 10 | 2026-06-30 02:19:35 DEBUG : Loading config
#>     ++ 10 | 2026-06-30 02:19:35 debug : loading config
#> [7] -- 30 | 2026-06-30 00:15:00 DEBUG : Disk usage high
#>     ++ 30 | 2026-06-30 00:15:00 DEBUG : DISK USAGE HIGH
#> [8] -- 33 | 2026-06-30 11:03:55 DEBUG : Retrying request
#>     ++ 33 | 2026-06-30 11:03:55 Debug : Retrying Request
#> [9] -- 35 | 2026-06-30 04:43:43 DEBUG : Failed to authenticate
#>     ++ 35 | 2026-06-30 04:43:43 Debug : Failed To Authenticate
```

## Restore the example files

The examples above modified files in a temporary directory.
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
created a backup before writing, so we can restore the previous contents
if we need to.

``` r

bck <- last_backup()
bck
#> # A tibble: 2 × 9
#>      id created_at          operation description original                                          backup         original_exists backup_exists  size
#>   <int> <dttm>              <chr>     <chr>       <chr>                                             <chr>          <lgl>           <lgl>         <fs:>
#> 1     1 2026-07-07 05:57:57 replace   NA          /tmp/RtmpSZhaS5/seekr-example/extdata/server1.log /tmp/RtmpSZha… TRUE            TRUE          1.76K
#> 2     1 2026-07-07 05:57:57 replace   NA          /tmp/RtmpSZhaS5/seekr-example/extdata/server2.log /tmp/RtmpSZha… TRUE            TRUE           1.8K
restore_files(from = bck$backup, to = bck$original)
#> ℹ Creating a backup of the current version of each existing destination file before restoring it.
#> ℹ This ensures you can revert to the state before restoration if needed.
```

After restoring, the original matches are back.

``` r

after_restore <- seek("([A-Z]+) : (.+$)", extension = "log")
print(after_restore)
#> <seekr::match[80]> 2 sources
#> Common Path: /tmp/RtmpSZhaS5/seekr-example/extdata
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
identical(x, after_restore)
#> [1] TRUE
```

## When to use this pattern

You do not need a tabular workflow for every search-and-replace task.

Use
[`filter_match()`](https://smartiing.github.io/seekr/reference/filter_match.md)
when you want to filter matches with simple expressions based on match
fields.

Use
[`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
and
[`as_match()`](https://smartiing.github.io/seekr/reference/as_tibble.seekr_match.md)
when you want to use data frame tools, especially for grouped summaries,
group-aware filtering, joins, or more complex replacement preparation.
