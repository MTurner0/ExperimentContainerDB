if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

if (!require("MultiAssayExperiment", quietly = TRUE))
  BiocManager::install("MultiAssayExperiment")

if (!require("RSQLite", quietly = TRUE))
  install.packages("RSQLite")

if (!require("tidyverse", quietly = TRUE))
  install.packages("tidyverse")
