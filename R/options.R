#' Retrieve a seekr option
#'
#' @description
#' `seekr_option()` returns the resolved value of a single seekr option.
#'
#' It first checks whether the user has set the option with [base::options()].
#' If not, it returns the package default. The returned value is validated before
#' being returned.
#'
#' This function is mostly useful for seekr's own default arguments, such as:
#'
#' ```
#' .progress = seekr_option("seekr.progress")
#' ```
#'
#' In most cases, users should configure seekr with [base::options()] and inspect
#' available options with [seekr_options()].
#'
#' @param name Name of the seekr option to retrieve, as a single string. See
#'   [seekr_options()] for the list of valid names.
#'
#' @return
#' The resolved option value. The returned type depends on the option:
#' - `logical` for `seekr.progress`.
#' - `character` for all other options (paths, print symbols, and ANSI style
#'   codes).
#'
#' @seealso
#' [seekr_options()] to list all available options and their defaults.
#'
#' @examples
#' seekr_option("seekr.progress")
#' seekr_option("seekr.print.mode")
#'
#' options(seekr.print.mode = "plain")
#' seekr_option("seekr.print.mode")
#'
#' options(seekr.print.mode = NULL)
#' seekr_option("seekr.print.mode")
#'
#' @export
seekr_option = function(name) {
  call = rlang::caller_env()
  defaults = seekr_options_defaults()

  if (!checkmate::test_string(name, na.ok = FALSE)) {
    cli::cli_abort(
      c(
        "Invalid seekr option name.",
        "x" = "Expected a single non-missing string.",
        "i" = "Use {.fun seekr_options} to list available options."
      ),
      class = "seekr_error_option_name",
      call = call
    )
  }

  if (!name %in% names(defaults)) {
    cli::cli_abort(
      c(
        "Unknown seekr option {.val {name}}.",
        "i" = "Use {.fun seekr_options} to list available options."
      ),
      class = "seekr_error_option_unknown",
      call = call
    )
  }

  value = getOption(name, defaults[[name]])
  assert_seekr_option(name, value, call = call)

  return(value)
}


#' List seekr options
#'
#' @description
#' `seekr_options()` returns the options that control seekr's global behavior,
#' along with their current user-defined value and their package default.
#'
#' These options can be changed with [base::options()]. For example:
#'
#' ```
#' options(seekr.progress = FALSE)
#' options(seekr.print.mode = "plain")
#' ```
#'
#' ## Option values
#' The `current` column reports the value currently set with [base::options()].
#' If an option has not been set by the user, `current` is `NA` and seekr falls
#' back to the value shown in `default`.
#'
#' ## Available options
#' The main options are:
#' - `seekr.progress`: whether seekr displays progress messages by default.
#' - `seekr.backup_dir`: directory where backups are stored.
#' - `seekr.print.mode`: print mode, either `"rich"`, `"color"`, or `"plain"`.
#' - `seekr.print.tab`: symbol used to display tab characters.
#' - `seekr.print.newline`: symbol used to display newline characters when printing deleted newlines.
#' - `seekr.style.*`: ANSI style codes used internally by rich printing.
#'
#' The `seekr.style.*` options are intentionally low-level. They accept ANSI SGR
#' codes as strings, such as `"31"`, `"1;31"`, or `"38;5;243"`.
#'
#' @return
#' A tibble with one row per seekr option and the following columns:
#' - `name`: option name.
#' - `current`: value currently set by the user, or `NA` if unset.
#' - `default`: default value used by seekr when the option is unset.
#'
#' @seealso
#' [seekr_option()] to retrieve the resolved value of a single option.
#'
#' @examples
#' seekr_options()
#'
#' # Disable progress messages globally
#' options(seekr.progress = FALSE)
#' seekr_options()
#'
#' # Reset the option
#' options(seekr.progress = NULL)
#'
#' @export
seekr_options = function() {
  defaults = seekr_options_defaults()

  tibble::tibble(
    name = names(defaults),
    current = purrr::map_chr(
      names(defaults),
      \(name) as.character(getOption(name, default = NA_character_))
    ),
    default = as.character(defaults)
  )
}


#' @keywords internal
seekr_options_defaults = function() {
  support_utf8 = cli::is_utf8_output()

  list(
    seekr.progress = rlang::is_interactive(),
    seekr.backup_dir = normalize_path(file.path(rappdirs::user_data_dir(appname = "seekr"), "backup")),
    seekr.style.match_only = "36",
    seekr.style.match = "31",
    seekr.style.replacement = "32",
    seekr.style.dim = "38;5;243",
    seekr.style.class = "3;38;5;243",
    seekr.style.osc8_file = "34",
    seekr.style.osc8_dir = "1;34",
    seekr.style.na = "31",
    seekr.print.mode = default_print_mode(),
    seekr.print.tab = if (support_utf8) "\u2192" else ">",
    seekr.print.newline = if (support_utf8) "\u21b5" else "\u2193"
  )
}


#' @keywords internal
default_print_mode = function(
  n_colors = cli::num_ansi_colors(),
  support_osc8 = cli::ansi_has_hyperlink_support(),
  in_knitr = getOption("knitr.in.progress")
) {
  support_color = n_colors > 1L
  support_osc8 = isTRUE(support_osc8)
  in_knitr = isTRUE(in_knitr)

  if (!support_color) {
    return("plain")
  } else if (in_knitr || !support_osc8) {
    return("color")
  } else {
    return("rich")
  }
}


#' @keywords internal
ansi_option = function(x, style) {
  if (!checkmate::test_string(style)) {
    cli::cli_abort(
      "Internal error: {.arg style} must be a single non-missing string.",
      class = "seekr_error_internal_ansi_style"
    )
  }

  if (seekr_option("seekr.print.mode") == "plain") {
    return(as.character(x))
  }

  style_code = seekr_option(glue::glue("seekr.style.{style}"))
  ansi = ifelse(
    is.na(x),
    NA_character_,
    glue::glue("\033[{style_code}m{x}\033[0m")
  )

  as.character(ansi)
}
