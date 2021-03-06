% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities-objective.R
\name{scaleRelease}
\alias{scaleRelease}
\title{Scale coefficient estimates}
\usage{
scaleRelease(estimates, xScaler, yScaler = NULL)
}
\arguments{
\item{estimates}{Numeric, coefficient estimates vector.}

\item{xScaler}{Numeric, maximum norm from \code{mapMatrixUnit} fit on features.}

\item{yScaler}{Numeric, maximum norm from \code{mapMatrixUnit} fit on response,
default NULL.}
}
\value{
Transformed coefficients vector
}
\description{
This function puts coefficient estimates on the scale of the original features
}
