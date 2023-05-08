# Define functions to export a SummarizedExperiment to a trio of SQLite tables.
library(dplyr)

export_se <- function (
    experiment,
    db_name = "experiment",
    key = FALSE,
    drop_empty = FALSE
    ) {

  exp_db <- DBI::dbConnect(
    RSQLite::SQLite(),
    paste0("data/", db_name, ".sqlite", collapse = "")
    )

  if (key) {
    cd <- SummarizedExperiment::colData(experiment) %>%
      data.frame()
    DBI::dbExecute(exp_db, "drop table if exists colData;")
    DBI::dbExecute(exp_db,
                   "create table colData(sampleID, binary_attribute, primary key(sampleID));"
    )
    DBI::dbWriteTable(exp_db, "colData", cd, append = TRUE)
  }
  else {
    SummarizedExperiment::colData(experiment) %>%
      data.frame() %>%
      DBI::dbWriteTable(exp_db, "colData", ., overwrite = TRUE)
  }

  SummarizedExperiment::rowData(experiment) %>%
    data.frame() %>%
    DBI::dbWriteTable(exp_db, "rowData", ., overwrite = TRUE)

  if (drop_empty) {
    SummarizedExperiment::assay(experiment) %>%
      unpivot_assay() %>%
      filter(value > 0) %>%
      DBI::dbWriteTable(exp_db, "assay", ., overwrite = TRUE)    
  }
  else {
    SummarizedExperiment::assay(experiment) %>%
      unpivot_assay() %>%
      DBI::dbWriteTable(exp_db, "assay", ., overwrite = TRUE)
  }
  return(exp_db)
}

unpivot_assay <- function(assay) {
  assay <- as.data.frame(assay)
  assay["featureID"] <- rownames(assay)

  tidyr::pivot_longer(assay,
                      -featureID,
                      names_to = "sampleID",
                      values_to = "value")
}
