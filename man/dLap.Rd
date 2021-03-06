% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities-noise-generation.R
\name{dLap}
\alias{dLap}
\title{Probability density for Laplace distribution}
\usage{
dLap(x, mu = 0, b = 1)
}
\arguments{
\item{x}{numeric, value}

\item{mu}{numeric, center of the distribution}

\item{b}{numeric, spread}
}
\value{
Density for elements of x
}
\description{
Probability density for Laplace distribution
}
\examples{

x <- seq(-3, 3, length.out=61)
dLap(x)
}
