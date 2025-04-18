% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/list-files.R
\name{list_files}
\alias{list_files}
\title{List All Files in a Directory}
\usage{
list_files(path, recursive, all.files)
}
\arguments{
\item{path}{a character vector of full path names; the default
    corresponds to the working directory, \code{\link[base]{getwd}()}.  Tilde
    expansion (see \code{\link[base]{path.expand}}) is performed.  Missing
    values will be ignored.  Elements with a marked encoding will
    be converted to the native encoding (and if that fails, considered
    non-existent).}

\item{recursive}{logical.  Should the listing recurse into directories?}

\item{all.files}{a logical value.  If \code{FALSE}, only the
    names of visible files are returned (following Unix-style visibility,
    that is files whose name does not start with a dot).  If \code{TRUE},
    all file names will be returned.}
}
\value{
A character vector of normalized file paths.
}
\description{
Lists all files in a specified directory using \code{\link[base:list.files]{base::list.files()}}, with options
to include subdirectories and hidden files. If no files are found, provides
informative error messages.
}
\keyword{internal}
