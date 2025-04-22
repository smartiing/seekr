Sys.setenv('_R_CHECK_SYSTEM_CLOCK_' = 0)

#' @keywords internal
set_seekr_verbose_default = function() {
  if (is.null(getOption("seekr.verbose"))) {
    options(seekr.verbose = interactive())
  }
}

.onLoad = function(libname, pkgname) {
  set_seekr_verbose_default()
}
