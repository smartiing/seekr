# Detect Null Bytes in a File

Reads the first `n` bytes of a file and checks whether any null bytes
(`0x00`) are present, which is commonly used to detect binary files.

If the file cannot be read (e.g., corrupted or permission issues), the
function safely assumes the file is binary and returns `TRUE`.

## Usage

``` r
has_null_bytes(file, n = 1000L)
```

## Arguments

- file:

  A character string representing a single file path.

- n:

  The number of bytes to read for binary detection in files with unknown
  extensions. Defaults to 1000.

## Value

`TRUE` if a null byte is found or if an error occurs. `FALSE` otherwise.
