% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/list-files.R
\name{filter_matching_files}
\alias{filter_matching_files}
\title{Filter Files by Name Pattern}
\usage{
filter_matching_files(files, filter)
}
\arguments{
\item{files}{A character vector of file paths to filter.}

\item{filter}{A Perl-compatible regular expression applied to the file paths.}
}
\value{
A character vector of file paths that match the pattern.
}
\description{
Filters a character vector of file paths using a Perl-compatible regular expression.
If no files match, an informative error message is displayed.
}
\keyword{internal}
