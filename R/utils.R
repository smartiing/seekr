#' @title Should CLI Output Be Printed?
#'
#' @description
#' Determines whether CLI progress or messaging functions should be executed.
#' This helper evaluates the `seekr.verbose` option, checks for an interactive session,
#' and disables output during testthat tests.
#'
#' @returns A logical scalar: `TRUE` if CLI output should be shown, `FALSE` otherwise.
#'
#' @details
#' This function is designed to control conditional CLI output (e.g., [cli::cli_progress_step()]).
#' It returns `TRUE` only when:
#' \itemize{
#'   \item `getOption("seekr.verbose", TRUE)` is `TRUE`
#'   \item the session is interactive (`interactive()`)
#'   \item testthat is not running (`!testthat::is_testing()`)
#' }
#'
#' @keywords internal
print_cli = function() {
  getOption("seekr.verbose", TRUE) &&
    !testthat::is_testing()
}


#' @title Check Flag or Scalar Integerish
#'
#' @description This function validates whether the input is either a logical flag
#' (`TRUE`/`FALSE`) or a scalar integer-like value (e.g., `1`, `2L`, etc.).
#'
#' @param x The object to check.
#'
#' @returns `TRUE` if the input is a valid flag or scalar integerish, otherwise an error message string.
#'
#' @keywords internal
check_flag_or_scalar_integerish = function(x) {
  is_flag = checkmate::test_flag(x)
  is_scalar_integerish = checkmate::test_integerish(x, len = 1L, any.missing = FALSE)

  if (!(is_flag || is_scalar_integerish)) {
    return("Must be a flag or a single integerish")
  } else {
    return(TRUE)
  }
}


#' @title Assert Flag or Scalar Integerish
#'
#' @description Assertion function for [check_flag_or_scalar_integerish()]. Will throw an error if
#' the input is invalid.
#'
#' @inheritParams check_flag_or_scalar_integerish
#'
#' @keywords internal
assert_flag_or_scalar_integerish = checkmate::makeAssertionFunction(check_flag_or_scalar_integerish)


#' @title Extract Lowercase File Extensions
#'
#' @description
#' Extracts the file extensions from the provided file paths, normalizes them
#' to lowercase, and returns them as a character vector. The extension includes
#' the leading period (`.`).
#'
#' @inheritParams filter_files
#'
#' @returns A character vector of lowercase file extensions.
#'
#' @keywords internal
extract_lower_file_extension = function(files) {
  stringr::str_extract(stringr::str_to_lower(files), "\\.([[:alnum:]]+)$")
}
