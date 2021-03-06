% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities-categorical.R
\name{makeDummies}
\alias{makeDummies}
\title{Function to convert factor variables to binary indicators}
\usage{
makeDummies(df)
}
\arguments{
\item{df}{Data frame}
}
\value{
List with data frame with factor columns converted to dummy indicators and the names of
     the columns of the transformed data frame.

For each factor variable in the data frame, a binary indicator is generated for (k - 1) of its
k levels. The first level is dropped. The original factor variable is dropped. The names of the
binary indicators are the result of combining the name of the original factor variable and the
level represented by the indicator.
}
\description{
Function to convert factor variables to binary indicators
}
