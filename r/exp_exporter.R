# Define functions to export a SummarizedExperiment to a trio of SQLite tables.

library(dplyr)

export_se <- function (experiment, db_name = "experiment") {

  exp_db <- DBI::dbConnect(
    RSQLite::SQLite(),
    paste0("data/", db_name, ".sqlite", collapse = "")
    )

  SummarizedExperiment::colData(experiment) %>%
    data.frame() %>%
    DBI::dbWriteTable(exp_db, "colData", .)

  SummarizedExperiment::rowData(experiment) %>%
    data.frame() %>%
    DBI::dbWriteTable(exp_db, "rowData", .)

  SummarizedExperiment::assay(experiment) %>%
    unpivot_assay() %>%
    dbWriteTable(exp_db, "assay", .)

  return(exp_db)
}

unpivot_assay <- function(assay) {
  assay <- as.data.frame(assay)
  assay["featureID"] <- rownames(assay)

  tidyr::pivot_longer(assay,
                      featureID,
                      names_to = "sampleID",
                      values_to = "value")
}
