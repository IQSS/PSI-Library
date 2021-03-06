#' Differentially private histogram
#'
#' @param varType Character, the variable type.
#' @param variable Character, the variable name in the data frame.
#' @param n Integer, the number of observations.
#' @param epsilon Numeric, the privacy loss parameter.
#' @param accuracy Numeric, the desired accuracy of the query.
#' @param rng Numeric, a priori estimate of the lower and upper bounds of a
#'    variable taking numeric values. Ignored for categorical types.
#' @param bins Character, the available bins or levels of a categorical variable.
#' @param nBins Integer, the number of bins to release.
#' @param granularity Numeric, the width of each histogram bin (i.e. the inverse of `nBins`). Used 
#'    to calculate histogram bins in comination with `rng`.
#' @param alpha Numeric, level of statistical significance, default 0.05.
#' @param delta Numeric, probability of privacy loss beyond \code{epsilon}.
#' @param imputeRng Numeric, a 2-tuple indicating the lower and upper bounds of the range from which NA
#'    values in numeric or integer-type variables should be imputed 
#' @param imputeBins Character (or numeric for logical variables), a list of bins from which NA values
#'    values in character-type variables should be imputed
#' @param impute Boolean, a boolean value indicating if logical-type variables should have NA values
#'    imputed or not. If true, a logical variable histogram will have 2 bins, 0 and 1. If false, the
#'    histogram will have 3 bins: 0, 1, and NA.
#' @param nBoot Numeric, the number of bootstrap iterations to do for bootstrapping (not used for version 1 release)
#' @param mechanism Character, one of 'mechanismLaplace', 'mechanismStability'. May be NULL, in which mechanism will be chosen automatically.
#'
#' @import methods
#' @export dpHistogram
#' @exportClass dpHistogram
#'
#' @include mechanism.R
#' @include mechanism-laplace.R
#' @include mechanism-stability.R

dpHistogram <- setRefClass(
    Class = 'dpHistogram',
    contains = c('mechanismLaplace', 'mechanismStability')
)

dpHistogram$methods(
    initialize = function(varType, variable, n, epsilon=NULL, accuracy=NULL, rng=NULL, 
                          bins=NULL, nBins=NULL, granularity=NULL, alpha=0.05, delta=NULL,
                          imputeRng=NULL, imputeBins=NULL, impute=FALSE, nBoot=NULL, mechanism=NULL, ...) {
        .self$name <- 'Differentially private histogram'
        
        # determine  which mechanism to use based on inputs
        if (is.null(mechanism)){
          .self$mechanism <- determineMechanism(varType, rng, bins, nBins, granularity)
        }
        else {
          .self$mechanism <- checkMechanism(mechanism, c('mechanismLaplace', 'mechanismStability'))
        }
        
        # set parameters of the histogram
        .self$varType <- checkVariableType(varType, c('numeric', 'integer', 'logical', 'character'))
        .self$variable <- variable
        .self$n <- checkN(n)
        .self$bins <- bins # may be null
        .self$nBins <- checkHistogramNBins(nBins) # may be null
        .self$alpha <- checkNumeric(alpha, expectedLength=1)
        .self$imputeRng <- checkImputationRange(imputeRng, .self$rng, .self$varType)
        .self$impute <- impute
        .self$nBoot <- checkN(nBoot, emptyOkay=TRUE)
        .self$granularity <- checkNumeric(granularity, emptyOkay=TRUE) # may be null
        .self$bootFun <- bootHist
        .self$sens <- 2 # the sensitivity of a histogram is 2 because we are using the replacement definition of "neighboring database"
        .self$rngFormat <- 'vector' #if range is specified, should always be a vector of two values.
        
        checkVariableType(typeof(variable), 'character')
        checkVariableType(typeof(bins), c('character', 'integer', 'double', 'numeric', 'logical'), emptyOkay=TRUE)
        checkVariableType(typeof(impute), 'logical')
        
        # if the mechanism used is NOT the stability mechanism:
        # 1) determine the bins of the histogram. (If the mechanism is 
        #    the stability mechanism, then the bins will be determined in 
        #    the stability mechanism.)
        # 2) determine the number of bins from the input number of bins, the granularity, or the list of bins.
        if (.self$mechanism != 'mechanismStability') {
            .self$bins <- determineBins(.self$varType, rng, bins, .self$n, .self$nBins, impute, granularity, .self)
            .self$nBins <- setNumHistogramBins(.self$nBins, granularity, .self$varType, .self$bins)
        }
        
        # check the data range
        # if numeric bins have been entered, set the range to the range of the bins 
        # if logical variable is entered, set the range to c(0,1)
        # (may be NULL)
        .self$rng <- setHistogramRange(rng, .self$varType, bins)
        
        # get the epsilon and accuracy
        if (is.null(epsilon)) {
            .self$accuracy <- checkAccuracy(accuracy)
            .self$epsilon <- histogramGetEpsilon(.self$mechanism, accuracy, delta, alpha, .self$sens)
        } else {
            .self$epsilon <- checkEpsilon(epsilon)
            .self$accuracy <- histogramGetAccuracy(.self$mechanism, epsilon, delta, alpha, .self$sens)
        }
        
        # get the delta parameter (will be 0 unless stability mechanism is being used)
        .self$delta <- checkDelta(.self$mechanism, delta)
        
        # set the range for data imputation (will be null if no range entered)
        .self$imputeRng <- checkImputationRange(imputeRng, rng, varType)
        
        # set the bins for data imputation (will be null if no bins entered)
        .self$imputeBins <- checkImputationBins(imputeBins, bins, varType)
})

dpHistogram$methods(
    release = function(data) {
        x <- data[, variable]
        out <- export(.self$mechanism)$evaluate(funHist, x, .self$sens)
        .self$result <- .self$postProcess(out)
})

dpHistogram$methods(
    postProcess = function(out) {
        out$variable <- variable
        out$release <- normalizeReleaseAndConvertToDataFrame(out$release, n)
        out$accuracy <- .self$accuracy
        out$epsilon <- .self$epsilon
        out$delta <- .self$delta
        out$mechanism <- .self$mechanism
        if (.self$mechanism == 'mechanismStability') out$delta <- delta
        if (length(out$release) > 0) {
            if (.self$mechanism == 'mechanismLaplace') {
                out$intervals <- histogramGetCI(out$release, nBins, out$accuracy)
            }
        }
        if (varType %in% c('factor', 'character')) {
            out$herfindahl <- sum((out$release / n)^2)
        }
        if (varType %in% c('logical', 'factor')) {
            temp.release <- out$release[na.omit(names(out$release))]
            out$mean <- as.numeric(temp.release[2] / sum(temp.release))
            out$median <- ifelse(out$mean < 0.5, 0, 1)
            out$variance <- out$mean * (1 - out$mean)
            out$std.dev <- sqrt(out$variance)
        }
        return(out)
})
