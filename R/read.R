#' Read a file and decode its content to a string.
#'
#' `ff_seekr_read_file()` is a factory that returns a closure, `seekr_read_file()`.
#' The factory pattern is used to maintain a per-session locale cache: since
#' `readr::locale()` is not free to construct, the closure caches one locale object
#' per encoding across the R session.
#'
#' The returned function reads up to `n_bytes` raw bytes from `path`, detects
#' or applies `encoding`, and returns the decoded file content as a single
#' string with an `"encoding"` attribute.
#'
#' @keywords internal
ff_seekr_read_file = function() {
  list_locales = list()
  encodings_allowing_null_bytes = c(
    "UTF-16BE",
    "UTF-16LE",
    "UTF-32BE",
    "UTF-32LE"
  )

  function(path, n_bytes, encoding, call = rlang::caller_env()) {
    if (n_bytes == 0L) {
      text = structure("", encoding = encoding)
      return(text)
    }

    bytes = tryCatch(
      expr = {
        readBin(path, raw(), n = n_bytes)
      },
      warning = function(cnd) {
        stop(conditionMessage(cnd))
      },
      error = function(cnd) {
        cli::cli_abort(
          c(
            "Failed to read file.",
            "x" = "`{conditionMessage(cnd)}`",
            "i" = "{fs::path(path)}"
          ),
          call = call,
          class = "seekr_error_read_bytes"
        )
      }
    )

    file_is_empty = rlang::is_empty(bytes)
    if (file_is_empty) {
      text = structure("", encoding = encoding)
      return(text)
    }

    guess_encoding = is.null(encoding)
    if (guess_encoding) {
      encoding = stringi::stri_enc_detect(str = bytes)[[1]]$Encoding[[1]]

      if (is.na(encoding)) {
        encoding = "UTF-8"
        cli::cli_warn(
          c(
            "Failed to detect file encoding.",
            "i" = "{fs::path(path)}",
            "i" = "Defaulting to UTF-8"
          ),
          class = "seekr_warning_read_encoding_detection_failed"
        )
      }
    }

    encoding_cant_have_null_bytes = !encoding %in% encodings_allowing_null_bytes
    if (encoding_cant_have_null_bytes && any(bytes == as.raw(0))) {
      cli::cli_warn(
        c(
          "File skipped, null bytes detected.",
          "i" = "{fs::path(path)}",
          "i" = "Null bytes are only supported for UTF-16/32 encodings, not {.val {encoding}}."
        ),
        class = "seekr_warning_read_null_bytes"
      )

      text = structure(NA_character_, encoding = encoding)
      return(text)
    }

    if (!encoding %in% names(list_locales)) {
      list_locales[[encoding]] <<- readr::locale(encoding = encoding)
    }

    text = tryCatch(
      expr = {
        readr::read_file(file = bytes, locale = list_locales[[encoding]])
      },
      error = function(cnd) {
        cli::cli_abort(
          c(
            "Failed to decode file using {.val {encoding}}.",
            "x" = "{conditionMessage(cnd)}",
            "i" = "{fs::path(path)}"
          ),
          call = call,
          class = "seekr_error_read_decode"
        )
      }
    )

    if (!stringr::str_detect(encoding, "(?i)utf-?8")) {
      cli::cli_warn(
        c(
          "Some files were read with a non-UTF-8 encoding.",
          "i" = "{.fn replace_files} always writes files in UTF-8.",
          "i" = "Calling {.fn replace_files} on these matches will fail unless {.code allow_encoding_change = TRUE} is set."
        ),
        .frequency = "once",
        .frequency_id = "seekr_non_utf8_encoding",
        class = "seekr_warning_non_utf8_encoding"
      )
    }

    return(structure(text, encoding = encoding))
  }
}


#' @keywords internal
seekr_read_file = ff_seekr_read_file()
