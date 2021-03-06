% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities-noise-generation.R
\name{rLap}
\alias{rLap}
\title{Random draw from Laplace distribution}
\usage{
rLap(mu = 0, b = 1, size = 1)
}
\arguments{
\item{mu}{numeric, center of the distribution}

\item{b}{numeric, spread}

\item{size}{integer, number of draws}
}
\value{
Random draws from Laplace distribution
}
\description{
Random draw from Laplace distribution
}
\examples{

rLap(size=1000)
}
