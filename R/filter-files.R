#' @title Filter Files by Pattern and Content Type
#'
#' @description
#' Filters a character vector of file paths using a user-defined pattern and additional
#' content-based criteria to ensure only likely text files are retained.
#'
#' This function applies multiple filters:
#' \itemize{
#'   \item A regex-based path filter (if provided).
#'   \item Exclusion of files located within `.git` folders.
#'   \item Exclusion of files with known binary or non-text extensions.
#'   \item A fallback scan for embedded null bytes to detect binary content in ambiguous files.
#' }
#' The function returns a filtered character vector of file paths likely to be valid text files.
#'
#' @inheritParams seek
#' @param n The number of bytes to read for binary detection in files with unknown extensions. Defaults to 1000.
#'
#' @returns A character vector of file paths identified as potential text files.
#' If no matching files are found, an informative error is thrown.
#'
#' @keywords internal
filter_files = function(files, filter, negate, n = 1000L) {
  if (print_cli()) cli::cli_progress_step("Filter files")
  N = length(files)

  if (!is.null(filter)) {
    files = files[stringr::str_detect(files, filter, negate)]
  }

  files = files[!is_in_gitfolder(files)]
  files = files[!has_known_nontext_extension(files)]
  is_text = has_known_text_extension(files)

  for (i in seq_along(files)) {
    if (!is_text[[i]]) {
      is_text[[i]] = !has_null_bytes(files[[i]], n)
    }
  }

  files = files[is_text]

  if (length(files) == 0L) {
    cli::cli_abort(c(
      "!" = "No readable text files could be found among the files."
    ))
  }

  return(files)
}


#' @title Check if Files Are Located in a `.git` Folder
#'
#' @description
#' Identifies whether the provided file paths are located inside a `.git` directory.
#'
#' This function assumes that the file paths are normalized beforehand (i.e., using
#' forward slashes `/` even on Windows systems).
#'
#' @inheritParams filter_files
#'
#' @returns A logical vector indicating whether each file is located within a `.git` folder.
#'
#' @keywords internal
is_in_gitfolder = function(files) {
  stringr::str_detect(files, "/\\.git/")
}


#' @title Identify Files with Known Non-Text Extensions
#'
#' @description
#' Checks whether the provided file paths have extensions typically associated
#' with binary or non-text formats (e.g., images, archives, executables).
#'
#' @inheritParams filter_files
#'
#' @returns A logical vector indicating whether each file has a known non-text extension.
#'
#' @keywords internal
has_known_nontext_extension = function(files) {
  nontext_extensions = c(
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", # Images
    ".wav", ".mp3", ".mp4", ".mkv", # Audio
    ".exe", ".dll", ".lib", ".pyd", ".lnk", ".tmp", ".chm", # Binaries & system
    ".xlsx", ".xlsm", ".xlsb", ".xls", ".docx", ".pptx", # Office
    ".rds", ".rdata", ".rda", ".rdb", ".rdx", # R data formats
    ".parquet", ".npy", ".npz", ".pkl", ".mo", ".mod", # Data storage
    ".pdf", ".msg", ".tv.msg", # Documents/email
    ".zip", ".rar", ".gz", ".tar.gz", ".xml.gz", ".xml.bz2", # Archives
    ".woff", ".woff2", ".eot", ".ttf", # Fonts
    ".db", ".kdbx", # Databases
    ".json.enc", # Encrypted
    ".frx", ".rwz" # Misc/unknown
  )

  extract_lower_file_extension(files) %in% nontext_extensions
}


#' @title Identify Files with Known Text Extensions
#'
#' @description
#' Checks whether the provided file paths have extensions commonly associated
#' with text-based formats (e.g., scripts, markdown, configuration files).
#'
#' @inheritParams filter_files
#'
#' @returns A logical vector indicating whether each file has a known text extension.
#'
#' @keywords internal
has_known_text_extension = function(files) {
  text_extensions = c(
    ".r", ".rmd", ".rnw", ".rd", ".rproj", ".qmd", ".rhistory", ".rprofile", ".rout", # R ecosystem
    ".py", ".ipynb", # Python
    ".md", ".markdown", ".txt", ".rst", ".asciidoc", ".adoc", # Markdown / markup / plain text
    ".csv", ".tsv", ".psv", ".json", ".xml", ".yaml", ".yml", ".ndjson", ".ini", ".toml", # Data files
    ".log", ".conf", ".cfg", ".env", ".properties", ".sample", ".pem", ".crt", ".key", ".license", ".readme", ".todo", # Logs and configs
    ".sh", ".bash", ".zsh", ".csh", ".tcsh", ".fish", ".bat", ".cmd", ".ps1", # Shell & scripting
    ".html", ".htm", ".css", ".scss", ".sass", ".less", ".js", ".jsx", ".ts", ".tsx", ".vue", ".jsonld", ".map", # Web technologies
    ".tex", ".bib", ".sty", ".cls", ".nfo", # LaTeX and documentation
    ".dockerfile", ".editorconfig", ".gitattributes", ".gitignore", ".gitmodules", ".npmrc", ".babelrc", ".eslintrc", # General config / dotfiles
    ".make", ".mk", ".ninja", ".gradle", ".bazel", ".build", ".cmake", ".msbuild", # Makefiles & build systems
    ".c", ".cpp", ".cxx", ".cc", ".h", ".hh", ".hpp", ".hxx", ".ino", # Arduino # C-family
    ".cs", ".csx", # C#
    ".fs", ".fsi", ".fsx", # F#
    ".rs", ".rlib", # Rust
    ".go", # Go
    ".zig", # Zig
    ".jl", # Julia
    ".swift", # Swift
    ".kt", ".kts", # Kotlin
    ".java", ".jsp", # Java
    ".scala", ".sc", # Scala
    ".hs", ".lhs", # Haskell
    ".ml", ".mli", # OCaml
    ".lisp", ".cl", ".el", ".emacs", ".scm", ".rkt", ".ss", ".lsp", # Lisp family
    ".erl", ".hrl", ".ex", ".exs", # Erlang & Elixir
    ".dart", # Dart / Flutter
    ".php", ".php4", ".php5", ".phtml", # PHP
    ".rb", ".erb", ".rake", ".gemspec", # Ruby
    ".pl", ".pm", ".pod", ".t", # Perl
    ".tcl", # Tcl / Tk
    ".vb", ".vbs", # Visual Basic
    ".sql", ".psql", # SQL
    ".asm", ".s", ".S", # Assembly
    ".jsonc", ".cfg", ".txt", ".md", ".list", ".note" # Miscellaneous
  )

  extract_lower_file_extension(files) %in% text_extensions
}


#' @title Detect Null Bytes in a File
#'
#' @description
#' Reads the first `n` bytes of a file and checks whether any null bytes (`0x00`)
#' are present, which is commonly used to detect binary files.
#'
#' If the file cannot be read (e.g., corrupted or permission issues), the function
#' safely assumes the file is binary and returns `TRUE`.
#'
#' @param file A character string representing a single file path.
#' @inheritParams filter_files
#'
#' @returns `TRUE` if a null byte is found or if an error occurs. `FALSE` otherwise.
#'
#' @keywords internal
has_null_bytes = function(file, n = 1000L) {
  tryCatch(
    expr = {
      any(readBin(file, n = n, what = "raw") == as.raw(0))
    },
    error = function(e) {
      TRUE
    },
    warning = function(w) {
      TRUE
    }
  )
}
