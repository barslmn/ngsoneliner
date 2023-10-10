#!/usr/bin/env -S Rscript --vanilla
## Plotting the resource usage and file sizes
## This script creates the [[fig:resource_usage][resource usage]] [[fig:file_sizes][file sizes]] plots using the metrics created at [[Monitoring the resource usage][above]] section.
## These images can later be included in the multiqc report.


## [[file:ngsoneliners.org::*Plotting the resource usage and file sizes][Plotting the resource usage and file sizes:1]]
library(ggplot2)

args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  run_dir <- "."
} else if (length(args)==1) {
  run_dir <- args[1]
}

num_x_ticks <- 66

plot_resource_usage <- function(log_path) {
  data <- read.table(log_path)
  mem <- data[c("V1", "V2", "V4")]
  mem$V5 <- "CPU"
  cpu <- data[c("V1", "V2", "V3")]
  cpu$V5 <- "MEM"

  colnames(mem) <- c("cmd", "time", "percent", "type")
  colnames(cpu) <- c("cmd", "time", "percent", "type")

  data <- rbind(cpu, mem)

  major_tasks <- c(
    "bwa_mem",
    "samtools_sort",
    "bcftools_mpileup",
    "samtools_markdup",
    "vep"
  )
  data <- data[grepl(paste(major_tasks, collapse = "|"), data$cmd), ]

  data$time <- as.POSIXct(data$time, format = "%Y/%m/%d/%H:%M:%S")

  date_breaks <- paste(
    signif(
      as.numeric(
        difftime(max(data$time), min(data$time), units = "secs") / num_x_ticks
      ),
      2
    ),
    "sec"
  )

  ggplot(
    data,
    aes(x = time, y = percent, color = cmd, group = cmd, linetype = cmd)
  ) +
    facet_wrap(~type, nrow = 2) +
    geom_line() +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
    ggtitle(log_path) +
    scale_linetype_manual(values = rep(c(
      "solid", "longdash", "twodash",
      "dashed", "dotdash", "dotted", "solid"
    ), 3)) +
    scale_x_datetime(date_breaks = date_breaks)
}


plot_file_sizes <- function(log_path) {
  num_x_ticks <- 67
  data <- read.table(log_path)
  colnames(data) <- c("time", "size", "file")
  data$time <- as.POSIXct(data$time, format = "%Y/%m/%d/%H:%M:%S")

  major_files <- c("cram$", "bcf$", "tsv$")

  data <- data[grepl(paste(major_files, collapse = "|"), data$file), ]

  date_breaks <- paste(
    signif(
      as.numeric(
        difftime(max(data$time), min(data$time), units = "secs") / num_x_ticks
      ),
      2
    ),
    "sec"
  )

  ggplot(
    data,
    aes(x = time, y = size, color = file, group = file, linetype = file)
  ) +
    geom_line() +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
    ggtitle(log_path) +
    scale_linetype_manual(
      values = rep(c(
        "solid", "longdash", "twodash",
        "dashed", "dotdash", "dotted", "solid"
      ), 3)
    ) +
    scale_x_datetime(date_breaks = date_breaks)
}


my_files <- list.files(path = run_dir, pattern = "^resources.*\\.log$", full.names = T)
for (i in my_files) {
  plot_resource_usage(i)
  ggsave(paste(i, "_mqc.png", sep = ""), width = 14, height = 7)
}

my_files <- list.files(path = run_dir, pattern = "^file_sizes.*\\.log$", full.names = T)
for (i in my_files) {
  plot_file_sizes(i)
  ggsave(paste(i, "_mqc.png", sep = ""), width = 14, height = 7)
}
## Plotting the resource usage and file sizes:1 ends here
