% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read-files.R
\name{readLines_safe}
\alias{readLines_safe}
\title{Safe File Reading}
\usage{
readLines_safe(con, warn, n)
}
\arguments{
\item{con}{a \link[base]{connection} object or a character string.}

\item{warn}{logical.  Warn if a text file is missing a final \abbr{EOL} or if
    there are embedded \abbr{NUL}s in the file.}

\item{n}{integer.  The (maximal) number of lines to
    read.  Negative values indicate that one should read up to the end of
    input on the connection.}
}
\value{
A character vector of lines from the file, or \code{NULL} if reading fails.
}
\description{
Reads a file using \code{\link[base:readLines]{base::readLines()}} with error handling. If an error occurs
(e.g., file unreadable), returns \code{NULL} instead of stopping execution.
}
\keyword{internal}
