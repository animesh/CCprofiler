% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/annotateMassDistribution.R
\name{summarizeMassDistribution}
\alias{summarizeMassDistribution}
\title{summarizeMassDistribution}
\usage{
summarizeMassDistribution(traces, PDF = FALSE,
  name = "massDistribution_summary")
}
\arguments{
\item{traces}{An object of type traces.}

\item{PDF}{Logical, whether to generate a PDF file with the summary plot. Default is \code{FALSE}.}

\item{name}{Character string specifying the name of the PDF file of the summary plot.
Only applicable if PDF=\code{TRUE}. Default is "massDistribution_summary".}
}
\description{
Plots the fraction of assembled vs. monomeric mass
}
