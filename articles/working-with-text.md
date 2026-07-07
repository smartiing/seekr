# Working with text

The usual `seekr` workflow starts from files.

You call
[`seek()`](https://smartiing.github.io/seekr/reference/seek.md),
[`seekr()`](https://smartiing.github.io/seekr/reference/seek.md), or
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)
to search files and create a `seekr_match` vector. You inspect, filter,
or update that vector. Then, if needed, you pass it to
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
to apply the selected replacements back to disk.

That workflow is useful when files are the source of truth and when you
want `seekr` to handle file reading and writing for you.

But sometimes the text you want to search does not come directly from
files, or you need more control over how text is read, transformed, and
written. For example, text may come from a database, an API, a package
object, a clipboard, a web request, or a custom file-reading function.
You may also want to decide exactly what happens after replacement:
update a database row, send the result to an API, write a custom SQL
script, preserve a specific encoding, or use your own output format.

For those cases, `seekr` provides two lower-level counterparts to
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)
and
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md):

- [`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
  searches one in-memory string and returns a `seekr_match` vector.
- [`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md)
  applies a `seekr_match` vector back to an in-memory string and returns
  the modified text.

These functions let you use `seekr` as a search-and-replacement engine
for strings. You still get structured match objects, context printing,
replacement previews, filtering, and safety checks, but you remain
responsible for where the text comes from and where the modified text
goes.

## Example: updating SQL procedures from a table

Imagine that you have extracted a few SQL procedures from a database.

In this example, the procedures are already available in a tibble. In a
real workflow, this table could have been created from a database query,
an API call, or any other source.

``` r

library(seekr)
library(dplyr)
library(purrr)
```

``` r

df
#> # A tibble: 5 × 2
#>   name                     body                                                                                                                       
#>   <chr>                    <chr>                                                                                                                      
#> 1 refresh_customer_scores  "\nCREATE OR REPLACE FUNCTION refresh_customer_scores()\nRETURNS void AS $$\nBEGIN\n  UPDATE customer_scores\n  SET old_sc…
#> 2 refresh_offer_flags      "\nCREATE OR REPLACE FUNCTION refresh_offer_flags()\nRETURNS void AS $$\nBEGIN\n  UPDATE offer_flags\n  SET old_flag = TRU…
#> 3 archive_old_events       "\nCREATE OR REPLACE FUNCTION archive_old_events()\nRETURNS void AS $$\nBEGIN\n  DELETE FROM events\n  WHERE event_date < …
#> 4 refresh_campaign_targets "\nCREATE OR REPLACE FUNCTION refresh_campaign_targets()\nRETURNS void AS $$\nBEGIN\n  UPDATE campaign_targets\n  SET old_…
#> 5 cleanup_temp_tables      "\nCREATE OR REPLACE FUNCTION cleanup_temp_tables()\nRETURNS void AS $$\nBEGIN\n  DELETE FROM temp_work_table;\nEND;\n$$ L…
```

Suppose we want to rename some old SQL identifiers before reviewing and
re-running the procedures.

The text is not coming from files, so we use
[`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
instead of
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md).

[`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
searches one string at a time. It also needs a `path`, which is used as
a source identifier in the resulting `seekr_match` vector. Here, we use
the procedure name as that identifier.

``` r

df <- 
  df |>
  mutate(
    x = map2(
      name, 
      body, 
      \(name, body) match_text(
        text = body,
        path = name,
        pattern = "old_([a-z_]+)",
        replacement = "new_\\1"
      )
    ),
    .before = name
  )
```

The result is a list-column of `seekr_match` vectors.

``` r

df
#> # A tibble: 5 × 3
#>   x                  name                     body                                                                                                    
#>   <list>             <chr>                    <chr>                                                                                                   
#> 1 <seekr::match [2]> refresh_customer_scores  "\nCREATE OR REPLACE FUNCTION refresh_customer_scores()\nRETURNS void AS $$\nBEGIN\n  UPDATE customer_s…
#> 2 <seekr::match [1]> refresh_offer_flags      "\nCREATE OR REPLACE FUNCTION refresh_offer_flags()\nRETURNS void AS $$\nBEGIN\n  UPDATE offer_flags\n …
#> 3 <seekr::match [1]> archive_old_events       "\nCREATE OR REPLACE FUNCTION archive_old_events()\nRETURNS void AS $$\nBEGIN\n  DELETE FROM events\n  …
#> 4 <seekr::match [1]> refresh_campaign_targets "\nCREATE OR REPLACE FUNCTION refresh_campaign_targets()\nRETURNS void AS $$\nBEGIN\n  UPDATE campaign_…
#> 5 <seekr::match [0]> cleanup_temp_tables      "\nCREATE OR REPLACE FUNCTION cleanup_temp_tables()\nRETURNS void AS $$\nBEGIN\n  DELETE FROM temp_work…
```

Each row still contains the original text and the matches found in that
text. This is useful because we can now use ordinary data-frame
operations to decide which procedures we want to keep.

For example, we can keep only procedures where at least one match was
found.

``` r

df <- 
  df |>
  filter(!map_lgl(x, is_empty))

df
#> # A tibble: 4 × 3
#>   x                  name                     body                                                                                                    
#>   <list>             <chr>                    <chr>                                                                                                   
#> 1 <seekr::match [2]> refresh_customer_scores  "\nCREATE OR REPLACE FUNCTION refresh_customer_scores()\nRETURNS void AS $$\nBEGIN\n  UPDATE customer_s…
#> 2 <seekr::match [1]> refresh_offer_flags      "\nCREATE OR REPLACE FUNCTION refresh_offer_flags()\nRETURNS void AS $$\nBEGIN\n  UPDATE offer_flags\n …
#> 3 <seekr::match [1]> archive_old_events       "\nCREATE OR REPLACE FUNCTION archive_old_events()\nRETURNS void AS $$\nBEGIN\n  DELETE FROM events\n  …
#> 4 <seekr::match [1]> refresh_campaign_targets "\nCREATE OR REPLACE FUNCTION refresh_campaign_targets()\nRETURNS void AS $$\nBEGIN\n  UPDATE campaign_…
```

We can also inspect all matches together by combining the list-column
into one `seekr_match` vector.

``` r

x <- reduce(df$x, c, .init = new_seekr_match())
print(x, context = 2L)
#> <seekr::match[5]> 4 sources
#> refresh_customer_scores [2]
#>        4 | BEGIN
#>        5 |   UPDATE customer_scores
#> [1] -- 6 |   SET old_score = old_score + 1;
#>     ++ 6 |   SET new_score = old_score + 1;
#> [2] -- 6 |   SET old_score = old_score + 1;
#>     ++ 6 |   SET old_score = new_score + 1;
#>        7 | END;
#>        8 | $$ LANGUAGE plpgsql;
#> 
#> refresh_offer_flags [1]
#>        4 | BEGIN
#>        5 |   UPDATE offer_flags
#> [3] -- 6 |   SET old_flag = TRUE
#>     ++ 6 |   SET new_flag = TRUE
#>        7 |   WHERE active = TRUE;
#>        8 | END;
#> 
#> archive_old_events [1]
#>        1 | 
#> [4] -- 2 | CREATE OR REPLACE FUNCTION archive_old_events()
#>     ++ 2 | CREATE OR REPLACE FUNCTION archive_new_events()
#>        3 | RETURNS void AS $$
#>        4 | BEGIN
#> 
#> refresh_campaign_targets [1]
#>        4 | BEGIN
#>        5 |   UPDATE campaign_targets
#> [5] -- 6 |   SET old_segment = 'active'
#>     ++ 6 |   SET new_segment = 'active'
#>        7 |   WHERE last_seen >= CURRENT_DATE - INTERVAL '30 days';
#>        8 | END;
```

At this point, `x` is a regular `seekr_match` vector and can be
inspected like any other search result.

``` r

summary(x)
#> ── <seekr::match[5]> ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#> Top sources [4]
#>  • refresh_customer_scores  : 2 (40.0%)
#>  • archive_old_events       : 1 (20.0%)
#>  • refresh_campaign_targets : 1 (20.0%)
#>  • refresh_offer_flags      : 1 (20.0%)
#> 
#> Top matches/replacements [4]
#>  • <old_score/new_score>     : 2 (40.0%)
#>  • <old_events/new_events>   : 1 (20.0%)
#>  • <old_flag/new_flag>       : 1 (20.0%)
#>  • <old_segment/new_segment> : 1 (20.0%)
#> 
#> Top extension [1]
#>  •  : 5 (100.0%)
#> 
#> Top encoding [1]
#>  • NA : 5 (100.0%)
```

## Filtering before replacement

One advantage of the in-memory workflow is that the match vectors remain
linked to the text they came from.

Suppose we decide that only some procedures should be updated. For
example, we may want to update the 3 refresh procedures, but leave other
procedures unchanged for now.

``` r

df <- 
  df |>
  filter(grepl("^refresh_", name))

df
#> # A tibble: 3 × 3
#>   x                  name                     body                                                                                                    
#>   <list>             <chr>                    <chr>                                                                                                   
#> 1 <seekr::match [2]> refresh_customer_scores  "\nCREATE OR REPLACE FUNCTION refresh_customer_scores()\nRETURNS void AS $$\nBEGIN\n  UPDATE customer_s…
#> 2 <seekr::match [1]> refresh_offer_flags      "\nCREATE OR REPLACE FUNCTION refresh_offer_flags()\nRETURNS void AS $$\nBEGIN\n  UPDATE offer_flags\n …
#> 3 <seekr::match [1]> refresh_campaign_targets "\nCREATE OR REPLACE FUNCTION refresh_campaign_targets()\nRETURNS void AS $$\nBEGIN\n  UPDATE campaign_…
```

## Applying replacements in memory

We can now apply the selected replacements with
[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md).

Unlike
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md),
this does not write anything to disk. It simply returns a modified
string and the updated text is now just another column.

``` r

df <- 
  df |>
  mutate(
    body_replaced = map2_chr(
      body, 
      x, 
      \(body, x) replace_text(text = body, x = x)
    ), 
    .before = body
  )

df
#> # A tibble: 3 × 4
#>   x                  name                     body_replaced                                                                                      body 
#>   <list>             <chr>                    <chr>                                                                                              <chr>
#> 1 <seekr::match [2]> refresh_customer_scores  "\nCREATE OR REPLACE FUNCTION refresh_customer_scores()\nRETURNS void AS $$\nBEGIN\n  UPDATE cust… "\nC…
#> 2 <seekr::match [1]> refresh_offer_flags      "\nCREATE OR REPLACE FUNCTION refresh_offer_flags()\nRETURNS void AS $$\nBEGIN\n  UPDATE offer_fl… "\nC…
#> 3 <seekr::match [1]> refresh_campaign_targets "\nCREATE OR REPLACE FUNCTION refresh_campaign_targets()\nRETURNS void AS $$\nBEGIN\n  UPDATE cam… "\nC…
```

This is the point of the in-memory workflow: `seekr` helped us find,
inspect, filter, and safely apply replacements, but it did not decide
what to do with the result.

## Writing a custom SQL script

Because the updated procedures are ordinary strings, we can write them
however we want.

For example, we can combine the updated procedures into a single SQL
script. We can also add comments, separators, or any other metadata that
makes sense for the target system.

``` r

sql_script <- 
  df |>
  mutate(
    script_block = paste0(
      "-- Procedure: ", name, " -------------------------------\n",
      body_replaced
    )
  ) |>
  pull(script_block)

cat(sql_script, sep = "\n\n")
#> -- Procedure: refresh_customer_scores -------------------------------
#> 
#> CREATE OR REPLACE FUNCTION refresh_customer_scores()
#> RETURNS void AS $$
#> BEGIN
#>   UPDATE customer_scores
#>   SET new_score = new_score + 1;
#> END;
#> $$ LANGUAGE plpgsql;
#> 
#> 
#> -- Procedure: refresh_offer_flags -------------------------------
#> 
#> CREATE OR REPLACE FUNCTION refresh_offer_flags()
#> RETURNS void AS $$
#> BEGIN
#>   UPDATE offer_flags
#>   SET new_flag = TRUE
#>   WHERE active = TRUE;
#> END;
#> $$ LANGUAGE plpgsql;
#> 
#> 
#> -- Procedure: refresh_campaign_targets -------------------------------
#> 
#> CREATE OR REPLACE FUNCTION refresh_campaign_targets()
#> RETURNS void AS $$
#> BEGIN
#>   UPDATE campaign_targets
#>   SET new_segment = 'active'
#>   WHERE last_seen >= CURRENT_DATE - INTERVAL '30 days';
#> END;
#> $$ LANGUAGE plpgsql;
```

The script could then be written to disk, copied into a SQL client, sent
to a deployment tool, or reviewed manually.

``` r

writeLines(sql_script, "updated_procedures.sql")
```

## Safety checks still apply

[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md)
follows the same safety principle as
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md).

A `seekr_match` vector records a hash of the text that was searched.
When you call
[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md),
`seekr` checks that the text supplied to
[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md)
is the same text that was used to create the matches.

This prevents replacements from being applied to stale positions.

For example, if the text is changed after matching but before
replacement,
[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md)
will fail rather than applying replacements to a string that no longer
corresponds to the recorded matches.

``` r

x <- match_text(
  text = "Original text with old_name.",
  path = "example",
  pattern = "old_name",
  replacement = "new_name",
  encoding = "UTF-8"
)

replace_text(text = "Modified text with the match: old_name.", x)
```

The safe workflow is the same as with files: if the text changed, search
again.

## Why not use stringr directly?

For simple in-memory replacements, using `stringr` directly is often the
right choice.

If you already know exactly what should be replaced and you want to
replace every occurrence in a string, a direct call to
[`stringr::str_replace_all()`](https://stringr.tidyverse.org/reference/str_replace.html)
is simpler than creating a `seekr_match` vector.

The reason to use
[`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
and
[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md)
is when replacement is not just a single immediate operation.

With direct replacement, the search and replacement happen at the same
time. This is efficient, but it leaves little room for inspection. You
do not get a structured object containing all matches, their locations,
surrounding context, and planned replacements. You also cannot easily
print the matches with context, preview the replacements, filter out
false positives, update replacements match by match, and then apply only
the selected changes.

To get that kind of workflow with `stringr` alone, you would need to
first find all matches, store their positions, extract context, keep
track of replacements, filter the result, and then carefully apply the
selected replacements back to the original text. In other words, you
would start rebuilding much of what a `seekr_match` vector already
represents.

[`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
and
[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md)
are useful when you want the flexibility of working with strings in
memory, but still want the structured, inspectable, and safe replacement
workflow that `seekr` provides.

## Summary

Use
[`match_files()`](https://smartiing.github.io/seekr/reference/match_files.md)
and
[`replace_files()`](https://smartiing.github.io/seekr/reference/replace_files.md)
when files are the source of truth and you want `seekr` to handle file
reading and writing.

Use
[`match_text()`](https://smartiing.github.io/seekr/reference/match_text.md)
and
[`replace_text()`](https://smartiing.github.io/seekr/reference/replace_text.md)
when you want to bring your own text into the `seekr` workflow and
decide yourself what to do with the modified result.

This is useful when text comes from a database, an API, an object in
memory, or a custom reading process. It is also useful when you need
full control over output: writing a custom script, updating a database,
preserving a specific encoding, or sending the result somewhere else.

The core idea is the same in both workflows: search results become
`seekr_match` vectors that can be inspected, filtered, updated, and then
applied safely.
