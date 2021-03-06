% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/statistic-tree.R
\name{treePostPercentiles}
\alias{treePostPercentiles}
\title{Quantile function using the DP CDF}
\usage{
treePostPercentiles(cdf, percentiles)
}
\arguments{
\item{cdf}{Differentially private estimate of the empirical cumulative
distribution function}

\item{percentiles}{Vector of probabilities given to the quantile function}
}
\value{
Differnetially private estimate of the values corresponding to
     the provided probabilities
}
\description{
Quantile function using the DP CDF
}
