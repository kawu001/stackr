% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_counter.R
\name{read_counter}
\alias{read_counter}
\title{Counts the number of reads in samples}
\usage{
read_counter(
  path.samples,
  recursive = FALSE,
  strata = NULL,
  plot.reads = TRUE,
  write = TRUE,
  parallel.core = parallel::detectCores() - 1
)
}
\arguments{
\item{path.samples}{(character, path) Path of folder containing the
samples to count reads}

\item{recursive}{(logical) Should the listing recurse into the directory?
e.g. when \code{path.samples} contains nested folders with FQ files.
Default: \code{recursive = FALSE}.}

\item{strata}{(optional)
The strata file is a tab delimited file with 2 columns headers:
\code{INDIVIDUALS} and \code{STRATA}.
The \code{STRATA} column can be any hierarchical grouping.
To create a strata file see \href{https://thierrygosselin.github.io/radiator/reference/individuals2strata.html}{individuals2strata}.
If you have already run
\href{http://catchenlab.life.illinois.edu/stacks/}{stacks} on your data,
the strata file is similar to a stacks \emph{population map file}, make sure you
have the required column names (\code{INDIVIDUALS} and \code{STRATA}).
Note: Make sure that the fastq file names (without extension) match the INDIVIDUALS
column in the strata file. With default, figures are generated without strata
grouping.
Default: \code{strata = NULL}.}

\item{plot.reads}{With default \code{plot.reads = TRUE}, the distribution and
boxplot figures are generated and written in the directory.}

\item{write}{With default \code{write = TRUE}, the data frame with read counts
and figures are is written in the working directory.}

\item{parallel.core}{(optional) The number of core for parallel computing.
By default: \code{parallel.core = parallel::detectCores() - 1}.}
}
\value{
a list with a data frame with the sample id and the number of reads.
If option to generate figures was selected, the list also returns 2 figures
(see example below)
}
\description{
This function counts the number of reads in samples present
in the specified folder.
Useful if you don't have the info (e.g. generated by stacks process_radtags),
and you want to check the distribution in the number of reads between samples.
}
\examples{
\dontrun{
library(stackr)
# To run this function, bioconductor \code{ShortRead} package is necessary:
source("http://bioconductor.org/biocLite.R")
biocLite("ShortRead")

# Using OpenMP threads
nthreads <- .Call(ShortRead:::.set_omp_threads, 1L)
on.exit(.Call(ShortRead:::.set_omp_threads, nthreads))

# with defaults
read.info <- stackr::read_counter(path.samples = "corals")

# to extract info from the list
reads = read.info$reads
reads.distribution <- read.info$reads.distribution
reads.boxplot <- read.info$reads.boxplot

# If the default figures saved were not good, save with new width and height
# the histogram
ggplot2::ggsave(
filename = "reads.distribution.pdf",
plot = reads.distribution,
width = 15, height = 15,
dpi = 600, units = "cm", useDingbats = FALSE, limitsize = FALSE)

# the boxplot
ggplot2::ggsave(
filename = "reads.boxplot.pdf",
plot = reads.boxplot,
width = 15, height = 15,
dpi = 600, units = "cm", useDingbats = FALSE, limitsize = FALSE)
}
}
