#read_counter
#' @name read_counter
#' @title Counts the number of reads in samples
#' @description This function counts the number of reads in samples present
#' in the specified folder.
#' Useful if you don't have the info (e.g. generated by stacks process_radtags),
#' and you want to check the distribution in the number of reads between samples.

#' @param path.samples (character, path) Path of folder containing the
#' samples to count reads

#' @param recursive (logical) Should the listing recurse into the directory?
#' e.g. when \code{path.samples} contains nested folders with FQ files.
#' Default: \code{recursive = FALSE}.

#' @param strata (optional)
#' The strata file is a tab delimited file with 2 columns headers:
#' \code{INDIVIDUALS} and \code{STRATA}.
#' The \code{STRATA} column can be any hierarchical grouping.
#' To create a strata file see \href{https://thierrygosselin.github.io/radiator/reference/individuals2strata.html}{individuals2strata}.
#' If you have already run
#' \href{http://catchenlab.life.illinois.edu/stacks/}{stacks} on your data,
#' the strata file is similar to a stacks \emph{population map file}, make sure you
#' have the required column names (\code{INDIVIDUALS} and \code{STRATA}).
#' Note: Make sure that the fastq file names (without extension) match the INDIVIDUALS
#' column in the strata file. With default, figures are generated without strata
#' grouping.
#' Default: \code{strata = NULL}.

#' @param plot.reads With default \code{plot.reads = TRUE}, the distribution and
#' boxplot figures are generated and written in the directory.

#' @param write With default \code{write = TRUE}, the data frame with read counts
#' and figures are is written in the working directory.

#' @param parallel.core (optional) The number of core for parallel computing.
#' By default: \code{parallel.core = parallel::detectCores() - 1}.


#' @rdname read_counter
#' @export
#' @return a list with a data frame with the sample id and the number of reads.
#' If option to generate figures was selected, the list also returns 2 figures
#' (see example below)

#' @examples
#' \dontrun{
#' library(stackr)
#' # To run this function, bioconductor \code{ShortRead} package is necessary:
#' source("http://bioconductor.org/biocLite.R")
#' biocLite("ShortRead")
#'
#' # Using OpenMP threads
#' nthreads <- .Call(ShortRead:::.set_omp_threads, 1L)
#' on.exit(.Call(ShortRead:::.set_omp_threads, nthreads))
#'
#' # with defaults
#' read.info <- stackr::read_counter(path.samples = "corals")
#'
#' # to extract info from the list
#' reads = read.info$reads
#' reads.distribution <- read.info$reads.distribution
#' reads.boxplot <- read.info$reads.boxplot
#'
#' # If the default figures saved were not good, save with new width and height
#' # the histogram
#' ggplot2::ggsave(
#' filename = "reads.distribution.pdf",
#' plot = reads.distribution,
#' width = 15, height = 15,
#' dpi = 600, units = "cm", useDingbats = FALSE, limitsize = FALSE)
#'
#' # the boxplot
#' ggplot2::ggsave(
#' filename = "reads.boxplot.pdf",
#' plot = reads.boxplot,
#' width = 15, height = 15,
#' dpi = 600, units = "cm", useDingbats = FALSE, limitsize = FALSE)
#' }


# @seealso
# \href{http://catchenlab.life.illinois.edu/stacks/comp/process_radtags.php}{process_radtags}.

# @references todo

read_counter <- function(
  path.samples,
  recursive = FALSE,
  strata = NULL,
  plot.reads = TRUE,
  write = TRUE,
  parallel.core = parallel::detectCores() - 1
) {
  opt.change <- getOption("width")
  options(width = 70)
  cat("#######################################################################\n")
  cat("######################## stackr::read_counter #########################\n")
  cat("#######################################################################\n")
  timing <- proc.time()
  file.date <- format(Sys.time(), "%Y%m%d@%H%M")

  # Missing argument -----------------------------------------------------------
  # folder is given
  if (missing(path.samples)) stop("path.samples argument is required")

  # Check for required package -------------------------------------------------
  if (!requireNamespace("ShortRead", quietly = TRUE)) {
    stop("ShortRead needed for this function to work.
         Please follow the example for install instructions", call. = FALSE)
  }


  # Check for results folder
  results.folder <- getwd()
  if (file.exists("08_stacks_results")) results.folder <- "08_stacks_results"

  # get fq files ---------------------------------------------------------------
  fastq.files <- list_sample_file(f = path.samples, full.path = TRUE, recursive = recursive)
  message("Number of samples to count: ", length(fastq.files))
  message("\nCounting reads...")
  names(fastq.files) <- fastq.files

  # # sequential
  # reads <- purrr::map_dfr(.x = fastq.files, .f = read_count_one) %>%
  #   dplyr::arrange(NUMBER_READS)

  # parallel
  reads <- .stackr_parallel(
    X = fastq.files,
    FUN = read_count_one,
    mc.cores = parallel.core
  ) %>%
    dplyr::bind_rows(.) %>%
    dplyr::arrange(NUMBER_READS)

  # merge strata if present ----------------------------------------------------
  # read in the strata

  if (is.vector(strata)) {
    if (!file.exists(strata)) rlang::abort("\nstrata file doesn't exist...\n")
    strata <- readr::read_tsv(
      file = strata,
      col_types = readr::cols(.default = readr::col_character()))
  }

  if (rlang::has_name(strata, "POP_ID") && !rlang::has_name(strata, "STRATA")) {
    colnames(strata) <- stringi::stri_replace_all_fixed(
      colnames(strata), "POP_ID", "STRATA",
      vectorize_all = FALSE)
  }


  # strata <- radiator::read_strata(strata) %$% strata

  if (!is.null(strata)) {
    reads %<>% dplyr::left_join(strata, by = "INDIVIDUALS")
  } else {
    reads %<>% dplyr::mutate(STRATA = "overall")
  }


  # check if problematic samples .....
  if (anyNA(reads$NUMBER_READS)) {
    prob <- reads$INDIVIDUALS[is.na(reads$NUMBER_READS)]
    message("\n\nProblematic samples: \n", paste0(prob, sep = "\n"))
    prob.filename <- file.path(results.folder, paste0("problematic_read_counter_samples_", file.date, ".tsv"))
    tibble::tibble(PROBLEMATIC_SAMPLES = prob) %>%
      readr::write_tsv(x = ., file = prob.filename)
    message("File written: ", prob.filename)

    reads %<>% dplyr::filter(!INDIVIDUALS %in% prob)
  }

  reads.stats <- stats_stackr(data = reads, x = "NUMBER_READS", digits = 0L) %>%
    tibble::add_column(.data = ., STRATA = "OVERALL", .before = 1L)

  message("\nReads stats:")
  message("Total reads across samples = ", reads.stats[3])
  message("Median number of reads = ", reads.stats[7])
  message("IQR = ", reads.stats[10][[1]])
  message("Min - Max = ", reads.stats[11], " - ", reads.stats[12])
  message("Number of outliers (min and max) = ", reads.stats[15] + reads.stats[16])

  if (!is.null(strata)) {
    reads.stats <- stats_stackr(data = reads, x = "NUMBER_READS", group.by = "STRATA", digits = 0L) %>%
      dplyr::bind_rows(reads.stats)
  }

  readr::write_tsv(x = reads.stats, file = file.path(results.folder, paste0("reads_stats_", file.date, ".tsv")))


  if (plot.reads) {
    n.pop <- dplyr::n_distinct(reads$STRATA)

    reads.distribution <- suppressMessages(ggplot2::ggplot(
      data = reads, ggplot2::aes(x = NUMBER_READS)) +
        ggplot2::geom_histogram() +
        ggplot2::labs(x = "Number of reads") +
        ggplot2::labs(y = "Number of samples") +
        ggplot2::theme(
          legend.position = "none",
          axis.title.x = ggplot2::element_text(size = 10, family = "Helvetica", face = "bold"),
          axis.title.y = ggplot2::element_text(size = 10, family = "Helvetica", face = "bold"),
          axis.text.x = ggplot2::element_text(size = 10, family = "Helvetica"),
          strip.text.x = ggplot2::element_text(size = 10, family = "Helvetica", face = "bold")
        ) +
        ggplot2::theme_bw()
    )

    # the boxplot
    if (n.pop > 1) {
      width.plot <- n.pop * 10
    } else {
      width.plot <- 15
    }

    if (!is.null(strata)) {
      reads.distribution <- suppressMessages(
        reads.distribution +
          ggplot2::facet_grid(~STRATA, scales = "free", space = "free_x"))
    }


    suppressMessages(
      ggplot2::ggsave(
        filename = file.path(results.folder, paste0("reads_distribution_", file.date, ".pdf")),
        plot = reads.distribution,
        width = width.plot, height = 15,
        dpi = 300,
        units = "cm",
        useDingbats = FALSE,
        limitsize = FALSE
      )
    )

    # boxplot
    reads.boxplot <- suppressMessages(
      ggplot2::ggplot(
        data = reads,
        ggplot2::aes(x = STRATA, y = NUMBER_READS, colour = STRATA)) +
        ggplot2::geom_jitter(alpha = 0.5) +
        ggplot2::geom_violin(trim = TRUE, fill = NA) +
        ggplot2::geom_boxplot(width = 0.1, fill = NA, outlier.colour = NA, outlier.fill = NA) +
        ggplot2::labs(y = "Number of reads") +
        ggplot2::theme(
          legend.position = "none",
          panel.grid.minor.x = ggplot2::element_blank(),
          panel.grid.major.y = ggplot2::element_blank(),
          axis.title.x = ggplot2::element_blank(),
          axis.title.y = ggplot2::element_text(size = 10, family = "Helvetica", face = "bold"),
          axis.text.x = ggplot2::element_text(size = 10, family = "Helvetica"),
          strip.text.x = ggplot2::element_text(size = 10, family = "Helvetica", face = "bold")
        ) +
        ggplot2::theme_bw()
    )

    # the boxplot
    if (n.pop > 1) {
      width.plot <- n.pop * 10
    } else {
      width.plot <- 15
    }

    ggplot2::ggsave(
      plot = reads.boxplot,
      filename = file.path(results.folder, paste0("reads_boxplot_", file.date, ".pdf")),
      width = width.plot, height = 15,
      dpi = 300,
      units = "cm",
      useDingbats = FALSE,
      limitsize = FALSE
    )

  } else {
    reads.distribution <- "option not selected"
    reads.boxplot <- "option not selected"
  }

  if (write) {
    filename <- file.path(results.folder, paste0("read_counts_", file.date, ".tsv"))
    readr::write_tsv(x = reads, file = filename)
    message("\nRead count file written: ", filename)
  }

  read.info <- list(
    reads.data = reads,
    reads.stast = reads.stats,
    reads.distribution = reads.distribution,
    reads.boxplot = reads.boxplot
  )
  timing <- proc.time() - timing
  message("\nComputation time: ", round(timing[[3]]), " sec")
  cat("############################## completed ##############################\n")
  options(width = opt.change)
  return(read.info)
}#read_counter


# Internal function ------------------------------------------------------------
#' @title read_count_one
#' @description count 1 fq file
#' @rdname read_count_one
#' @export
#' @keywords internal
read_count_one <- function(fastq.files) {
  clean.name <- clean_fq_filename(basename(fastq.files))
  message("\nCounting the number of reads in sample: ", clean.name)
  safe_counts <- purrr::safely(.f = ShortRead::readFastq)
  n.reads <- safe_counts(fastq.files)
  if (is.null(n.reads$result)) {
    n.reads <- NA
    message("\n\nProblematic sample: ", basename(fastq.files), "\n\n")
    return(tibble::as_tibble(list(INDIVIDUALS = clean.name, NUMBER_READS = NA)))
  } else {
    n.reads <- length(n.reads$result)
    message("    Number of reads: ", n.reads)
    return(tibble::as_tibble(list(INDIVIDUALS = clean.name, NUMBER_READS = n.reads)))
  }
}#End read_count_one
