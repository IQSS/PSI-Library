% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities-data-validation.R
\name{censorData1D}
\alias{censorData1D}
\title{Helper function to censor data}
\usage{
censorData1D(x, rng)
}
\arguments{
\item{x}{Numeric vector of length n}

\item{rng}{Range of values allowed in x, as a single (min, max) tuple}
}
\value{
numeric vector of length n equal to x except with any values in x larger than max replaced with max
 and any values in x smaller than min replaced with min.
}
\description{
Takes as input a numeric vector x of length n and replaces any values in x greater than max with max,
and any values less than min with min
}
\examples{
censorData1D(1:7, (2,5))    #returns c(2,2,3,4,5,5,5)
censorData1D(c(1,9,7,3,0), (2,5))     #returns(c(2,5,5,3,2))

}
