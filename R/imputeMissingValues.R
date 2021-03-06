#' Find the position of missing values in a traces object
#' @description Replaces 0 values in a traces object with \code{NA} according to
#' a specified rule. NA values can then be imputed.
#' @param traces Object of class traces.
#' @param bound_left Numeric integer, the minimum number of non-zero values to the
#' left of a missing value to be replaced with \code{NA}.
#' @param bound_right Numeric integer, the minimum number of non-zero values to the
#' right of a missing value to be replaced with \code{NA}.
#' @param consider_borders Logical, whether to find missin values in the first/last fractions
#' (e.g. \code{0-1-1 -> NA-1-1} and \code{1-0-1-1 -> 1-NA-1-1} if the leftmost value is the
#' first fraction of the traces object).
#' @details The algorithm identifies 0 values on the dataset as missing values if they fulfill
#' the rule: \code{(1)*bound_left - 0 - (1)*bound_right} i.e. a zero value has to have at least
#' a specified number of non-zero neighbors to be classified as \code{NA}.
#' @return Object of class traces. Missing values are replaced with \code{NA}.
#' @family imputation functions
#' @export
#' @examples
#' tracesMiss <- findMissingValues(examplePeptideTraces)
#' View(tracesMiss$traces)

findMissingValues <- function(traces,
                              bound_left = 2,
                              bound_right = 2,
                              consider_borders = TRUE){
  UseMethod("findMissingValues", traces)
}

#' @describeIn findMissingValues Find missing values one traces object
#' @export

findMissingValues <- function(traces,
                              bound_left = 2,
                              bound_right = 2,
                              consider_borders = TRUE){
  .tracesTest(traces)
  intMat <- getIntensityMatrix(traces)

  #Pad matrix for border neighbors
  padVal <- ifelse(consider_borders, NA, 0)
  padLeft <- matrix(padVal, nrow= nrow(intMat), ncol = bound_right)
  padRight <- matrix(padVal, nrow= nrow(intMat), ncol = bound_left)
  intMatPad <- cbind(padLeft, intMat, padLeft)
  # Find missing values
  zeroes <- which(intMatPad == 0, arr.ind = T)
  zeroes <- zeroes[(zeroes[,2] > bound_left) & (zeroes[,2] <= (ncol(intMatPad) - bound_right)),]
  zeroMat <- matrix(0, nrow=nrow(intMat), ncol = ncol(intMat)+bound_left+bound_right)
  neighbors <- c(-bound_left:-1, 1:bound_right)
  z <- zeroes
  for(i in neighbors){
    z[,2] <- zeroes[,2] + i
    zeroMat[z] <- zeroMat[z] +1
  }

  intMatPad[,c(1:bound_left, (ncol(intMatPad)-bound_right+1):ncol(intMatPad))] <- 999
  missingVals <- which(intMatPad == 0 & zeroMat == 0, arr.ind = T)
  missingVals[,2] <- missingVals[,2] - bound_left
  traces$traces[missingVals] <- NA
  .tracesTest(traces)
  return(traces)
}

#' Impute NA values in a traces object
#' @description Imputes all NA values in a traces object by interpolation.
#' @param traces Object of class traces.
#' @param method Character string, which interpolation method to use.
#' @details Unlike with standard imputation methods, missing values on the borders
#' are linearly extrapolated from the neighboring 2 values. Any imputed value below 0
#' is set to 0.
#' @return Object of class traces with imputed NA values.
#' @export
#' @examples
#' tracesMiss <- findMissingValues(examplePeptideTraces)
#' tracesImp <- imputeMissingVals(tracesMiss)
#' View(tracesImp$traces)
#'
#' # The imputed values can be visualised using the package 'daff'
#' require(daff)
#' render_diff(diff_data(examplePeptideTraces$traces, tracesImp$traces))
#'

imputeMissingVals <- function(traces, method = c("mean", "spline")){
  .tracesTest(traces)
  traces_res <- copy(traces)
  method <- match.arg(method)
  intMat <- getIntensityMatrix(traces)
  naIndx <- which(is.na(intMat), arr.ind = T)
  intMatImp <- apply(intMat, 1, function(tr){
    naIdx <- is.na(tr)
    n <- length(tr)

    if (!any(naIdx)) {
      return(tr)
    }

    allindx <- 1:n
    indx <- allindx[!naIdx]
    if (method == "mean") {
      interp <- approx(indx, tr[indx], 1:n)$y
    }
    else if (method == "spline") {
      interp <- spline(indx, tr[indx], n = n)$y
    }
    # Calculate border fractions (linear interpolation of 2 adjacent fractions)
    if(naIdx[1]){
      interp[1] <- 2 * interp[2] -interp[3]
    }
    if(naIdx[n]){
      interp[n] <- 2 * interp[n-1] -interp[n-2]
    }

    return(interp)
  })
  intMatImp <- t(intMatImp)
  intMatImp[intMatImp < 0] <- 0
  traces_res$traces[naIndx] <- round(intMatImp[naIndx],digits=2)
  .tracesTest(traces_res)
  return(traces_res)
}


#' Plot a summary of the trace imputation
#' @description Plot the distribution of missing values per trace as well as
#' missing values per fraction and some imputed traces.
#' @param traces Object of class traces with missing values indicated by \code{NA}.
#' @param tracesImp Object of class traces with imputed missing values.
#' @param PDF Logical, whether to plot to PDF. PDF file is saved in working directory.
#' Default is \code{FALSE}.
#' @param plot_traces Logical, whether to plot some traces, visualizing the imputed values.
#' Default is \code{TRUE}.
#' @param max_n_traces Numeric integer, how many traces to plot. Default is 30.
#' @param name Character string with name of the plot, only used if \code{PDF=TRUE}.
#' Default is "Missing_value_imputation_summary.pdf".
#' @return Summary plots of the missing value imputation.
#' @export
#' @examples
#' tracesMiss <- findMissingValues(examplePeptideTraces)
#' tracesImp <- imputeMissingVals(tracesMiss)
#' View(tracesImp$traces)
#'
#' plotImputationSummary(tracesMiss, tracesImp, PDF = FALSE)

plotImputationSummary <- function(traces,
                                  tracesImp,
                                  PDF = FALSE,
                                  plot_traces = TRUE,
                                  max_n_traces = 30,
                                  name = "Missing_value_imputation_summary.pdf"){
  ids <- intersect(traces$traces$id, tracesImp$traces$id)
  traces <- subset(traces,trace_subset_ids = ids)
  tracesImp <- subset(tracesImp,trace_subset_ids = ids)

  intMat <- getIntensityMatrix(traces)
  intMatImp <- getIntensityMatrix(tracesImp)


  if(PDF){pdf(gsub("\\.pdf|$", ".pdf", name), width=8, height = 5)}

  ## NA distribution
  #per trace
  nas <- apply(intMat, 1, function(x) length(which(is.na(x))))

  p <- ggplot(data.table(NAs_per_trace = nas)) +
    geom_histogram(aes(x = NAs_per_trace), binwidth = 1) +
    scale_y_log10() +
    xlab("Missing values per trace") +
    ggtitle("Missing Values per trace") +
    theme_bw()
  plot(p)
  #per fraction
  nas <- apply(intMat, 2, function(x) length(which(is.na(x))))

  p <- ggplot(data.table(Fraction = 1:length(nas), NAs = nas)) +
    geom_bar(aes(x = Fraction, y = NAs),stat = "identity") +
    ylab("Missing values") +
    ggtitle("Missing Values per fraction") +
    theme_bw()
  plot(p)
  ## Traces
  naTraces <- is.na(intMat)
  naIds <- rownames(naTraces)[apply(naTraces, 1, any)]
  naTracesLong <- melt(naTraces)
  names(naTracesLong) <- c("id", "Fraction", "MissingVal")
  plot_df <- melt(intMatImp)
  plot_df <- cbind(plot_df, naTracesLong$MissingVal)
  names(plot_df) <- c("id", "Fraction", "Intensity", "MissingVal")
  # plot_df <- plot_df[id %in% naIds]

  if(max_n_traces > 0){
    max_n_traces <- min(max_n_traces, length(naIds))
    for(id in naIds[1:max_n_traces]){
      p_df <- plot_df[plot_df$id == id,]
      plot_dfNoNa <- p_df[!p_df$MissingVal,]
      p <- ggplot(p_df, aes(x = Fraction, y = Intensity)) +
        geom_line() +
        geom_point(color = "red") +
        geom_point(data = plot_dfNoNa) +
        theme_bw() +
        ggtitle(id)
      plot(p)
    }
  }
  if(PDF){dev.off()}
}

#' Plot a summary of the trace imputation
#' @description Plot the distribution of missing values per trace as well as
#' missing values per fraction and some imputed traces.
#' @param traces Object of class traces with missing values indicated by \code{NA}.
#' @param tracesImp Object of class traces with imputed missing values.
#' @param PDF Logical, whether to plot to PDF. PDF file is saved in working directory.
#' Default is \code{TRUE}.
#' @param plot_traces Logical, whether to plot some traces, visualizing the imputed values.
#' Default is \code{TRUE}.
#' @param max_n_traces Numeric integer, how many traces to plot. Default is 30.
#' @param name Character string with name of the plot, only used if \code{PDF=TRUE}.
#' Default is "Missing_value_imputation_summary.pdf".
#' @return Summary plots of the missing value imputation.
#' @export
#' @examples
#' tracesMiss <- findMissingValues(examplePeptideTraces)
#' tracesImp <- imputeMissingVals(tracesMiss)
#' View(tracesImp$traces)
#'
#' plotImputationSummary(tracesMiss, tracesImp, PDF = FALSE)

imputeTraces <- function(traces,
                         bound_left = 2,
                         bound_right = 2,
                         consider_borders = TRUE,
                         method = c("mean", "spline"),
                         plot_summary = TRUE,
                         plot_traces = TRUE,
                         max_n_traces = 30){

  # Convert 0's in missing value locations to NA
  pepTracesMV <- findMissingValues(traces,
                                   bound_left = bound_left,
                                   bound_right = bound_right,
                                   consider_borders = consider_borders)
  # Impute NA values
  pepTracesImp <- imputeMissingVals(pepTracesMV, method = method)

  # Plot summary
  if(plot_summary){
    plotImputationSummary(pepTracesMV, pepTracesImp,
                          PDF = TRUE,
                          plot_traces = plot_traces,
                          max_n_traces = max_n_traces,
                          name = "Missing_value_imputation_summary.pdf")
  }
  return(pepTracesImp)
}
