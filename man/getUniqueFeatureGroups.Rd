% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/collapseHypothesisWideFeatures.R
\name{getUniqueFeatureGroups}
\alias{getUniqueFeatureGroups}
\title{Determine unique feature groups}
\usage{
getUniqueFeatureGroups(feature_table, rt_height = 2,
  distance_cutoff = 1, plot = FALSE)
}
\arguments{
\item{feature_table}{data.table containing filtered complex feature results.}

\item{rt_height}{Numeric, rt difference for clustering along the fractionation dimension, default = 2.}

\item{distance_cutoff}{Numeric, distance of detected subunit overlap 
(0=identical, 1=subcomplexes, 2=no shared subunits), default = 1.}

\item{plot}{Logical, whether to plot the fraction dimenson apex distance histogram, default = \code{FALSE}.}
}
\value{
data.table containing complex feature results with an extra column with a unique_feature_identifier.
}
\description{
Determine unique feature groups based on the apex distances in the fraction dimension 
as well as the overlap between co-eluting subunits.
}
\examples{
## run unique feature annotation
complexFeaturesUnique <- getUniqueFeatureGroups(exampleComplexFeatures,
                                                rt_height=2,
                                                distance_cutoff=1,
                                                plot=TRUE)
                                                
}
