library(DBI)
library(dplyr)
source("r/dummy_exp_builder.R")

baby <- dummy_se_builder(rpois, list(lambda = 1), seed = 1416)

baby_db <- dbConnect(RSQLite::SQLite(), "data/baby.sqlite")

SummarizedExperiment::colData(baby) %>%
  data.frame() %>%
  dbWriteTable(baby_db, "colData", .)

SummarizedExperiment::rowData(baby) %>%
  data.frame() %>%
  dbWriteTable(baby_db, "rowData", .)

unpivot_assay <- function(assay) {
  assay <- as.data.frame(assay)
  assay$featureID <- rownames(assay)

  tidyr::pivot_longer(assay,
                      featureID,
                      names_to = "sampleID",
                      values_to = "value")
}

SummarizedExperiment::assay(baby) %>%
  unpivot_assay() %>%
  dbWriteTable(baby_db, "assay", .)

dbListTables(baby_db)
