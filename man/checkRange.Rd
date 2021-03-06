% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities-data-validation.R,
%   R/utilities-input-validation.R
\name{checkRange}
\alias{checkRange}
\title{Range Parameter Check}
\usage{
checkRange(rng, varType, formatType, expectedLength = NULL,
  emptyOkay = FALSE)

checkRange(rng, varType, formatType, expectedLength = NULL,
  emptyOkay = FALSE)
}
\arguments{
\item{rng}{A numeric vector of length two, that ought to be an
ordered pair.}

\item{varType}{The variable type; e.g. 'logical', 'integer', 'numeric'.}

\item{formatType}{One of 'vector' or 'list', describing which of the two the input range should be, where 'vector' returns to an atomic vector.
Since matrices are coerced to lists within the function, when using a matrix as range input, `format type = 'list'` should be specified.}

\item{expectedLength}{Integer value. Specifies how long the output ought to be. Defaults to NULL and only used on list or matrix inputs.}

\item{emptyOkay}{Boolean. TRUE if a null or NA range is allowed. Defaults to FALSE.}

\item{rng}{Range. A numeric vector of one of two formats:
1. A vector of length two, that ought to be an atomic ordered pair, representing 
the maximum and minimum bounds on the data.
2. A sequence of ordered pairs as a matrix or as a list, where each row represents
 the maximum and minimum bounds on some subsets of the data (e.g. of different data columns)
 Matrix and list types are supported. Internally, matrices are coerced to lists to allow 
 varying dimensions across rows.}
}
\value{
An ordered pair.

An ordered pair, a list of ordered pairs, or NULL.

Note that you can input a single ordered pair as a first element of a list, e.g. \code{rng = list(c(1,2))},
but performance will be slightly worse.
}
\description{
Checks if a supplied range is an ordered pair. Coerces any vector of length
   two or greater into an ordered pair, and issues an error for
   shorter vectors.

Checks if a supplied range(s) is(are) an ordered pair(s).
}
\details{
If emptyOkay, no error will be raised if the input range(s) is(are) null or NA. Ranges that
were input as NULL will be output as NULL.

In order to handle potential of some rows with different lengths when some rows contain NULL
or NA values, a rng input of
}
\examples{

checkRange(c(1,3))
checkRange(1:3)
\dontrun{checkRange(1)}

checkRange(c(1,3))
checkRange(1:3)s
\dontrun{checkRange(1)}
}
