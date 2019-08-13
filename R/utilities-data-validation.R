#' Error check imputation range for numeric or integer variables
#' 
#' Check that the entered imputation range is within the entered data range. If yes, return
#' the entered imputation range, which will be used as the imputation range for the call
#' to the utility function `fillMissing()`. If not, return the data range. 
#' If the imputation range is NULL, default to the data range.
#' 
#' We check if the imputation range is within the data range because it is a privacy concern.
#' If the imputation range is outside of the data range, NA values will be replaced with values 
#' outside of the data range, which will show that there are NA values in the data or skew the 
#' result when the differentially private estimate is released.
#' 
#' @param imputationRange The imputation range entered by the user
#' @param rng The data range entered by the user
#' @param varType The variable type for the histogram data
#' 
#' @return the imputation range that will be used for `fillMissing()`.

checkImputationRange <- function(imputationRange, rng, varType) {
    # if no imputation range was entered, return the data range.
    # (Note: rng may be NULL, in which case stability mechanism will be used)
    if (is.null(imputationRange)) {
        return(rng)
    }
    
    # for numeric and integer variables, the imputation range should be a 2-tuple
    # with the minimum and maximum of the imputation range.
    # if an imputation range was entered, check that it is
    # within the data range. If it is not, clip it to be within the data range
    if (varType %in% c('numeric', 'integer')) {
        lowerBound <- NULL
        upperBound <- NULL
        
        # if the imputation range lower bound is below the data range lower bound,
        # clip the lower bound to the data range
        if (imputationRange[1] < rng[1]) {
            warning('Lower bound of imputation range is outside of the data range. Setting lower bound of the imputation range to the lower bound of the data range.')
            lowerBound <- rng[1]
        } else {
            lowerBound <- imputationRange[1]
        }
        
        # if the imputation range upper bound is above the data range upper bound,
        # clip the upper bound to the data range
        if (imputationRange[2] > rng[2]) {
            warning('Upper bound of imputation range is outside of the data range. Setting upper bound of the imputation range to the upper bound of the data range.')
            upperBound <- rng[2]
        } else {
            upperBound <- imputationRange[2]
        }
        
        for (entry in imputationRange) {
            if (!is.numeric(entry)) {
                warning('Imputation range for a numeric variable must be numeric. Setting imputation range to data range.')
                lowerBound <- rng[1]
                upperBound <- rng[2]
            }
        }
        
        # return the (potentially clipped) imputation range
        return(c(lowerBound,upperBound))
        
    } else {
        # if the variable type is something other than numeric or integer,
        # default to the data range
        warning('Imputation range entered for variable that is not of numeric or integer type. Setting imputation range to data range.')
        return(rng)
    }
}


#' Check validity of n
#' 
#' n should always be a positive whole number, check the user's input
#' 
#' @param n the input n from te user
#' 
#' @return n, if n is a positive whole number

checkNValidity <- function(n) {
    if ((n > 0) & (n%%1 == 0)) {
        return(n)
    } else {
        stop("n must be a positive whole number")
    }
}


#' Range Parameter Check
#' 
#' Checks if a supplied range is an ordered pair. Coerces any vector of length 
#'    two or greater into an ordered pair, and issues an error for
#'    shorter vectors.
#'    
#' @param rng A numeric vector of length two, that ought to be an 
#'    ordered pair.
#' 
#' @return An ordered pair.
#' @examples
#'
#' checkRange(c(1,3))
#' checkRange(1:3)
#' \dontrun{checkRange(1)}
#' @rdname checkRange
#' @export
checkRange <- function(rng, varType) {
    if (NCOL(rng) > 1) {
        for (i in 1:nrow(rng)) {
            rng[i, ] <- sort(rng[i, ])
        }
    } else {
        if (varType == 'logical') {
            rng <- c(0,1)
        } else if (length(rng) < 2) {
            stop("range argument in error: requires upper and lower values as vector of length 2.")
        } else if (length(rng) > 2) {
            warning("range argument supplied has more than two values.  Will proceed using min and max values as range.")
            rng <- c(min(rng), max(rng))
        } else {
            rng <- sort(rng)
        }
    }
    return(rng)
}


#' Epsilon Parameter Check
#' 
#' Utility function for checking that epsilon is acceptably defined.
#'
#' @param epsilon A vector, that ought to be positive and of length one.
#' 
#' @return The supplied epsilon if acceptable, otherwise an error 
#'    message interupts.
#'
#' @examples
#' 
#' checkEpsilon(0.1)
#' \dontrun{checkEpsilon(-2)}
#' \dontrun{checkEpsilon(c(0.1,0.5))}
#' @rdname checkEpsilon
#' @export
checkEpsilon <- function(epsilon) {
    if (epsilon <= 0) {
        stop("Privacy parameter epsilon must be a value greater than zero.")
    }
    if (length(epsilon) > 1) {
        stop(paste("Privacy parameter epsilon must be a single value, but is currently a vector of length", length(epsilon)))
    }
    return(epsilon)
}


#' Censoring data
#' 
#' For numeric types, checks if x is in rng = (min, max) and censors values to 
#'    either min or max if it is out of the range. For categorical types, 
#'    values not in `levels` are coded NA.
#'
#' @param x A vector of numeric or categorial values to censor.
#' @param varType Character indicating the variable type of \code{x}.
#'    Possible values include: numeric, logical, ...
#' @param rng For numeric vectors, a vector (min, max) of the bounds of the 
#'    range. For numeric matrices with nrow N and ncol P, a Px2 matrix of 
#'    (min, max) bounds.
#' @param levels For categorical types, a vector containing the levels to 
#'    be returned.
#' 
#' @return Original vector with values outside the bounds censored to the bounds.
#' @examples
#' 
#' censorData(x=1:10, varType='integer', rng=c(2.5, 7))
#' censorData(x=c('a', 'b', 'c', 'd'), varType='character', levels=c('a', 'b', 'c'))
#' @rdname censorData
#' @export
censorData <- function(x, varType, rng=NULL, levels=NULL) {
    if (varType %in% c('character', 'factor')) {
        if (is.null(levels)) {
            x <- factor(x, exclude=NULL)
        } else {
            x <- factor(x, levels=levels, exclude=NULL)
        }
    } else {
        if (is.null(rng)) {
            stop('range `rng` is required for numeric types')
        }
        if (NCOL(x) > 1) {
            for (j in 1:ncol(x)) {
                rng[j, ] <- checkRange(rng[j, ], varType)
                x[, j][x[, j] < rng[j, 1]] <- rng[j, 1]
                x[, j][x[, j] > rng[j, 2]] <- rng[j, 2]
            }
        } else {
            rng <- checkRange(rng, varType)
            x[x < rng[1]] <- rng[1]
            x[x > rng[2]] <- rng[2]
        }
    }
    return(x)
}


#' Checking variable types
#' 
#' Verifies that the variable is an element in the set of acceptable types.
#' 
#' @param type A character specifying the type of the variable.
#' @param inTypes A vector of acceptable types of variables.
#' 
#' @return The original character string indicating the variable type.
#' @examples 
#' 
#' checkVariableType(type='Numeric', inTypes=c('Numeric', 'Factor'))
#' @rdname checkVariableType
#' @export
checkVariableType <- function(type, inTypes) { 
    if (!(type %in% inTypes)) {
        stop(paste('Variable type', type, 'should be one of', paste(inTypes, collapse = ', ')))
    } 
    return(type)
}


#' Logical variable check
#' 
#' Utility function to verify that a variable is dichotomous.
#'
#' This function effectively allows the user to ask for any variable containing
#' at most two unique values to treat the variable as logical. If the variable
#' contains numeric values, the highest value is recoded 1 and the the lower
#' value is recoded 0. If the variable is categorical and contains only two unique
#' values, the least frequently observed is recoded 1.
#'
#' @param x Vector containing two unique types of values.
#' 
#' @return Logical form of \code{x} coded 0-1.
#' @examples
#' 
#' makeLogical(sample(c('cat', 'dog'), size=8, replace=TRUE))
#' makeLogical(sample(c(0, 1), size=8, replace=TRUE))
#' makeLogical(sample(c(-6.87, 3.23), size=8, replace=TRUE))
#' @rdname makeLogical
#' @export
makeLogical <- function(x) {
    if (!length(unique(x)) <= 2) { # how to handle if contains 1 value only?
        stop('Variable has more than two values')
    }
    if (class(x) %in% c('character', 'factor')) {
        tab <- data.frame(table(x))
        min_level <- tab[which.min(tab[, 2]), 1]
        x <- ifelse(x == min_level, 1, 0)
    } else {
        x <- ifelse(x == max(x), 1, 0)
    }
    return(x)
}


#' Scaling helper function for fillMissing
#' 
#' Takes input array and scales to upper and lower bounds, which are either defined by lower and upper or calculated depending on
#' the type of variable. (Note that input array will always be numeric; varType refers to the variable type of the input array in
#' the fillMissing function.)
#' 
#' @param vals Input array of values to scale Type: numeric array
#' @param varType Variable type of input array to fillMissing function; affects how scaling occurs. 
#'   Type: one of following strings: 'character', 'factor', 'logical', 'integer', 'numeric'.
#' @param lower Lower bound for scaling. Type: numeric
#' @param upper Upper bound for scaling. Type: numeric
#' @param categories List of categories. Type: factor
#'
#' @return Array of values, either characters, integers, logicals, numerics depending on varType, scaled according to either the 
#' number of categories if varType='factor' or 'character', or based on lower and upper when varType='logical','numeric', or 'integer'.
#'
scaleValues = function(vals, varType, lower=NULL, upper=NULL, categories=NULL) {
    if (varType %in% c('character', 'factor')) { 
        lower <- 1
        upper <- length(categories)
    }
    
    if (varType == 'logical') {       # logical values can only be 0 or 1 so set bounds accordingly
        lower <- 0
        upper <- 2                       # upper bound of 2 not 1 because as.integer always rounds down.
    }
    
    out <- vals * (upper - lower) + lower  # scale uniform random numbers based on upper and lower bounds
    
    if (varType %in% c('logical', 'integer')) { # if logical or integer, trim output to integer values
        out <- as.integer(out)
    } else if(varType == 'logical') {
        
    } else if (varType %in% c('character', 'factor')) { # if character or factor, assign output to categories.
        out <- categories[as.integer(out)]
    }
    
    return(out)
}


#' Helper function for fillMissing; fills missing values in one-dimensional array
#'
#' Imputes uniformly in the range of the provided variable.
#'
#' @param x Input array of missing values.
#' @param varType Variable type of input array to fillMissing function; affects how scaling occurs. 
#'   Type: one of following strings: 'character', 'factor', 'logical', 'integer', 'numeric'.
#' @param lower Lower bound for scaling. Type: numeric. Default NULL.
#' @param upper Upper bound for scaling. Type: numeric. Default NULL.
#' @param categories List of categories. Type: factor. Default NULL.
#' @return Vector \code{x} with missing values imputed
fillMissing1D <- function(x, varType, lower=NULL, upper=NULL, categories=NULL) {
    naIndices <- is.na(x)         # indices of NA values in x
    nMissing <- sum(naIndices)    # number of missing values
    
    if (nMissing == 0) { 
        return(x) 
    }
    
    u <- dpUnif(nMissing) # array of uniform random numbers of length nMissing
    scaledVals <- scaleValues(u, varType, lower, upper, categories) # scale uniform vals
    x[naIndices] <- scaledVals #assign to NAs in input array
    return(x)
}


#' Helper function for fillMissing. Fills missing values column-wise for matrix.
#'
#' Impute uniformly in the range of the provided variable
#'
#' @param x Numeric matrix with missing values
#' @param varType Variable type of input array.
#'   Type: one of following strings: 'character', 'factor', 'logical', 'integer', 'numeric'.
#' @param imputeRng Px2 matrix where the pth row contains the range
#'      within which the pth variable in x is imputed.
#' @return Matrix \code{x} with missing values imputed
#'
#' @seealso \code{\link{fillMissing}}
fillMissing2D <- function(x, varType, imputeRng=NULL) {
    for (j in 1:ncol(x)) {
        x[, j] <- fillMissing1D(x[, j], varType, lower=imputeRng[j, 1], upper=imputeRng[j, 2])
    }
    return(x)
}


#' Fill missing values
#'
#' Impute uniformly in the range of the provided variable
#'
#' @param x Vector with missing values to impute
#' @param varType Character specifying the variable type
#' @param lower Numeric lower bound, default NULL
#' @param upper Numeric upper bound, default NULL
#' @param categories Set of possible categories from which to choose,
#'      default NULL
#' @return Vector \code{x} with missing values imputed
#' @examples
#'
#' # numeric example
#' y <- rnorm(100)
#' y[sample(1:100, size=10)] <- NA
#' y_imputed <- fillMissing(x=y, varType='numeric', lower=-1, upper=1)
#'
#' # categorical example
#' cats <- as.factor(c('dog', 'zebra', 'bird', 'hippo'))
#' s <- sample(cats, size=100, replace=TRUE)
#' s[sample(1:100, size=10)] <- NA
#' s_imputed <- fillMissing(x=s, varType='factor', categories=cats)
#'
#' @seealso \code{\link{dpUnif}}
#' @rdname fillMissing
#' @export
fillMissing = function(x, varType, imputeRng=NULL, categories=NULL) {
    if (varType %in% c('numeric', 'integer', 'logical')) {
        if (NCOL(x) > 1) {
            x <- fillMissing2D(x, varType, imputeRng)
        } else {
            x <- fillMissing1D(x, varType, imputeRng[1], imputeRng[2])
        }
    } else {
        x <- fillMissing1D(x, varType, categories=categories)
    }
    return(x)
}


#' Extract function arguments
#' 
#' Utility function to match arguments of a function with input list and/or attributes of input object
#'
#' @param targetFunc A character vector containing the name of the function to find the matching inputs of
#'    with arguments that need to be filled by output.
#' @param inputList A named list of values
#' @param inputObject An object with a predefined getFields() function that takes all attributes of object and returns them as a list
#' @return List of arguments and values needed for specification of \code{target.func}
#' @rdname getFuncArgs
getFuncArgs <- function(targetFunc, inputList=NULL, inputObject=NULL){
    funcArgs <- list()                      # Initialize list of function arguments
    argNames <- names(formals(targetFunc))  # Names of all arguments of targetFunc
    inputListNames <- names(inputList)      # Names of all items in inputList
    
    if (!is.null(inputObject)){             
        inputObjectNames <- names(inputObject$getFields()) # Names of all fields of inputObject
    }
    else{
        inputObjectNames <- NULL
    }
    
    for (argument in argNames) {
        # If argument of targetFunc has an associated named attribute in the input list, save that attribute to funcArgs
        if (argument %in% inputListNames) {
            funcArgs[[argument]] <- inputList[[argument]] 
        }
        # If argument of targetFunc has an associated field of inputObject, save that field value to funcArgs 
        if (argument %in% inputObjectNames) {          
            funcArgs[[argument]] <- inputObject[[argument]]
        }
    }
    return(funcArgs)
}