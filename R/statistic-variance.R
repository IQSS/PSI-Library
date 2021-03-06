#' Sensitivity of sample variance
#'
#' For a detailed derivation of the sensitivity, see /extra_docs/variance_sensitivity.pdf.
#' @name varianceSensitivity
#' @param n Numeric vector of length one; the number of datapoints in the database.
#' @param rng Numeric vector of length two; first entry is minimal bound on the database entries, second is maximal bound on the database entries.
#' @return Numeric vector of length one; a maximal bound on the sensitivity of the sample variance.
#'
#' @examples
#' varianceSensitivity(2,c(0,10)) #should return 50
varianceSensitivity <- function(n, rng){
  return(diff(rng)^2/n)
}

#' Postprocessed standard deviation from variance
#'
#' Function to extract standard deviation from noisy estimate of variance.
#' @name postStandDev
#' @param release Differentially private release of variance.
#'
#' @return Noisy estimate of the standard deviation of \code{release}, if possible to compute. Else returns NULL.
#' @rdname postStandDev

postStandDev <- function(release) {
  if (release >= 0){
    std <- sqrt(release)
    return(std)
  }
  else {
    return(NULL)
  }
}


#' Differentially private variance
#'
#' @param mechanism Character, the privacy mechanism. For \code{dpMean}, one
#'   of \code{c('mechanismLaplace')}.
#' @param varType Character, the R variable type. One of \code{c('numeric',
#'   'integer', 'logical')}.
#' @param variable Character, variable name of the variable that you wish to find variance of.
#' @param n Integer, number of observations
#' @param rng Numeric, a priori estimate of the range
#' @param epsilon Numeric, privacy cost parameter
#' @param accuracy Numeric, accuracy guarantee given \code{epsilon}
#' @param imputeRng Numeric, range within which missing values are imputed. If \code{NULL},
#'   the range provided in \code{rng} is used.
#' @param alpha Numeric, the level of statistical significance. Default 0.05.
#'
#' @import methods
#' @export dpVariance
#' @exportClass dpVariance
#'
#' @include mechanism.R
#' @include mechanism-laplace.R

dpVariance <- setRefClass(
    Class = 'dpVariance',
    contains = c('mechanismLaplace')
)

dpVariance$methods(

    initialize = function(mechanism, varType, variable, n, rng=NULL, epsilon=NULL,
                          accuracy=NULL, imputeRng=NULL, alpha=0.05) {
        .self$name <- 'Differentially private variance'
        .self$mechanism <- checkMechanism(mechanism, c('mechanismLaplace'))
        .self$varType <- checkVariableType(varType, c('integer', 'double', 'numeric', 'logical'))
        .self$variable <- variable

        .self$n <- checkNValidity(n)

        .self$rngFormat <- 'vector'
        .self$rng <- checkRange(rng, .self$varType, .self$rngFormat)

        .self$sens <- varianceSensitivity(.self$n, .self$rng)
        checkVariableType(typeof(variable), 'character')

        if (is.null(epsilon)) {
            .self$accuracy <- checkAccuracy(accuracy)
            .self$epsilon <- laplaceGetEpsilon(.self$sens, .self$accuracy, alpha)
        } else {
            checkEpsilon(epsilon)
            .self$epsilon <- checkEpsilon(epsilon)
            .self$accuracy <- laplaceGetAccuracy(.self$sens, .self$epsilon, alpha)
        }

        if (is.null(imputeRng)) {
            .self$imputeRng <- rng
        } else {
            .self$imputeRng <- checkImputationRange(imputeRng, .self$rng, .self$varType)
        }

        .self$alpha <- checkNumeric(alpha)
})

dpVariance$methods(
#' Differentially private variance release
#'
#' @name dpVarianceRelease
#' @param data Dataframe with a column named .self$variable, where
#'  that column has data of type .self$varType and which is bounded by
#'  .self$rng.
#'
#' Assigns to .self$result a dataframe that describes the differentially private
#' variance, calculated by some mechanism as defined in .self$mechanism, of that
#' column of the dataframe and any post-processing on that output. This
#' postprocessing is done in @seealso{dpVariance$postProcess}
#'
#' Note that the actual differentially private release is calculated in a call to the
#' differentially private mechanism .self$mechanism's \code{evaluate} function within
#' the \code{dpVariance$release} function.
    release = function(data) {
        x <- data[, variable]
        out <- export(mechanism)$evaluate(var, x, sens)
        .self$result <- .self$postProcess(out)
})

dpVariance$methods(
#' Post-processing on differentially private variance, called within the \code{.self$mechanism$evaluate}
#' function, which in turn is called within \code{dpVariance$release}.
#'
#' @name dpVariancePostProcess
#' @param out Input dataframe that describes the differentially private release that was created in
#' \code{.self$mechanism$evaluate}. This dataframe will have at least one pre-existing attribute,
#' out$release, which is a numeric value of length one that is the differentially private variance.
#'
#' This function then post-processes the standard deviation from the variance and adds it to the dataframe
#' as \code{out$std}, as long as the variance is positive.
#'
#' Additionally, known portions of the input such as the variable name and the accuracy
#' of the DP variance and the epsilon value may be appended with no extra privacy loss.
#'
#' @return Dataframe \code{out}, updated to include post-processed values.
    postProcess = function(out) {
        if (.self$mechanism == 'mechanismLaplace'){
            out$accuracy <- accuracy
            out$epsilon <- epsilon
        }
        out$variable <- variable
        out$std <- sqrt(out$release)
        out$epsilon <- .self$epsilon
        out$accuracy <- .self$accuracy
        return(out)
})
